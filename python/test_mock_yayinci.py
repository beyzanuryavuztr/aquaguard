"""
AquaGuard - Mock Yayinci Senaryo/Komut Testleri (pytest)
============================================================

Amac:
    aquaguard_mock_yayinci.py'nin senaryo ureteclerini (normal -> kotulesme ->
    tedavi -> durulama -> iyilesme) ve operator komut isleyicisini
    (_komut_isle -- Flutter tarafindaki manuel mudahale ozelliginin gercek
    MQTT brokerina karsi uctan uca calistigi kod yolu) dogrular. Bu mantik
    daha once sadece bir kerelik "python -c" ile elle test edilmisti (bkz.
    proje notlari) -- kalici, tekrar calistirilabilir bir test yoktu.

Calistirma:
    cd python
    python -m pytest test_mock_yayinci.py -v

Tarih:  2026-09-03
Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
"""

import itertools

import numpy as np
import pytest

from aquaguard_mock_yayinci import (
    FAZ_ADIM_SAYILARI,
    TEDAVI_ESLEME,
    TUR_ESLEME_TERS,
    _komut_isle,
    _mesaj_olustur,
    durulama_ve_iyilesme_adimlarini_uret,
    senaryo_adimlarini_uret,
    tedavi_ve_iyilesme_adimlarini_uret,
)
from aquaguard_karar_motoru import kural_tabanli_teshis


def _fazlari_al(uretec, adet):
    return [next(uretec)[1] for _ in range(adet)]


class TestSenaryoAdimlariUret:
    def test_faz_sirasi_dogru(self):
        rng = np.random.default_rng(1)
        uretec = senaryo_adimlarini_uret(rng)
        toplam = sum(FAZ_ADIM_SAYILARI.values())  # bir tam dongu
        fazlar = _fazlari_al(uretec, toplam)

        beklenen = (
            ["normal"] * FAZ_ADIM_SAYILARI["normal"]
            + ["kotulesme"] * FAZ_ADIM_SAYILARI["kotulesme"]
            + ["tedavi"] * FAZ_ADIM_SAYILARI["tedavi"]
            + ["durulama"] * FAZ_ADIM_SAYILARI["durulama"]
            + ["iyilesme"] * FAZ_ADIM_SAYILARI["iyilesme"]
        )
        assert fazlar == beklenen

    def test_sonsuz_dongu_ikinci_tura_gecer(self):
        rng = np.random.default_rng(2)
        uretec = senaryo_adimlarini_uret(rng)
        toplam = sum(FAZ_ADIM_SAYILARI.values())
        # Iki tam donguyu de tuket -- ikinci turun basi yine "normal" olmali.
        _fazlari_al(uretec, toplam)
        ikinci_tur_ilk_faz = next(uretec)[1]
        assert ikinci_tur_ilk_faz == "normal"

    def test_tedavi_fazinda_dogru_tedavi_adi_atanir(self):
        rng = np.random.default_rng(3)
        uretec = senaryo_adimlarini_uret(rng)
        # normal + kotulesme adimlarini atla, tedavinin ilk adimina gel.
        atlanacak = FAZ_ADIM_SAYILARI["normal"] + FAZ_ADIM_SAYILARI["kotulesme"]
        for _ in range(atlanacak):
            next(uretec)
        ornek, faz, tedavi_aktif, durulama_aktif = next(uretec)
        assert faz == "tedavi"
        assert tedavi_aktif in TEDAVI_ESLEME.values()
        assert durulama_aktif is False


class TestTedaviVeIyilesmeAdimlariUret:
    def test_dogru_tedavi_ile_baslar_ve_durulamayla_biter(self):
        rng = np.random.default_rng(4)
        uretec = tedavi_ve_iyilesme_adimlarini_uret("biyolojik", rng)
        adimlar = list(itertools.islice(uretec, 9))  # 3 tedavi + 2 durulama + 4 iyilesme

        ilk_uc = adimlar[: FAZ_ADIM_SAYILARI["tedavi"]]
        assert all(a[1] == "tedavi" and a[2] == "klor_enjeksiyon" for a in ilk_uc)
        assert all(a[3] is False for a in ilk_uc)

        kalan = adimlar[FAZ_ADIM_SAYILARI["tedavi"]:]
        assert any(a[3] is True for a in kalan), "durulama adimlari (durulama_aktif=True) olmali"


class TestDurulamaVeIyilesmeAdimlariUret:
    def test_once_durulama_sonra_normale_donus(self):
        rng = np.random.default_rng(5)
        uretec = durulama_ve_iyilesme_adimlarini_uret("fiziksel", rng)
        adimlar = list(itertools.islice(uretec, 6))

        assert adimlar[0][1] == "durulama"
        assert adimlar[0][2] == "yok"
        assert adimlar[0][3] is True
        assert adimlar[-1][3] is False  # iyilesme adiminda durulama bitmis olmali


class TestKomutIsle:
    def _durum(self, seed=42, guncel_tur=None):
        return {
            "uretec": senaryo_adimlarini_uret(np.random.default_rng(seed)),
            "rng": np.random.default_rng(seed),
            "guncel_tur": guncel_tur,
        }

    def test_tedavi_baslat_gecerli_tur_ile_dogru_tedaviyi_baslatir(self):
        calisma_durumu = self._durum()
        _komut_isle({"komut": "tedavi_baslat", "tedavi_turu": "klor_enjeksiyon"}, calisma_durumu)

        ilk_adim = next(calisma_durumu["uretec"])
        assert ilk_adim[1] == "tedavi"
        assert ilk_adim[2] == "klor_enjeksiyon"

    def test_tedavi_baslat_her_tedavi_turu_icin_dogru_esler(self):
        for tedavi_turu, beklenen_tur in TUR_ESLEME_TERS.items():
            calisma_durumu = self._durum()
            _komut_isle({"komut": "tedavi_baslat", "tedavi_turu": tedavi_turu}, calisma_durumu)
            ilk_adim = next(calisma_durumu["uretec"])
            assert ilk_adim[2] == TEDAVI_ESLEME[beklenen_tur]

    def test_tedavi_baslat_gecersiz_tur_ureteci_degistirmez(self):
        calisma_durumu = self._durum()
        eski_uretec = calisma_durumu["uretec"]
        _komut_isle({"komut": "tedavi_baslat", "tedavi_turu": "olmayan_tur"}, calisma_durumu)
        assert calisma_durumu["uretec"] is eski_uretec

    def test_tedavi_durdur_durulamaya_gecer(self):
        calisma_durumu = self._durum(guncel_tur="kimyasal")
        _komut_isle({"komut": "tedavi_durdur"}, calisma_durumu)

        ilk_adim = next(calisma_durumu["uretec"])
        assert ilk_adim[1] == "durulama"
        assert ilk_adim[2] == "yok"
        assert ilk_adim[3] is True

    def test_tedavi_durdur_guncel_tur_bilinmiyorsa_varsayilan_kullanir(self):
        calisma_durumu = self._durum(guncel_tur=None)
        # Hata firlatmamali (varsayilan "fiziksel" tur kullanilir).
        _komut_isle({"komut": "tedavi_durdur"}, calisma_durumu)
        ilk_adim = next(calisma_durumu["uretec"])
        assert ilk_adim[1] == "durulama"

    def test_normale_dondur_dogrudan_normal_baslatir(self):
        calisma_durumu = self._durum()
        _komut_isle({"komut": "normale_dondur"}, calisma_durumu)
        ilk_adim = next(calisma_durumu["uretec"])
        assert ilk_adim[1] == "normal"
        assert ilk_adim[2] == "yok"

    def test_bilinmeyen_komut_ureteci_degistirmez(self):
        calisma_durumu = self._durum()
        eski_uretec = calisma_durumu["uretec"]
        _komut_isle({"komut": "boyle_bir_komut_yok"}, calisma_durumu)
        assert calisma_durumu["uretec"] is eski_uretec

    def test_sulama_durdur_bayragi_kapatir(self):
        calisma_durumu = self._durum()
        calisma_durumu["sulama_acik"] = True
        _komut_isle({"komut": "sulama_durdur"}, calisma_durumu)
        assert calisma_durumu["sulama_acik"] is False

    def test_sulama_baslat_bayragi_acar(self):
        calisma_durumu = self._durum()
        calisma_durumu["sulama_acik"] = False
        _komut_isle({"komut": "sulama_baslat"}, calisma_durumu)
        assert calisma_durumu["sulama_acik"] is True

    def test_sulama_durdur_ureteci_DEGISTIRMEZ(self):
        # Ana vana kapatma, teshis akisindan bagimsizdir -- senaryo ureteci
        # ayni kalmali (donduralm kalir, degismez); calistir() dongusu bunu
        # ilerletmemeyi kendisi yonetir (bkz. calisma_durumu["sulama_acik"]).
        calisma_durumu = self._durum()
        eski_uretec = calisma_durumu["uretec"]
        _komut_isle({"komut": "sulama_durdur"}, calisma_durumu)
        assert calisma_durumu["uretec"] is eski_uretec


class TestMesajOlustur:
    def test_sema_firmware_ile_tutarli_alanlari_icerir(self):
        rng = np.random.default_rng(6)
        ornek = next(senaryo_adimlarini_uret(rng))[0]
        teshis = kural_tabanli_teshis(ornek)

        import json

        mesaj = json.loads(_mesaj_olustur(ornek, teshis, zone=1, tedavi_aktif="yok", durulama_aktif=False))

        beklenen_alanlar = {
            "zaman", "zone", "ph", "ec", "orp", "turbidite", "debi", "delta_basinc",
            "durum", "tikanma_turu", "guven", "guven_kimyasal", "guven_biyolojik",
            "guven_fiziksel", "tedavi_aktif", "durulama_aktif",
        }
        assert beklenen_alanlar.issubset(mesaj.keys())
        assert mesaj["zone"] == 1
        assert mesaj["tedavi_aktif"] == "yok"
        assert mesaj["durulama_aktif"] is False
