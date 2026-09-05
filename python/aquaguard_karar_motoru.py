"""
AquaGuard - Iki Katmanli Tikanma Teshis Motoru
================================================

Amac:
    Sensor okumalarindan (pH, EC, ORP, turbidite, debi, delta_basinc) yola
    cikarak damlatici tikanmasini tespit eder ve turunu (kimyasal / biyolojik
    / fiziksel) belirler. Karar iki bagimsiz katmanin birlikte calismasiyla
    verilir:

    KATMAN 1 - Kural tabanli esik mantigi (BIRINCIL):
        Aciklanabilir, deterministik, mikrodenetleyicide de calisabilecek
        kadar basit bir mantik. Once "tikanma var mi" sorusuna (debi/basinc/
        turbidite esikleri) sonra "hangi turde" sorusuna (pH/EC/ORP'nin
        literatur imzalarina ne kadar yakin oldugu) cevap arar. Guven skoru
        dusukse "belirsiz" der, tedavi TETIKLEMEZ.

    KATMAN 2 - Random Forest siniflandirici (IKINCIL / DOGRULAYICI):
        Sentetik veri setiyle egitilir, kural katmaninin belirsiz kaldigi
        vakalari coder ve genel kararin istatistiksel olarak da tutarli
        oldugunu dogrular. Iki katman celisirse KURAL KATMANI KAZANIR
        (aciklanabilirlik ve saha guvenligi onceligi), ama operator her
        durumda bilgilendirilir.

    Bu iki katmanli tasarim, tek basina ne kural motorunun (esik disinda
    kalan yeni/nadir oruntuleri kacirabilir) ne de tek basina ML modelinin
    (kara kutu, aciklanamaz, sahada guvenilmez) yeterli olmamasindan dogar.

Kaynaklar:
    - Sensor esik/imza degerleri: PROJE_BRIEF.md SS6 (Lequette 2022,
      Shen 2022, Moulia 2024)
    - Sinif dagilimi ve hedef dogruluk: Abuzaid vd. (2024), Scientific Reports
    - Egitim verisi: aquaguard_veri_uretici.py (bu proje icinde uretilir)

Tarih:  2026-09-01
Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
"""

from __future__ import annotations

import math
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import ConfusionMatrixDisplay, classification_report, confusion_matrix
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split

from aquaguard_veri_uretici import (
    SENSOR_IMZALARI,
    SENSOR_SIRASI,
    SINIF_ORANLARI,
    veri_seti_olustur,
)

# ---------------------------------------------------------------------------
# 1) DOSYA YOLLARI
# ---------------------------------------------------------------------------

BU_KLASOR = Path(__file__).parent
VERI_YOLU = BU_KLASOR / "aquaguard_dataset.csv"
MODEL_KLASORU = BU_KLASOR / "model"
GORSEL_KLASORU = BU_KLASOR / "gorseller"

# ---------------------------------------------------------------------------
# 2) KATMAN 1 SABITLERI - Kural Tabanli Esik Mantigi
# ---------------------------------------------------------------------------

REFERANS_DEBI = 4.0            # Normal calisma debisi (LPM)
DEBI_DUSUS_ESIGI = 1.5         # LPM - bu kadar dusus tikanma isareti sayilir
BASINC_ARTIS_ESIGI = 0.36      # bar
TURBIDITE_ESIGI = 12           # NTU

GUVEN_ESIGI = 50.0             # % - bu esigin altinda durum "belirsiz"
TIP_SINIFLARI = ["kimyasal", "biyolojik", "fiziksel"]  # "normal" haric turler


def tikanma_tetikleyicilerini_kontrol_et(ornek: dict) -> dict:
    """
    Katman 1 - Asama A: "Tikanma var mi?" sorusuna hidrolik/turbidite
    esikleriyle cevap arar. Herhangi biri asilirsa tikanma var kabul edilir.
    """
    debi_dusus = (REFERANS_DEBI - ornek["debi"]) >= DEBI_DUSUS_ESIGI
    basinc_artis = ornek["delta_basinc"] >= BASINC_ARTIS_ESIGI
    turbidite_yuksek = ornek["turbidite"] >= TURBIDITE_ESIGI

    return {
        "debi_dusus": bool(debi_dusus),
        "basinc_artis": bool(basinc_artis),
        "turbidite_yuksek": bool(turbidite_yuksek),
        "tikanma_var": bool(debi_dusus or basinc_artis or turbidite_yuksek),
    }


def _log_gauss_yogunlugu(x: float, ortalama: float, std: float) -> float:
    """Bir degerin normal dagilima gore log-olabilirligi (log-likelihood)."""
    return -0.5 * ((x - ortalama) / std) ** 2 - math.log(std * math.sqrt(2 * math.pi))


def tur_guven_skorlarini_hesapla(ornek: dict) -> dict:
    """
    Katman 1 - Asama B: "Hangi turde?" sorusuna pH, EC, ORP degerlerinin
    literatur imzalarina (SENSOR_IMZALARI) ne kadar yakin oldugunu olcerek
    cevap arar.

    Her tur icin pH/EC/ORP'nin o turun normal dagilimina gore log-olabilirligi
    toplanir, ardindan softmax ile 0-100 arasi bir "guven yuzdesi"ne cevrilir.
    Bu, basit ama saglam bir Naive-Bayes tarzi olasilik skorlamasidir.
    """
    log_skorlar = {}
    for tur in TIP_SINIFLARI:
        imza = SENSOR_IMZALARI[tur]
        toplam = 0.0
        for sensor in ("ph", "ec", "orp"):
            ortalama, std = imza[sensor]
            toplam += _log_gauss_yogunlugu(ornek[sensor], ortalama, std)
        log_skorlar[tur] = toplam

    # Sayisal kararlilik icin softmax'tan once en buyuk log-skoru cikar
    en_buyuk = max(log_skorlar.values())
    ustel = {tur: math.exp(skor - en_buyuk) for tur, skor in log_skorlar.items()}
    toplam_ustel = sum(ustel.values())
    guvenler = {tur: 100.0 * deger / toplam_ustel for tur, deger in ustel.items()}

    return guvenler


def kural_tabanli_teshis(ornek: dict) -> dict:
    """
    Katman 1'in tam ciktisi: tikanma var mi, hangi turde, ne kadar guvenle.

    Donen "durum" alani ucten biridir:
        "normal"         -> hicbir esik asilmadi, tedavi gerekmez
        "belirsiz"        -> esik asildi ama tur guveni dusuk, operatore bildir,
                              tedavi TETIKLENMEZ (Katman 2'ye devredilir)
        "tespit_edildi"   -> esik asildi ve tur guvenle belirlendi, tedavi onerilir
    """
    tetikleyiciler = tikanma_tetikleyicilerini_kontrol_et(ornek)

    if not tetikleyiciler["tikanma_var"]:
        return {
            "durum": "normal",
            "tur": None,
            "guven": 100.0,
            "tetikleyiciler": tetikleyiciler,
        }

    guvenler = tur_guven_skorlarini_hesapla(ornek)
    en_olasi_tur = max(guvenler, key=guvenler.get)
    en_yuksek_guven = guvenler[en_olasi_tur]

    durum = "tespit_edildi" if en_yuksek_guven >= GUVEN_ESIGI else "belirsiz"

    return {
        "durum": durum,
        "tur": en_olasi_tur,
        "guven": round(en_yuksek_guven, 1),
        "tum_guvenler": {t: round(g, 1) for t, g in guvenler.items()},
        "tetikleyiciler": tetikleyiciler,
    }


# ---------------------------------------------------------------------------
# 3) KATMAN 2 - Random Forest Siniflandirici
# ---------------------------------------------------------------------------

def ozellik_hedef_ayir(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series]:
    """Veri cercevesini ozellikler (X) ve hedef etiket (y) olarak ayirir."""
    return df[SENSOR_SIRASI], df["sinif"]


def model_egit_ve_degerlendir(df: pd.DataFrame, seed: int = 42) -> dict:
    """
    Random Forest modelini egitir, 5-fold cross-validation ve ayri bir
    test bolmesiyle degerlendirir. Egitilmis model ve tum metrikleri doner.
    """
    X, y = ozellik_hedef_ayir(df)

    X_egitim, X_test, y_egitim, y_test = train_test_split(
        X, y, test_size=0.20, random_state=seed, stratify=y
    )

    model = RandomForestClassifier(
        n_estimators=200,
        max_depth=None,
        random_state=seed,
        class_weight="balanced",
    )
    model.fit(X_egitim, y_egitim)

    # 5-fold cross-validation (egitim verisi uzerinde, sizinti olmasin diye)
    kfold = StratifiedKFold(n_splits=5, shuffle=True, random_state=seed)
    cv_skorlari = cross_val_score(model, X_egitim, y_egitim, cv=kfold, scoring="accuracy")

    y_tahmin = model.predict(X_test)
    rapor = classification_report(y_test, y_tahmin, output_dict=True, zero_division=0)

    return {
        "model": model,
        "cv_skorlari": cv_skorlari,
        "cv_ortalama": cv_skorlari.mean(),
        "cv_std": cv_skorlari.std(),
        "X_test": X_test,
        "y_test": y_test,
        "y_tahmin": y_tahmin,
        "siniflandirma_raporu": rapor,
    }


def model_kaydet(model: RandomForestClassifier, dosya_adi: str = "aquaguard_model.pkl") -> Path:
    """Egitilmis modeli python/model/ klasorune .pkl olarak kaydeder."""
    MODEL_KLASORU.mkdir(exist_ok=True)
    yol = MODEL_KLASORU / dosya_adi
    joblib.dump(model, yol)
    return yol


# ---------------------------------------------------------------------------
# 4) IKI KATMANLI BIRLESIK KARAR
# ---------------------------------------------------------------------------

def iki_katmanli_teshis(ornek: dict, model: RandomForestClassifier) -> dict:
    """
    Katman 1 (kural) ve Katman 2 (RF) sonuclarini birlestirip nihai karari
    verir. Celiski kurallari brief'te tanimlandigi gibidir:

        - Katman 1 "normal" derse ve RF de "normal" derse -> normal.
        - Katman 1 "normal" der ama RF baska bir sey tahmin ederse -> kural
          birincil oldugu icin "normal" kalinir, ama not dusulur (izlemede).
        - Katman 1 "belirsiz" derse -> RF'in tahmini nihai karar olur
          (Katman 2'nin gorevi tam olarak budur: belirsiz vakalari cozmek).
        - Katman 1 net turde karar verdiyse (tespit_edildi) ve RF ayni
          turu tahmin ederse -> ikisi hemfikir, guven yuksek.
        - Katman 1 net turde karar verdi ama RF FARKLI bir tur tahmin
          ettiyse -> KURAL KATMANI KARARI KORUNUR, operator bilgilendirilir.
    """
    kural = kural_tabanli_teshis(ornek)

    X_ornek = pd.DataFrame([ornek])[SENSOR_SIRASI]
    rf_tahmin = model.predict(X_ornek)[0]
    rf_olasiliklar = dict(zip(model.classes_, model.predict_proba(X_ornek)[0]))
    rf_guven = round(100 * max(rf_olasiliklar.values()), 1)

    sonuc = {
        "kural_katmani": kural,
        "rf_tahmini": rf_tahmin,
        "rf_guveni": rf_guven,
        "operator_bilgilendir": False,
    }

    if kural["durum"] == "normal":
        sonuc["nihai_tur"] = None
        sonuc["kaynak"] = "kural (normal)"
        if rf_tahmin != "normal":
            sonuc["operator_bilgilendir"] = True
            sonuc["not"] = (
                f"Kural katmani normal diyor ama RF '{rf_tahmin}' egilimi goruyor "
                "(dusuk oncelikli izleme notu, tedavi tetiklenmedi)."
            )

    elif kural["durum"] == "belirsiz":
        sonuc["nihai_tur"] = rf_tahmin
        sonuc["kaynak"] = "RF (Katman 1 belirsizdi, Katman 2 cozdu)"
        sonuc["operator_bilgilendir"] = True
        if rf_tahmin == "normal":
            # ACIMASIZ DENETIM NOTU (2026-09-06): Katman 1 zaten en az bir
            # hidrolik esigi (debi/basinc/turbidite) asmisti (aksi halde
            # durum "belirsiz" degil dogrudan "normal" olurdu) -- RF'in
            # nihai kararinin "normal" olmasi bu tetiklemeyi GECERSIZ KILMAZ,
            # sadece RF'in bunu "gercek bir tikanma turune" baglayamadigi
            # anlamina gelir. Notu bunu ACIKCA belirtecek sekilde ozellestir
            # (aksi halde nihai_tur="normal" tek basina okunursa, Katman 1'in
            # zaten bir anomali tespit ettigi bilgisi kaybolur/gizlenir).
            sonuc["not"] = (
                "Katman 1 bir hidrolik esigi asti (belirsiz) ama Katman 2 (RF) "
                "bunu tur olarak siniflandiramadi ve 'normal' egilimi gosterdi -- "
                "bu, anomalinin GECERSIZ oldugu anlamina GELMEZ, sadece RF'in "
                "kesin bir tur atayamadigi anlamina gelir. Operator kural "
                "katmanindaki ham tetikleyicileri (kural_katmani alani) "
                "incelemelidir."
            )
        else:
            sonuc["not"] = "Katman 1 guven esiginin altinda kaldi, nihai karar RF'e devredildi."

    else:  # "tespit_edildi"
        sonuc["nihai_tur"] = kural["tur"]
        if rf_tahmin == kural["tur"]:
            sonuc["kaynak"] = "kural + RF hemfikir"
        else:
            sonuc["kaynak"] = f"kural (RF farkli tahmin etti: {rf_tahmin})"
            sonuc["operator_bilgilendir"] = True
            sonuc["not"] = (
                f"Iki katman celisti: kural katmani '{kural['tur']}', "
                f"RF '{rf_tahmin}' diyor. Guvenlik geregi kural katmani karari "
                "uygulanacak, operator bilgilendirildi."
            )

    return sonuc


# ---------------------------------------------------------------------------
# 5) GORSELLESTIRME FONKSIYONLARI
# ---------------------------------------------------------------------------

def confusion_matrix_ciz(y_test, y_tahmin, siniflar: list[str], yol: Path) -> None:
    cm = confusion_matrix(y_test, y_tahmin, labels=siniflar)
    fig, ax = plt.subplots(figsize=(6, 5))
    ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=siniflar).plot(
        ax=ax, cmap="Blues", colorbar=True
    )
    ax.set_title("AquaGuard - Karisiklik Matrisi (Test Seti)")
    ax.set_xlabel("Tahmin Edilen Sinif")
    ax.set_ylabel("Gercek Sinif")
    fig.tight_layout()
    fig.savefig(yol, dpi=150)
    plt.close(fig)


def siniflandirma_raporu_tablosu_ciz(rapor: dict, siniflar: list[str], yol: Path) -> None:
    satirlar = []
    for sinif in siniflar:
        m = rapor[sinif]
        satirlar.append([sinif, f"{m['precision']:.2f}", f"{m['recall']:.2f}", f"{m['f1-score']:.2f}", int(m["support"])])
    satirlar.append([
        "genel dogruluk", "", "", f"{rapor['accuracy']:.2f}", int(rapor["macro avg"]["support"])
    ])

    fig, ax = plt.subplots(figsize=(7, 1.2 + 0.5 * len(satirlar)))
    ax.axis("off")
    tablo = ax.table(
        cellText=satirlar,
        colLabels=["Sinif", "Precision", "Recall", "F1-Skoru", "Ornek Sayisi"],
        loc="center",
        cellLoc="center",
    )
    tablo.auto_set_font_size(False)
    tablo.set_fontsize(10)
    tablo.scale(1, 1.6)
    ax.set_title("AquaGuard - Sinif Bazli Performans Tablosu", pad=20)
    fig.tight_layout()
    fig.savefig(yol, dpi=150)
    plt.close(fig)


def cv_dogruluk_grafigi_ciz(cv_skorlari: np.ndarray, yol: Path) -> None:
    fig, ax = plt.subplots(figsize=(6, 4))
    fold_no = list(range(1, len(cv_skorlari) + 1))
    ax.bar(fold_no, cv_skorlari * 100, color="#2E86AB")
    ax.axhline(cv_skorlari.mean() * 100, color="#A23B72", linestyle="--",
               label=f"Ortalama: %{cv_skorlari.mean() * 100:.1f}")
    ax.set_xlabel("Fold Numarasi")
    ax.set_ylabel("Dogruluk (%)")
    ax.set_ylim(0, 100)
    ax.set_title("AquaGuard - 5-Fold Cross-Validation Dogrulugu")
    ax.legend()
    fig.tight_layout()
    fig.savefig(yol, dpi=150)
    plt.close(fig)


def sensor_dagilim_grafikleri_ciz(df: pd.DataFrame, yol: Path) -> None:
    fig, eksenler = plt.subplots(2, 3, figsize=(14, 8))
    sinif_sirasi = list(SINIF_ORANLARI.keys())
    for eksen, sensor in zip(eksenler.flat, SENSOR_SIRASI):
        sns.boxplot(data=df, x="sinif", y=sensor, order=sinif_sirasi, ax=eksen, palette="Set2")
        eksen.set_title(sensor.upper())
        eksen.set_xlabel("")
    fig.suptitle("AquaGuard - Sinif Bazli Sensor Dagilimlari", fontsize=14)
    fig.tight_layout()
    fig.savefig(yol, dpi=150)
    plt.close(fig)


def ozellik_onem_grafigi_ciz(model: RandomForestClassifier, yol: Path) -> None:
    onemler = pd.Series(model.feature_importances_, index=SENSOR_SIRASI).sort_values()
    fig, ax = plt.subplots(figsize=(6, 4))
    onemler.plot.barh(ax=ax, color="#2E86AB")
    ax.set_xlabel("Ozellik Onemi (Gini)")
    ax.set_title("AquaGuard - Random Forest Ozellik Onem Siralamasi")
    fig.tight_layout()
    fig.savefig(yol, dpi=150)
    plt.close(fig)


# ---------------------------------------------------------------------------
# 6) ANA CALISTIRMA BLOGU
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if VERI_YOLU.exists():
        veri = pd.read_csv(VERI_YOLU)
    else:
        print("Veri seti bulunamadi, aquaguard_veri_uretici.py cagriliyor...")
        veri = veri_seti_olustur()
        veri.to_csv(VERI_YOLU, index=False)

    print("=" * 78)
    print("AquaGuard Karar Motoru - Model Egitimi")
    print("=" * 78)

    sonuclar = model_egit_ve_degerlendir(veri)
    model = sonuclar["model"]

    print(f"\n5-Fold Cross-Validation dogrulugu: "
          f"%{sonuclar['cv_ortalama'] * 100:.1f} +/- %{sonuclar['cv_std'] * 100:.1f}")
    print(f"Test seti genel dogrulugu: %{sonuclar['siniflandirma_raporu']['accuracy'] * 100:.1f}")

    siniflar = sorted(veri["sinif"].unique())
    print("\nSinif bazli performans:")
    for sinif in siniflar:
        m = sonuclar["siniflandirma_raporu"][sinif]
        print(f"  {sinif:<12} precision=%{m['precision']*100:5.1f}  "
              f"recall=%{m['recall']*100:5.1f}  f1=%{m['f1-score']*100:5.1f}")

    # --- Gorselleri uret ---
    GORSEL_KLASORU.mkdir(exist_ok=True)
    confusion_matrix_ciz(sonuclar["y_test"], sonuclar["y_tahmin"], siniflar,
                          GORSEL_KLASORU / "karisiklik_matrisi.png")
    siniflandirma_raporu_tablosu_ciz(sonuclar["siniflandirma_raporu"], siniflar,
                                      GORSEL_KLASORU / "performans_tablosu.png")
    cv_dogruluk_grafigi_ciz(sonuclar["cv_skorlari"], GORSEL_KLASORU / "cv_dogruluk_grafigi.png")
    sensor_dagilim_grafikleri_ciz(veri, GORSEL_KLASORU / "sensor_dagilimlari.png")
    ozellik_onem_grafigi_ciz(model, GORSEL_KLASORU / "ozellik_onemi.png")
    print(f"\nGorseller kaydedildi: {GORSEL_KLASORU}")

    # --- Modeli kaydet ---
    model_yolu = model_kaydet(model)
    print(f"Model kaydedildi: {model_yolu}")

    # --- Iki katmanli motoru ornek vakalarla goster ---
    print("\n" + "=" * 78)
    print("Iki Katmanli Motor - Ornek Vaka Testleri")
    print("=" * 78)

    ornek_vakalar = [
        {"ad": "Acik normal vaka", "ph": 7.0, "ec": 1.15, "orp": 375, "turbidite": 3, "debi": 4.0, "delta_basinc": 0.10},
        {"ad": "Acik kimyasal vaka", "ph": 8.3, "ec": 2.75, "orp": 310, "turbidite": 10, "debi": 2.6, "delta_basinc": 0.40},
        {"ad": "Acik biyolojik vaka", "ph": 6.6, "ec": 1.50, "orp": 175, "turbidite": 20, "debi": 3.0, "delta_basinc": 0.32},
        {"ad": "Acik fiziksel vaka", "ph": 7.0, "ec": 1.15, "orp": 350, "turbidite": 35, "debi": 1.8, "delta_basinc": 0.60},
        {"ad": "Sinir durumu (belirsiz olabilir)", "ph": 7.4, "ec": 1.6, "orp": 300, "turbidite": 13, "debi": 3.3, "delta_basinc": 0.30},
    ]

    for vaka in ornek_vakalar:
        ornek = {k: v for k, v in vaka.items() if k != "ad"}
        sonuc = iki_katmanli_teshis(ornek, model)
        print(f"\n{vaka['ad']}:")
        print(f"  Katman 1: durum={sonuc['kural_katmani']['durum']}, "
              f"tur={sonuc['kural_katmani']['tur']}, guven=%{sonuc['kural_katmani']['guven']}")
        print(f"  Katman 2 (RF): tahmin={sonuc['rf_tahmini']}, guven=%{sonuc['rf_guveni']}")
        print(f"  NIHAI KARAR: {sonuc['nihai_tur']}  |  kaynak: {sonuc['kaynak']}")
        if sonuc["operator_bilgilendir"]:
            print(f"  [OPERATOR BILDIRIMI] {sonuc.get('not', '')}")
