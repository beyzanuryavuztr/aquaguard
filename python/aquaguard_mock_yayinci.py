"""
AquaGuard - Sahte (Mock) Canli Sensor Verisi Yayincisi
=========================================================

Amac:
    Deneyap Kart donanimi henuz hazir olmasa bile Flutter mobil uygulamasini
    ve MQTT veri akisini uctan uca test edebilmek icin, gercekci bir tikanma
    senaryosunun zaman icindeki gelisimini simule edip MQTT uzerinden
    yayinlar. Yayinlanan JSON semasi, firmware/mqtt_handler.h dosyasinda
    tanimlanan semayla BIREBIR AYNIDIR -- boylece gercek donanim geldiginde
    Flutter tarafinda HICBIR KOD DEGISIKLIGI gerekmez, sadece MQTT broker
    adresi degistirilir.

    Karar (durum/tur/guven) hesaplamasi icin KENDI BASINA bir mantik
    yazmiyoruz -- python/aquaguard_karar_motoru.py dosyasindaki
    kural_tabanli_teshis() fonksiyonunu DOGRUDAN cagiriyoruz. Boylece tek
    bir "gercek" karar mantigi kaynagi olur (bu script + firmware'in
    decision_engine.h dosyasi ayni matematigi iki farkli dilde uygular).

    OPERATOR KOMUTLARI: bu script ayrica "aquaguard/zone{N}/komut" konusuna
    ABONE OLUR -- Flutter uygulamasindaki manuel mudahale (bkz.
    providers/uygulama_durumu.dart manuelTedaviBaslat/Durdur/NormaleDondur)
    gercek bir MQTT brokerina karsi da uctan uca test edilebilsin diye.
    Komut geldiginde, o an yayinlanmakta olan senaryo ureteci degistirilir
    (firmware/mqtt_handler.h + treatment.h ile AYNI davranis: erken durdurma
    once zorunlu durulamadan gecer, mutex atlanmaz).

    "sulama_durdur"/"sulama_baslat" komutlari (bkz. UygulamaDurumu.
    sulamayiDurdur/sulamayiBaslat, firmware/ana_vana.h) teshis akisindan
    BAGIMSIZDIR -- ana vana kapatildiginda bu script o zon icin YAYIN
    YAPMAYI DURDURUR (gercek cihazda sensor okumasi anlamsiz hale geldigi
    icin firmware de ayni sekilde teshis dongusunu atlar).

    SEMA v3 (2026-09-24, "ciftci evinden sulama baslatsin" ozelligi):
    "sulama_baslat" komutu artik opsiyonel "sure_dakika" alani tasiyabilir
    (SULAMA_MAKS_SURE_DK ile kirpilir). Verilirse, ana vana o sure sonunda
    KENDILIGINDEN kapanir -- zamanlayici SUNUCUDA/CIHAZDA calisir, telefon
    uygulamasi kapansa bile su bosa akmaya devam etmez. Kalan sure
    "sulama_kalan_saniye" alaniyla yayinlanir (uygulamada geri sayim icin).

    KAPSAM DISI (2026-09-25, bilincli): firmware/mqtt_handler.h'ye eklenen
    "zon-bazli dozlama izolasyonu" (bir zon tedavi baslatinca DIGER
    zonlarin vanasini gecici kapatma -- ekip karari: dozlama pompalari
    ortak ana hatta enjekte ediyor) bu mock'ta UYGULANMADI. Bu, cok-surecli
    (multi-process, her zon ayri bir "python aquaguard_mock_yayinci.py
    --zone N" cagrisi) bir MQTT koordinasyonu gerektirir -- mock'un asil
    amaci (Flutter uygulamasini tek bir zonun veri akisina karsi test
    etmek) icin gereksiz karmasiklik. Bu davranis SADECE gercek donanimda
    (veya birden fazla mock ornegini MQTT Explorer gibi bir aracla elle
    izleyerek) gozlemlenebilir -- bkz. firmware/DONANIM_KONTROL_LISTESI.md
    "Python mock ile PARITE NOTU".

Senaryo mantigi (bir "hikaye" dongusu):
    1) NORMAL   - sensorler normal deger etrafinda dalgalanir
    2) KOTULESME - rastgele secilen bir tikanma turune dogru kademeli kayma
    3) TEDAVI    - esik asilir, "tedavi_aktif" alani dolar, degerler
                   iyilesmeye baslar (dozlama/yikama etkisini yansitir)
    4) DURULAMA  - tedavi biter, zorunlu durulama gosterilir
    5) IYILESME  - degerler tamamen normale doner
    ... dongu, YENI rastgele bir tikanma turuyle tekrar baslar.

    NOT: Buradaki gurultu seviyesi, egitim veri setindekinden (adim 1) daha
    dusuktur -- amac ML zorlugu yaratmak degil, Flutter arayuzunun her
    ekraninin (normal/uyari/tedavi/durulama) duzgun gorunmesini saglayan
    TEMIZ bir demo akisi uretmektir.

Kullanim:
    python aquaguard_mock_yayinci.py
    python aquaguard_mock_yayinci.py --broker test.mosquitto.org --zone 1 --aralik 3

Tarih:  2026-09-01
Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
"""

from __future__ import annotations

import argparse
import itertools
import json
import time
from datetime import datetime

import numpy as np
import paho.mqtt.client as mqtt

from aquaguard_karar_motoru import kural_tabanli_teshis
from aquaguard_veri_uretici import SENSOR_IMZALARI, SENSOR_SIRASI

# ---------------------------------------------------------------------------
# 1) SABITLER
# ---------------------------------------------------------------------------

TIKANMA_TURLERI = ["kimyasal", "biyolojik", "fiziksel"]

# Tikanma turunden tedavi adina esleme (brief SS3 tedavi tablosu, treatment.h ile ayni)
TEDAVI_ESLEME = {
    "kimyasal": "asit_dozlama",
    "biyolojik": "klor_enjeksiyon",
    "fiziksel": "yuksek_basincli_yikama",
}

# TEDAVI_ESLEME'nin TERSI -- operatorun MQTT komutuyla gonderdigi tedavi
# adindan (ekipmanla eslesir) hangi tikanma turu senaryosunun uretilecegini
# bulmak icin (bkz. _komut_isle()).
TUR_ESLEME_TERS = {tedavi: tur for tur, tedavi in TEDAVI_ESLEME.items()}

# Senaryo fazlarinin adim sayilari (her adim bir MQTT yayinina karsilik gelir)
FAZ_ADIM_SAYILARI = {
    "normal": 4,
    "kotulesme": 6,
    "tedavi": 3,
    "durulama": 2,
    "iyilesme": 4,
}

DEMO_GURULTU_CARPANI = 0.5  # Egitim verisindeki gurultuden daha dusuk (temiz demo icin)

# firmware/config.h SULAMA_MAKS_SURE_DK ile BIREBIR AYNI olmali (tek kaynak).
SULAMA_MAKS_SURE_DK = 180

# ---------------------------------------------------------------------------
# 2) SENARYO / SIMULASYON MANTIGI
# ---------------------------------------------------------------------------

def _sensor_degeri_hesapla(sensor: str, kaynak_sinif: str, hedef_sinif: str,
                            ilerleme: float, rng: np.random.Generator) -> float:
    """
    Iki sinif arasinda dogrusal interpolasyon yapip kucuk bir gurultu ekler.
    ilerleme=0.0 -> tamamen kaynak_sinif, ilerleme=1.0 -> tamamen hedef_sinif.
    """
    kaynak_ort, kaynak_std = SENSOR_IMZALARI[kaynak_sinif][sensor]
    hedef_ort, hedef_std = SENSOR_IMZALARI[hedef_sinif][sensor]

    ort = kaynak_ort + (hedef_ort - kaynak_ort) * ilerleme
    std = kaynak_std + (hedef_std - kaynak_std) * ilerleme

    return float(ort + rng.normal(0, std * DEMO_GURULTU_CARPANI))


def _tam_ornek_uret(kaynak_sinif: str, hedef_sinif: str, ilerleme: float,
                     rng: np.random.Generator) -> dict:
    return {
        sensor: _sensor_degeri_hesapla(sensor, kaynak_sinif, hedef_sinif, ilerleme, rng)
        for sensor in SENSOR_SIRASI
    }


def durulama_ve_iyilesme_adimlarini_uret(hedef_tur: str, rng: np.random.Generator):
    """
    DURULAMA + IYILESME kuyrugu -- otonom akisin (tedavi bittikten sonra) ve
    operatorun "tedavi_durdur" komutuyla ERKEN durdurmasinin (bkz. _komut_isle)
    ORTAK kullandigi tek kaynak. Guvenlik geregi erken durdurma da bu adimlardan
    gecer -- dogrudan "normal"e atlanmaz (firmware/treatment.h ile ayni kural).
    """
    adim_sayisi = FAZ_ADIM_SAYILARI["durulama"]
    for i in range(adim_sayisi):
        ilerleme = 0.5 - 0.25 * i
        ornek = _tam_ornek_uret("normal", hedef_tur, max(ilerleme, 0.0), rng)
        yield ornek, "durulama", "yok", True

    adim_sayisi = FAZ_ADIM_SAYILARI["iyilesme"]
    for i in range(1, adim_sayisi + 1):
        ilerleme = max(0.25 - 0.25 * (i / adim_sayisi), 0.0)
        ornek = _tam_ornek_uret("normal", hedef_tur, ilerleme, rng)
        yield ornek, "iyilesme", "yok", False


def tedavi_ve_iyilesme_adimlarini_uret(hedef_tur: str, rng: np.random.Generator):
    """
    TEDAVI + DURULAMA + IYILESME kuyrugu -- otonom akisin (kotulesme sonrasi)
    ve operatorun "tedavi_baslat" komutuyla MANUEL baslatmasinin (bkz.
    _komut_isle) ORTAK kullandigi tek kaynak.
    """
    tedavi_adi = TEDAVI_ESLEME[hedef_tur]
    adim_sayisi = FAZ_ADIM_SAYILARI["tedavi"]
    for i in range(adim_sayisi):
        ilerleme = 1.0 - 0.15 * i  # tedavi surerken hafif iyilesme egilimi
        ornek = _tam_ornek_uret("normal", hedef_tur, max(ilerleme, 0.0), rng)
        yield ornek, "tedavi", tedavi_adi, False

    yield from durulama_ve_iyilesme_adimlarini_uret(hedef_tur, rng)


def senaryo_adimlarini_uret(rng: np.random.Generator):
    """
    Sonsuz bir uretec (generator): her cagrida bir sonraki simulasyon adimini
    (sensor_ornegi, faz_adi, tedavi_aktif, durulama_aktif) olarak doner.
    """
    while True:
        hedef_tur = rng.choice(TIKANMA_TURLERI)

        # --- 1) NORMAL ---
        for _ in range(FAZ_ADIM_SAYILARI["normal"]):
            ornek = _tam_ornek_uret("normal", "normal", 0.0, rng)
            yield ornek, "normal", "yok", False

        # --- 2) KOTULESME (normal -> hedef_tur, kademeli) ---
        adim_sayisi = FAZ_ADIM_SAYILARI["kotulesme"]
        for i in range(1, adim_sayisi + 1):
            ilerleme = i / adim_sayisi
            ornek = _tam_ornek_uret("normal", hedef_tur, ilerleme, rng)
            yield ornek, "kotulesme", "yok", False

        # --- 3,4,5) TEDAVI -> DURULAMA -> IYILESME ---
        yield from tedavi_ve_iyilesme_adimlarini_uret(hedef_tur, rng)


def _komut_isle(mesaj_json: dict, calisma_durumu: dict, istemci=None,
                 komut_durumu_konusu: str | None = None) -> None:
    """
    Operatorden gelen bir MQTT komutunu isler, calisma_durumu["uretec"]'i
    (o an aktif olan senaryo ureteci) gerekirse DEGISTIRIR. bkz. dosya basi
    aciklamasi ve Flutter tarafinda providers/uygulama_durumu.dart.

    SEMA v2 (ACK/NACK): mesaj_json["komut_id"] verilmisse (Dart tarafi her
    komuta bir tane ekler -- bkz. MqttServisi.komutGonder), islem sonucunu
    `komut_durumu_konusu`'na yayinlar. `istemci`/`komut_durumu_konusu`
    verilmezse (ornegin dogrudan birim testlerinde) ACK gonderimi sessizce
    atlanir -- gercek firmware BU DAVRANISI HENUZ UYGULAMIYOR (bkz.
    firmware/mqtt_handler.h sema v2 notu), sadece bu mock/gelistirme
    yayincisi uygular.
    """
    komut = mesaj_json.get("komut")
    komut_id = mesaj_json.get("komut_id")
    rng = calisma_durumu["rng"]

    def _ack_gonder(basarili: bool) -> None:
        if istemci is None or komut_durumu_konusu is None or komut_id is None:
            return
        govde = json.dumps(
            {"komut_id": komut_id, "durum": "tamamlandi" if basarili else "reddedildi"},
            ensure_ascii=False,
        )
        istemci.publish(komut_durumu_konusu, govde, qos=1)

    if komut == "tedavi_baslat":
        # ACIMASIZ DENETIM DUZELTMESI (2026-09-14): bu isleyici daha once
        # firmware/mqtt_handler.h'nin uyguladigi IKI guvenlik kontrolunu de
        # (ana vana acik mi, mutex mesgul mu -- bkz. treatment.h) atliyordu,
        # dosyanin kendi basindaki "AYNI davranis, mutex atlanmaz" iddiasiyla
        # CELISEREK. Bu mock, Flutter'in manuel mudahale ozelligini gercek
        # MQTT modunda test etmek icin kullanildiginda, firmware'in REDDEDECEGI
        # bir komutu burada "basarili" gibi isleyip yanlis guven verirdi.
        if not calisma_durumu["sulama_acik"]:
            print("[Komut] Operatör: manuel tedavi REDDEDİLDİ (ana vana kapalı, akış yok).")
            _ack_gonder(False)
            return
        if calisma_durumu["tedavi_aktif"] != "yok" or calisma_durumu["durulama_aktif"]:
            print("[Komut] Operatör: manuel tedavi REDDEDİLDİ (mutex meşgul -- başka bir tedavi/durulama sürüyor).")
            _ack_gonder(False)
            return
        tedavi_turu = mesaj_json.get("tedavi_turu")
        hedef_tur = TUR_ESLEME_TERS.get(tedavi_turu)
        if hedef_tur is None:
            print(f"[Komut] Gecersiz/eksik tedavi_turu: {tedavi_turu!r}, yoksayildi.")
            _ack_gonder(False)
            return
        print(f"[Komut] Operatör: '{tedavi_turu}' tedavisi manuel başlatılıyor.")
        calisma_durumu["uretec"] = itertools.chain(
            tedavi_ve_iyilesme_adimlarini_uret(hedef_tur, rng),
            senaryo_adimlarini_uret(rng),
        )
        _ack_gonder(True)
    elif komut == "tedavi_durdur":
        guncel_tur = calisma_durumu.get("guncel_tur") or "fiziksel"
        print(f"[Komut] Operatör: aktif tedavi erken durduruluyor (tür={guncel_tur}).")
        calisma_durumu["uretec"] = itertools.chain(
            durulama_ve_iyilesme_adimlarini_uret(guncel_tur, rng),
            senaryo_adimlarini_uret(rng),
        )
        _ack_gonder(True)
    elif komut == "normale_dondur":
        print("[Komut] Operatör: durum yanlış alarm olarak işaretlendi, normale dönülüyor.")
        calisma_durumu["uretec"] = senaryo_adimlarini_uret(rng)
        _ack_gonder(True)
    elif komut == "sulama_durdur":
        print("[Komut] Operatör: ana vana MANUEL kapatıldı, sulama durdu.")
        calisma_durumu["sulama_acik"] = False
        calisma_durumu["sulama_kapanma_zamani"] = None
        _ack_gonder(True)
    elif komut == "sulama_baslat":
        # SEMA v3 (2026-09-24): opsiyonel "sure_dakika" -- verilmemisse
        # (0/None) suresiz acilir (eski davranis). Verilmisse
        # SULAMA_MAKS_SURE_DK ile kirpilip o sure sonunda bu mock da
        # firmware'deki gibi KENDILIGINDEN kapatir (bkz. ana ilmek).
        sure_dakika = mesaj_json.get("sure_dakika") or 0
        calisma_durumu["sulama_acik"] = True
        if sure_dakika > 0:
            sure_dakika = min(sure_dakika, SULAMA_MAKS_SURE_DK)
            calisma_durumu["sulama_kapanma_zamani"] = time.monotonic() + sure_dakika * 60
            print(f"[Komut] Operatör: ana vana yeniden açıldı, {sure_dakika} dakika süreli sulama başladı.")
        else:
            calisma_durumu["sulama_kapanma_zamani"] = None
            print("[Komut] Operatör: ana vana yeniden açıldı, sulama başladı (süresiz).")
        _ack_gonder(True)
    else:
        print(f"[Komut] Bilinmeyen komut: {komut!r}")
        _ack_gonder(False)


# ---------------------------------------------------------------------------
# 3) MQTT YAYIN MANTIGI
# ---------------------------------------------------------------------------

def _mesaj_olustur(ornek: dict, teshis: dict, zone: int, tedavi_aktif: str,
                    durulama_aktif: bool, hazne_asit_yuzde: float,
                    hazne_klor_yuzde: float,
                    ana_vana_acik: bool = True,
                    sulama_kalan_saniye: int = 0) -> str:
    """firmware/mqtt_handler.h basindaki JSON semasiyla BIREBIR AYNI alanlar.

    guven_kimyasal/guven_biyolojik/guven_fiziksel alanlari, karar motorunun
    UC turu de nasil degerlendirdigini (aciklanabilirlik) tasir -- sadece
    "kazanan" turu degil, ucunun de guven yuzdesini gosterir. Bu, mobil
    uygulamadaki "Neden bu karar?" panelinin veri kaynagidir.

    hazne_asit_yuzde/hazne_klor_yuzde (SEMA v2): GERCEK donanimda henuz bir
    hazne seviye sensoru YOK (bkz. firmware/config.h) -- bu mock yayinci
    SADECE gelistirme/demo amacli, ilgili tedavi aktifken yavasca azalan
    ILLUSTRATIF degerler uretir (bkz. calisma_durumu["hazne_*_yuzde"]).
    Gercek firmware bu alanlari YAYINLAMAZ; Dart tarafi alan eksikse
    `null` olarak okur ve UI hazne kartini gostermez.
    """
    tum_guvenler = teshis.get("tum_guvenler", {})

    mesaj = {
        "zaman": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "zone": zone,
        "ph": round(ornek["ph"], 2),
        "ec": round(ornek["ec"], 2),
        "orp": round(ornek["orp"], 0),
        "turbidite": round(ornek["turbidite"], 1),
        "debi": round(ornek["debi"], 2),
        "delta_basinc": round(ornek["delta_basinc"], 3),
        "durum": teshis["durum"],
        "tikanma_turu": teshis["tur"] if teshis["tur"] else "yok",
        "guven": round(teshis["guven"], 1),
        "guven_kimyasal": round(tum_guvenler.get("kimyasal", 0.0), 1),
        "guven_biyolojik": round(tum_guvenler.get("biyolojik", 0.0), 1),
        "guven_fiziksel": round(tum_guvenler.get("fiziksel", 0.0), 1),
        "tedavi_aktif": tedavi_aktif,
        "durulama_aktif": durulama_aktif,
        "hazne_asit_seviye_yuzde": round(hazne_asit_yuzde, 1),
        "hazne_klor_seviye_yuzde": round(hazne_klor_yuzde, 1),
        # SEMA v2 (2026-09-19): ana vananin GERCEK durumu -- gercek firmware
        # da yayinlar; uygulama vana durumunu bununla esitler.
        "ana_vana_acik": bool(ana_vana_acik),
        # SEMA v3 (2026-09-24): sureli sulama geri sayimi, sureli baslatilmadiysa 0.
        "sulama_kalan_saniye": int(sulama_kalan_saniye),
    }
    return json.dumps(mesaj, ensure_ascii=False)


def calistir(broker: str, port: int, zone: int, aralik_sn: float, adim_sayisi: int | None) -> None:
    veri_konusu = f"aquaguard/zone{zone}/veri"
    durum_konusu = f"aquaguard/zone{zone}/durum"
    komut_konusu = f"aquaguard/zone{zone}/komut"
    komut_durumu_konusu = f"aquaguard/zone{zone}/komut_durumu"

    istemci = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=f"aquaguard-mock-zone{zone}")
    istemci.will_set(durum_konusu, payload="offline", qos=1, retain=True)

    rng = np.random.default_rng()  # her calistirmada farkli senaryo (demo cesitliligi icin)
    # Operator komutlarinin (ayri bir ag thread'inde calisan on_message
    # geri cagirimi ile) o an aktif olan ureteci DEGISTIREBILMESI icin
    # paylasilan, mutable bir durum sozlugu -- bkz. _komut_isle().
    calisma_durumu = {
        "uretec": senaryo_adimlarini_uret(rng),
        "rng": rng,
        "guncel_tur": None,
        "sulama_acik": True,
        # None = sureli sulama zamanlayicisi YOK. Sayiysa, time.monotonic()
        # bu degere ulasinca ana ilmek vanayi OTOMATIK kapatir (bkz. asagida,
        # firmware/ana_vana.h anaVanaZamanlayiciyiGuncelle ile ayni desen).
        "sulama_kapanma_zamani": None,
        # _komut_isle()'in "tedavi_baslat" mutex kontrolu icin -- ana
        # dongude her adimda guncellenir (bkz. asagida).
        "tedavi_aktif": "yok",
        "durulama_aktif": False,
        # HAZNE SEVIYESI (SEMA v2, sadece gelistirme/demo amacli -- bkz.
        # _mesaj_olustur dosya ici notu): %100'den baslar, ilgili tedavi
        # aktifken yavasca azalir, %0'da kalir (gercek bir dolum akisi
        # simule edilmiyor, kasitli sinirli kapsam).
        "hazne_asit_yuzde": 100.0,
        "hazne_klor_yuzde": 100.0,
    }

    def _baglaninca(client, userdata, connect_flags, reason_code, properties):
        if reason_code == 0:
            print(f"[MQTT] Brokera baglanildi: {broker}:{port}")
            client.publish(durum_konusu, "online", qos=1, retain=True)
            client.subscribe(komut_konusu, qos=1)
        else:
            print(f"[MQTT] Baglanti hatasi: {reason_code}")

    def _mesaj_geldiginde(client, userdata, message):
        try:
            mesaj_json = json.loads(message.payload.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            print("[Komut] JSON ayristirilamadi, mesaj yoksayildi.")
            return
        # GECERLI JSON ama sozluk DEGILSE (ör. bir sayi, dizi veya null --
        # "5", "[1,2]", "null" hepsi gecerli JSON'dur) _komut_isle() icindeki
        # mesaj_json.get(...) cagrisi AttributeError firlatir ve MQTT agi
        # thread'ini durdurabilirdi -- acimasiz denetimde bulundu (2026-09-06).
        if not isinstance(mesaj_json, dict):
            print(f"[Komut] Beklenmeyen komut govdesi (sozluk degil): {mesaj_json!r}, yoksayildi.")
            return
        _komut_isle(
            mesaj_json, calisma_durumu,
            istemci=client, komut_durumu_konusu=komut_durumu_konusu,
        )

    istemci.on_connect = _baglaninca
    istemci.on_message = _mesaj_geldiginde

    print(f"[MQTT] Baglaniliyor: {broker}:{port} ...")
    # ACIMASIZ DENETIM DUZELTMESI (2026-09-14): connect() bloke edici bir
    # cagridir ve TRY/FINALLY blogunun DISINDA calisiyordu -- DNS hatasi
    # veya reddedilen baglanti gibi durumlarda ham bir Python traceback'iyle
    # cokup finally'deki temizligi (ve daha onemlisi kullaniciya anlasilir
    # bir hata mesaji vermeyi) atliyordu. firmware/mqtt_handler.h'nin
    # kendi baglanti hatasini loglayip devam etmesiyle ayni ilke: gelistirme
    # araci gurultusuz cokmemeli.
    try:
        istemci.connect(broker, port, keepalive=60)
    except OSError as hata:
        print(f"[MQTT] Baglanti kurulamadi ({broker}:{port}): {hata}")
        return
    istemci.loop_start()

    print("=" * 78)
    print(f"AquaGuard Mock Yayinci - Zone {zone} - Konu: {veri_konusu}")
    print(f"Operatör komut konusu: {komut_konusu}")
    print(f"Yayin araligi: {aralik_sn} sn  |  Durdurmak icin Ctrl+C")
    print("=" * 78)

    sayac = 0
    try:
        while True:
            # Sureli sulama -- suresi dolduysa firmware'deki
            # anaVanaZamanlayiciyiGuncelle() ile AYNI davranis: otomatik kapat.
            kapanma_zamani = calisma_durumu["sulama_kapanma_zamani"]
            if (
                kapanma_zamani is not None
                and calisma_durumu["sulama_acik"]
                and time.monotonic() >= kapanma_zamani
            ):
                calisma_durumu["sulama_acik"] = False
                calisma_durumu["sulama_kapanma_zamani"] = None
                print("[SULAMA] Süreli sulama tamamlandı, vana otomatik kapatıldı.")

            if not calisma_durumu["sulama_acik"]:
                # Ana vana kapali: senaryo uretecini ILERLETME (donduralm
                # kalsin) ve yeni veri yayinlama -- firmware/ana_vana.h ile
                # ayni davranis (bkz. dosya basi aciklamasi).
                time.sleep(aralik_sn)
                continue

            ornek, faz, tedavi_aktif, durulama_aktif = next(calisma_durumu["uretec"])
            calisma_durumu["tedavi_aktif"] = tedavi_aktif
            calisma_durumu["durulama_aktif"] = durulama_aktif
            teshis = kural_tabanli_teshis(ornek)
            if teshis["tur"]:
                calisma_durumu["guncel_tur"] = teshis["tur"]
            if tedavi_aktif == "asit_dozlama":
                calisma_durumu["hazne_asit_yuzde"] = max(
                    0.0, calisma_durumu["hazne_asit_yuzde"] - 0.4
                )
            if tedavi_aktif == "klor_enjeksiyon":
                calisma_durumu["hazne_klor_yuzde"] = max(
                    0.0, calisma_durumu["hazne_klor_yuzde"] - 0.4
                )
            kalan_saniye = 0
            if calisma_durumu["sulama_kapanma_zamani"] is not None:
                kalan_saniye = max(
                    0, int(calisma_durumu["sulama_kapanma_zamani"] - time.monotonic())
                )
            mesaj = _mesaj_olustur(
                ornek, teshis, zone, tedavi_aktif, durulama_aktif,
                calisma_durumu["hazne_asit_yuzde"],
                calisma_durumu["hazne_klor_yuzde"],
                ana_vana_acik=calisma_durumu["sulama_acik"],
                sulama_kalan_saniye=kalan_saniye,
            )

            istemci.publish(veri_konusu, mesaj, qos=1, retain=True)

            print(f"[{faz:<10}] durum={teshis['durum']:<15} tur={str(teshis['tur']):<10} "
                  f"guven=%{teshis['guven']:<5.1f} tedavi={tedavi_aktif:<22} "
                  f"pH={ornek['ph']:.2f} EC={ornek['ec']:.2f} ORP={ornek['orp']:.0f} "
                  f"Turb={ornek['turbidite']:.1f} Debi={ornek['debi']:.2f} dP={ornek['delta_basinc']:.3f}")

            sayac += 1
            if adim_sayisi is not None and sayac >= adim_sayisi:
                break

            time.sleep(aralik_sn)

    except KeyboardInterrupt:
        print("\n[MQTT] Kullanici tarafindan durduruldu.")

    finally:
        istemci.publish(durum_konusu, "offline", qos=1, retain=True)
        time.sleep(0.3)  # son mesajin gonderilmesi icin kisa bekleme
        istemci.loop_stop()
        istemci.disconnect()
        print("[MQTT] Baglanti kapatildi.")


# ---------------------------------------------------------------------------
# 4) KOMUT SATIRI ARAYUZU
# ---------------------------------------------------------------------------

def _argumanlari_ayristir() -> argparse.Namespace:
    ayristirici = argparse.ArgumentParser(description="AquaGuard sahte MQTT sensor veri yayincisi")
    ayristirici.add_argument("--broker", default="test.mosquitto.org", help="MQTT broker adresi")
    ayristirici.add_argument("--port", type=int, default=1883, help="MQTT broker portu")
    ayristirici.add_argument("--zone", type=int, default=1, help="Yayinlanacak zon numarasi")
    ayristirici.add_argument("--aralik", type=float, default=3.0, help="Yayinlar arasi sure (saniye)")
    ayristirici.add_argument("--adim-sayisi", type=int, default=None,
                              help="Belirtilirse bu kadar adimdan sonra durur (test icin); "
                                   "belirtilmezse sonsuz calisir")
    return ayristirici.parse_args()


if __name__ == "__main__":
    args = _argumanlari_ayristir()
    calistir(args.broker, args.port, args.zone, args.aralik, args.adim_sayisi)
