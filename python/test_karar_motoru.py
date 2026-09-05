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

from aquaguard_karar_motoru import iki_katmanli_teshis, kural_tabanli_teshis
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
        # NOT (acimasiz denetim, 2026-09-06): bu, SADECE debi dususu (pH/EC/ORP
        # tamamen "normal" imzasinda) tetiklendiginde turun "fiziksel" cikmasi
        # GERCEKTEN BEKLENEN davranistir -- brief SS6'daki sinif tanimina gore
        # fiziksel tikanmanin (sediman/partikul) imzasi zaten "hidrolik anomali
        # + degismemis su kimyasi"dir, yani normal'e neredeyse ozdestir. Onceki
        # surumde bu test SADECE durum!='normal' kontrol ediyordu -- tur/guven
        # hic dogrulanmiyordu, bu da (ornegin) tek bir gurultulu/hatali
        # kalibre debi sensorunun neden oldugu YANLIŞ POZITIF bir "fiziksel
        # tikanma tespit edildi (%100 guven)" ciktisini SESSIZCE gizleyebilirdi.
        # Asagidaki assert'ler bu davranisi ACIKCA belgeler -- degisirse (ör.
        # sensor gurultusune karsi bir tolerans/coklu-okuma dogrulamasi
        # eklenirse) bu test BILINCLI olarak guncellenmelidir.
        ornek = _sinifin_tam_ornegi("normal")
        ornek["debi"] = 4.0 - 1.5  # REFERANS_DEBI - DEBI_DUSUS_ESIGI
        sonuc = kural_tabanli_teshis(ornek)
        assert sonuc["durum"] == "tespit_edildi"
        assert sonuc["tur"] == "fiziksel"
        assert sonuc["guven"] > 50.0

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


class _SahteModel:
    """iki_katmanli_teshis()'in RF KATMANINI degil, KENDI DALLANMA
    MANTIGINI test etmek icin -- gercek bir egitilmis modele bagimli
    olmadan RF'in ne tahmin ettigini TAM KONTROL eder (acimasiz denetimde
    bulundu: iki_katmanli_teshis() daha once HIC test edilmiyordu, 2026-09-06).
    """

    def __init__(self, tahmin: str, olasiliklar: dict):
        self.classes_ = list(olasiliklar.keys())
        self._tahmin = tahmin
        self._olasiliklar = olasiliklar

    def predict(self, X):
        return [self._tahmin]

    def predict_proba(self, X):
        return [[self._olasiliklar[sinif] for sinif in self.classes_]]


class TestIkiKatmanliTeshis:
    def test_kural_normal_rf_hemfikirse_nihai_tur_none_ve_bilgilendirme_yok(self):
        ornek = _sinifin_tam_ornegi("normal")
        model = _SahteModel("normal", {"normal": 0.9, "kimyasal": 0.05, "biyolojik": 0.03, "fiziksel": 0.02})

        sonuc = iki_katmanli_teshis(ornek, model)

        assert sonuc["nihai_tur"] is None
        assert sonuc["kaynak"] == "kural (normal)"
        assert sonuc["operator_bilgilendir"] is False

    def test_kural_normal_rf_anomali_gorurse_operator_bilgilendirilir_ama_karar_normal_kalir(self):
        ornek = _sinifin_tam_ornegi("normal")
        model = _SahteModel("kimyasal", {"normal": 0.2, "kimyasal": 0.7, "biyolojik": 0.05, "fiziksel": 0.05})

        sonuc = iki_katmanli_teshis(ornek, model)

        assert sonuc["nihai_tur"] is None
        assert sonuc["operator_bilgilendir"] is True

    def test_kural_tespit_ve_rf_hemfikirse_karar_ve_kaynak_dogru(self):
        ornek = _sinifin_tam_ornegi("kimyasal")
        model = _SahteModel("kimyasal", {"normal": 0.05, "kimyasal": 0.85, "biyolojik": 0.05, "fiziksel": 0.05})

        sonuc = iki_katmanli_teshis(ornek, model)

        assert sonuc["nihai_tur"] == "kimyasal"
        assert sonuc["kaynak"] == "kural + RF hemfikir"
        assert sonuc["operator_bilgilendir"] is False

    def test_kural_tespit_rf_celisirse_kural_katmani_kazanir_ve_bilgilendirme_yapilir(self):
        ornek = _sinifin_tam_ornegi("kimyasal")
        model = _SahteModel("biyolojik", {"normal": 0.05, "kimyasal": 0.1, "biyolojik": 0.8, "fiziksel": 0.05})

        sonuc = iki_katmanli_teshis(ornek, model)

        # GUVENLIK GEREGI: iki katman celisirse kural katmaninin karari korunur.
        assert sonuc["nihai_tur"] == "kimyasal"
        assert sonuc["operator_bilgilendir"] is True
        assert "celisti" in sonuc["not"]

    def test_kural_belirsizse_rf_tahmini_nihai_karar_olur_ve_her_zaman_bilgilendirilir(self):
        # Katman 1'in GERCEKTEN "belirsiz" (durum=belirsiz, tespit_edildi
        # DEGIL) donmesi icin, fiziksel ve kimyasal imzalari arasinda TAM
        # gecis noktasina yakin bir pH/EC/ORP karisimi + bir debi tetikleyicisi
        # kullanilir -- t=0.399 (fiziksel imzasindan kimyasala dogru interpolasyon
        # orani) deneysel olarak guveni %49.7'ye (esik %50'nin altina) dusurdugu
        # dogrulanmistir (bkz. proje notlari, ayni yontem karar_motoru_test.dart'ta
        # da kullanilmisti).
        fiziksel = _sinifin_tam_ornegi("fiziksel")
        kimyasal = _sinifin_tam_ornegi("kimyasal")
        t = 0.399
        ornek = dict(fiziksel)
        for sensor in ("ph", "ec", "orp"):
            ornek[sensor] = fiziksel[sensor] * (1 - t) + kimyasal[sensor] * t
        ornek["debi"] = 4.0 - 1.5  # REFERANS_DEBI - DEBI_DUSUS_ESIGI

        kural = kural_tabanli_teshis(ornek)
        assert kural["durum"] == "belirsiz", (
            f"Beklenen 'belirsiz' ama '{kural['durum']}' geldi (guven={kural['guven']}) -- "
            "esik degerleri veya imza sabitleri degismis olabilir, t degeri yeniden ayarlanmali."
        )

        model_rf_normal = _SahteModel("normal", {"normal": 0.6, "kimyasal": 0.2, "biyolojik": 0.1, "fiziksel": 0.1})
        sonuc = iki_katmanli_teshis(ornek, model_rf_normal)
        assert sonuc["nihai_tur"] == "normal"
        assert sonuc["operator_bilgilendir"] is True
        assert "GECERSIZ" in sonuc["not"] or "gecersiz" in sonuc["not"].lower()

        model_rf_tur = _SahteModel("fiziksel", {"normal": 0.1, "kimyasal": 0.1, "biyolojik": 0.1, "fiziksel": 0.7})
        sonuc2 = iki_katmanli_teshis(ornek, model_rf_tur)
        assert sonuc2["nihai_tur"] == "fiziksel"
        assert sonuc2["operator_bilgilendir"] is True


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))
