"""
AquaGuard - Karar Motoru ve Veri Ureticisi Testleri (pytest)
================================================================

Amac:
    aquaguard_karar_motoru.kural_tabanli_teshis() fonksiyonu, firmware/
    decision_engine.h ve aquaguard_mobile/lib/services/karar_motoru.dart
    dosyalarina BIREBIR PORTLANAN "referans" implementasyondur -- bu yuzden
    en cok kopyalanmis ve dolayisiyla en riskli koddur. Bu testler, brief
    SS6'daki literatur imzalarinin dogru siniflandirildigini ve esik
    mantiginin dogru calistigini somut assert'lerle dogrular (sadece
    "scripti calistir, ciktiya bak" yeterli degildir).

Calistirma:
    cd python
    python -m pytest test_karar_motoru.py -v

Tarih:  2026-09-01
Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
"""

import numpy as np
import pytest

from aquaguard_karar_motoru import kural_tabanli_teshis
from aquaguard_veri_uretici import (
    SENSOR_IMZALARI,
    SINIF_ORANLARI,
    TOPLAM_ORNEK,
    veri_seti_olustur,
)


def _sinifin_tam_ornegi(sinif: str) -> dict:
    """Bir sinifin TUM sensorlerinin ortalama degerinden olusan 'ideal' ornek."""
    return {sensor: imza[0] for sensor, imza in SENSOR_IMZALARI[sinif].items()}


class TestEsikTetikleyicileri:
    def test_hicbir_esik_asilmazsa_normal(self):
        sonuc = kural_tabanli_teshis(_sinifin_tam_ornegi("normal"))
        assert sonuc["durum"] == "normal"
        assert sonuc["tur"] is None
        assert sonuc["guven"] == 100.0

    def test_debi_tam_esikte_tetiklenir(self):
        ornek = _sinifin_tam_ornegi("normal")
        ornek["debi"] = 4.0 - 1.5  # REFERANS_DEBI - DEBI_DUSUS_ESIGI
        sonuc = kural_tabanli_teshis(ornek)
        assert sonuc["durum"] != "normal"

    def test_turbidite_esik_altinda_tetiklenmez(self):
        ornek = _sinifin_tam_ornegi("normal")
        ornek["turbidite"] = 11.99  # TURBIDITE_ESIGI = 12
        sonuc = kural_tabanli_teshis(ornek)
        assert sonuc["durum"] == "normal"


class TestTurSiniflandirmasi:
    @pytest.mark.parametrize("sinif", ["kimyasal", "biyolojik", "fiziksel"])
    def test_tam_imza_dogru_siniflandirilir(self, sinif):
        sonuc = kural_tabanli_teshis(_sinifin_tam_ornegi(sinif))
        assert sonuc["durum"] == "tespit_edildi"
        assert sonuc["tur"] == sinif
        assert sonuc["guven"] > 90


class TestAciklanabilirlik:
    def test_tum_guvenler_toplami_yaklasik_100(self):
        sonuc = kural_tabanli_teshis(_sinifin_tam_ornegi("biyolojik"))
        toplam = sum(sonuc["tum_guvenler"].values())
        assert toplam == pytest.approx(100.0, abs=0.01)

    def test_kazanan_turun_guveni_tum_guvenlerle_tutarli(self):
        sonuc = kural_tabanli_teshis(_sinifin_tam_ornegi("fiziksel"))
        assert sonuc["guven"] == pytest.approx(sonuc["tum_guvenler"]["fiziksel"])


class TestVeriUreticisi:
    def test_tekrarlanabilirlik_ayni_seed_ayni_veri(self):
        d1 = veri_seti_olustur()
        d2 = veri_seti_olustur()
        assert d1.equals(d2)

    def test_toplam_ornek_sayisi_dogru(self):
        veri = veri_seti_olustur()
        assert len(veri) == TOPLAM_ORNEK

    def test_sinif_dagilimi_orana_yakin(self):
        veri = veri_seti_olustur()
        dagilim = veri["sinif"].value_counts(normalize=True)
        for sinif, oran in SINIF_ORANLARI.items():
            assert dagilim[sinif] == pytest.approx(oran, abs=0.01)

    def test_eksik_deger_yok(self):
        veri = veri_seti_olustur()
        assert not veri.isna().any().any()

    def test_sensor_degerleri_fiziksel_sinirlar_icinde(self):
        veri = veri_seti_olustur()
        assert veri["ph"].between(4.0, 10.0).all()
        assert veri["debi"].between(0.2, 5.0).all()
        assert veri["turbidite"].between(0.0, 60.0).all()


class TestKararMotoruVeriSetiTutarliligi:
    """Egitim verisinin ORTALAMALARI, kural motorunun kullandigi ayni
    SENSOR_IMZALARI kaynagindan geldigi icin buyuk oranda tutarli olmalidir
    -- bu, iki dosyanin (veri uretici + karar motoru) birbirinden
    kopmadigini dogrular."""

    def test_kimyasal_ornekler_cogunlukla_kimyasal_teshis_edilir(self):
        veri = veri_seti_olustur()
        kimyasal_ornekler = veri[veri["sinif"] == "kimyasal"].sample(
            n=100, random_state=42
        )
        dogru_sayisi = sum(
            kural_tabanli_teshis(satir.to_dict())["tur"] == "kimyasal"
            for _, satir in kimyasal_ornekler.iterrows()
        )
        # Katman 1 tek basina (RF olmadan) makul cogunlugu yakalamali
        assert dogru_sayisi >= 60


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))
