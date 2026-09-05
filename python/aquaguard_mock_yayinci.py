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


def _komut_isle(mesaj_json: dict, calisma_durumu: dict) -> None:
    """
    Operatorden gelen bir MQTT komutunu isler, calisma_durumu["uretec"]'i
    (o an aktif olan senaryo ureteci) gerekirse DEGISTIRIR. bkz. dosya basi
    aciklamasi ve Flutter tarafinda providers/uygulama_durumu.dart.
    """
    komut = mesaj_json.get("komut")
    rng = calisma_durumu["rng"]

    if komut == "tedavi_baslat":
        tedavi_turu = mesaj_json.get("tedavi_turu")
        hedef_tur = TUR_ESLEME_TERS.get(tedavi_turu)
        if hedef_tur is None:
            print(f"[Komut] Gecersiz/eksik tedavi_turu: {tedavi_turu!r}, yoksayildi.")
            return
        print(f"[Komut] Operatör: '{tedavi_turu}' tedavisi manuel başlatılıyor.")
        calisma_durumu["uretec"] = itertools.chain(
            tedavi_ve_iyilesme_adimlarini_uret(hedef_tur, rng),
            senaryo_adimlarini_uret(rng),
        )
    elif komut == "tedavi_durdur":
        guncel_tur = calisma_durumu.get("guncel_tur") or "fiziksel"
        print(f"[Komut] Operatör: aktif tedavi erken durduruluyor (tür={guncel_tur}).")
        calisma_durumu["uretec"] = itertools.chain(
            durulama_ve_iyilesme_adimlarini_uret(guncel_tur, rng),
            senaryo_adimlarini_uret(rng),
        )
    elif komut == "normale_dondur":
        print("[Komut] Operatör: durum yanlış alarm olarak işaretlendi, normale dönülüyor.")
        calisma_durumu["uretec"] = senaryo_adimlarini_uret(rng)
    elif komut == "sulama_durdur":
        print("[Komut] Operatör: ana vana MANUEL kapatıldı, sulama durdu.")
        calisma_durumu["sulama_acik"] = False
    elif komut == "sulama_baslat":
        print("[Komut] Operatör: ana vana yeniden açıldı, sulama başladı.")
        calisma_durumu["sulama_acik"] = True
    else:
        print(f"[Komut] Bilinmeyen komut: {komut!r}")


# ---------------------------------------------------------------------------
# 3) MQTT YAYIN MANTIGI
# ---------------------------------------------------------------------------

def _mesaj_olustur(ornek: dict, teshis: dict, zone: int, tedavi_aktif: str,
                    durulama_aktif: bool) -> str:
    """firmware/mqtt_handler.h basindaki JSON semasiyla BIREBIR AYNI alanlar.

    guven_kimyasal/guven_biyolojik/guven_fiziksel alanlari, karar motorunun
    UC turu de nasil degerlendirdigini (aciklanabilirlik) tasir -- sadece
    "kazanan" turu degil, ucunun de guven yuzdesini gosterir. Bu, mobil
    uygulamadaki "Neden bu karar?" panelinin veri kaynagidir.
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
    }
    return json.dumps(mesaj, ensure_ascii=False)


def calistir(broker: str, port: int, zone: int, aralik_sn: float, adim_sayisi: int | None) -> None:
    veri_konusu = f"aquaguard/zone{zone}/veri"
    durum_konusu = f"aquaguard/zone{zone}/durum"
    komut_konusu = f"aquaguard/zone{zone}/komut"

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
        _komut_isle(mesaj_json, calisma_durumu)

    istemci.on_connect = _baglaninca
    istemci.on_message = _mesaj_geldiginde

    print(f"[MQTT] Baglaniliyor: {broker}:{port} ...")
    istemci.connect(broker, port, keepalive=60)
    istemci.loop_start()

    print("=" * 78)
    print(f"AquaGuard Mock Yayinci - Zone {zone} - Konu: {veri_konusu}")
    print(f"Operatör komut konusu: {komut_konusu}")
    print(f"Yayin araligi: {aralik_sn} sn  |  Durdurmak icin Ctrl+C")
    print("=" * 78)

    sayac = 0
    try:
        while True:
            if not calisma_durumu["sulama_acik"]:
                # Ana vana kapali: senaryo uretecini ILERLETME (donduralm
                # kalsin) ve yeni veri yayinlama -- firmware/ana_vana.h ile
                # ayni davranis (bkz. dosya basi aciklamasi).
                time.sleep(aralik_sn)
                continue

            ornek, faz, tedavi_aktif, durulama_aktif = next(calisma_durumu["uretec"])
            teshis = kural_tabanli_teshis(ornek)
            if teshis["tur"]:
                calisma_durumu["guncel_tur"] = teshis["tur"]
            mesaj = _mesaj_olustur(ornek, teshis, zone, tedavi_aktif, durulama_aktif)

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
