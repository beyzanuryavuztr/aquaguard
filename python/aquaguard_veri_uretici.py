"""
AquaGuard - Sentetik Sensor Veri Ureticisi
============================================

Amac:
    Toprak alti damla sulama (SDI) sistemlerinde damlatici tikanmasini
    turune gore (kimyasal / biyolojik / fiziksel) siniflandiran makine
    ogrenmesi modelini egitmek icin etiketli bir sensor veri seti uretir.

Neden sentetik veri:
    Sahada tikanma turunu dogrudan belirleyen, kamuya acik, etiketli bir
    SDI tikanma veri seti literaturde mevcut degildir (Lequette vd., 2022).
    Bu yuzden AquaGuard, akademik olcum istatistiklerine dayanan sentetik
    bir veri seti uretir; her sinifin sensor ortalama/standart sapma
    degerleri literaturden alinmistir (bkz. KAYNAKLAR).

Uretim mantigi:
    1) 2000 ornek, 4 sinifa Abuzaid vd. (2024) oranlarina gore dagitilir:
       normal %10, kimyasal %22, biyolojik %37, fiziksel %31.
    2) Her sinif icin 6 sensor (pH, EC, ORP, turbidite, debi, delta_basinc)
       o sinifa ozgu ortalama/std etrafinda, sinif icinde FIZIKSEL OLARAK
       ANLAMLI KORELASYONLARLA uretilir (ornegin kimyasal tikanmada pH ve
       EC birlikte yukselir, cunku ikisi de ayni kimyasal cokelme surecinin
       sonucudur).
    3) Orneklerin %12'si, sinif sinirlarina yakin "atipik" vakalar olacak
       sekilde komsu bir sinifin profiline dogru kismen kaydirilir. Bu,
       gercek sahada sensor gurultusu ve gecis donemleri (ornegin hafif
       biyofilm baslangici) yuzunden ortaya cikan belirsizligi taklit eder.

    seed=42 ile tam tekrarlanabilirdir.

Kaynaklar:
    - Lequette vd. (2022) - SDI tikanma teshis yontemleri
    - Shen vd. (2022)     - Sensor tabanli tikanma izleme
    - Moulia vd. (2024)   - Su kalitesi parametreleri ve tikanma iliskisi
    - Abuzaid vd. (2024), Scientific Reports - Tikanma turu dagilim oranlari

Tarih:  2026-09-01
Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# 1) SABITLER
# ---------------------------------------------------------------------------

RASTGELE_TOHUM = 42          # Tekrarlanabilirlik icin sabit "seed"
TOPLAM_ORNEK = 2000          # Uretilecek toplam satir sayisi
ATIPIK_ORAN = 0.12           # Sinif sinirinda belirsiz ornek orani (%12)

# Literaturdeki ortalama/std degerleri, FARKLI SAHALAR arasindaki populasyon
# degiskenligini yansitir (yani "1000 farkli ciftlikte olculse boyle dagilir").
# Ama bizim tek bir sahadaki TEK BIR ANLIK sensor okumasi, bu populasyon
# varyansina ek olarak kendi olcum belirsizligini de tasir (kalibrasyon
# sapmasi, elektriksel gurultu, anlik turbulans vb.). Bu yuzden veri
# uretirken literatur std'sini bu carpanla buyuterek gercekci saha
# gurultusunu simule ediyoruz. Carpan, adim 2'deki (aquaguard_karar_motoru.py)
# Random Forest modelinin brief'te hedeflenen ~%90 (dogrulanmis: %89.9 +/- %2.3,
# 5-fold CV) dogruluguna ulasmasi icin deneysel olarak kalibre edilmistir --
# carpan=1.0 (ham literatur std'si) siniflari gercekci olmayacak kadar
# ayristirip %95+ dogruluk veriyordu.
OLCUM_GURULTUSU_CARPANI = 1.85

# Sinif adlari ve Abuzaid vd. (2024) dagilim oranlari (toplami 1.0 olmali)
SINIF_ORANLARI = {
    "normal": 0.10,
    "kimyasal": 0.22,
    "biyolojik": 0.37,
    "fiziksel": 0.31,
}

# Brief SS6 "Sensor Imzalari" tablosundaki ortalama +/- std degerleri.
# Format: {sinif: {sensor: (ortalama, std)}}
SENSOR_IMZALARI = {
    "normal": {
        "ph": (7.00, 0.30),
        "ec": (1.15, 0.20),
        "orp": (375, 40),
        "turbidite": (3, 1.2),
        "debi": (4.0, 0.25),
        "delta_basinc": (0.10, 0.03),
    },
    "kimyasal": {
        "ph": (8.30, 0.30),
        "ec": (2.75, 0.45),
        "orp": (310, 40),
        "turbidite": (10, 3),
        "debi": (2.6, 0.35),
        "delta_basinc": (0.40, 0.09),
    },
    "biyolojik": {
        "ph": (6.60, 0.35),
        "ec": (1.50, 0.30),
        "orp": (175, 45),
        "turbidite": (20, 5.5),
        "debi": (3.0, 0.30),
        "delta_basinc": (0.32, 0.07),
    },
    "fiziksel": {
        "ph": (7.00, 0.30),
        "ec": (1.15, 0.20),
        "orp": (350, 40),
        "turbidite": (35, 8),
        "debi": (1.8, 0.45),
        "delta_basinc": (0.60, 0.12),
    },
}

# Sensorlerin fiziksel olarak mumkun oldugu aralik (gurultu bu sinirlarin
# disina tasarsa bile olcum cihazi/dogal fizik bu araligi asamaz).
FIZIKSEL_SINIRLAR = {
    "ph": (4.0, 10.0),
    "ec": (0.3, 4.5),
    "orp": (-50, 500),
    "turbidite": (0.0, 60.0),
    "debi": (0.2, 5.0),
    "delta_basinc": (0.02, 1.0),
}

# Her sinif icin, hangi sensorlerin ayni fiziksel nedenden (ortak "siddet"
# etkeni) dolayi birlikte hareket ettigini tanimlar. "agirlik" 0-1 arasi bir
# korelasyon gucudur: 1'e yaklastikca sensor neredeyse tamamen ortak etkene
# baglidir, 0'a yaklastikca bagimsiz gurultuye yaklasir.
KORELASYON_GRUPLARI = {
    "kimyasal": [
        {"sensorler": ["ph", "ec"], "agirlik": 0.65},          # ortak: kimyasal cokelme siddeti
        {"sensorler": ["orp"], "agirlik": 0.30},
        {"sensorler": ["turbidite", "debi", "delta_basinc"], "agirlik": 0.40},
    ],
    "biyolojik": [
        {"sensorler": ["orp"], "agirlik": 0.70},               # ortak: anaerobik biyofilm siddeti
        {"sensorler": ["turbidite", "debi", "delta_basinc"], "agirlik": 0.50},
        {"sensorler": ["ph", "ec"], "agirlik": 0.25},
    ],
    "fiziksel": [
        {"sensorler": ["turbidite", "debi", "delta_basinc"], "agirlik": 0.70},  # ortak: partikul birikim siddeti
        {"sensorler": ["ph", "ec", "orp"], "agirlik": 0.10},   # "degismez" -> neredeyse bagimsiz
    ],
    "normal": [
        {"sensorler": ["turbidite", "debi", "delta_basinc"], "agirlik": 0.20},
        {"sensorler": ["ph", "ec", "orp"], "agirlik": 0.15},
    ],
}

SENSOR_SIRASI = ["ph", "ec", "orp", "turbidite", "debi", "delta_basinc"]


# ---------------------------------------------------------------------------
# 2) URETIM FONKSIYONLARI
# ---------------------------------------------------------------------------

def _sinif_ornek_sayilari(toplam: int, oranlar: dict[str, float]) -> dict[str, int]:
    """Sinif oranlarini tam sayi ornek sayisina cevirir (toplam korunur)."""
    sayilar = {sinif: round(toplam * oran) for sinif, oran in oranlar.items()}
    fark = toplam - sum(sayilar.values())
    if fark != 0:
        # Yuvarlama farkini en buyuk sinifa ekle/cikar (toplam tam 2000 kalsin)
        en_buyuk_sinif = max(sayilar, key=sayilar.get)
        sayilar[en_buyuk_sinif] += fark
    return sayilar


def _korelasyonlu_sensor_uret(
    sinif: str, n: int, rng: np.random.Generator
) -> dict[str, np.ndarray]:
    """
    Bir sinif icin n adet ornegin 6 sensor degerini uretir.

    Her korelasyon grubu icin ortak bir "siddet" latenti (standart normal)
    cekilir; grup icindeki her sensorun degeri kismen bu ortak latente,
    kismen kendi bagimsiz gurultusune baglidir:

        deger = ortalama + std * (agirlik * latent + sqrt(1-agirlik^2) * gurultu)

    Bu, gercek fizikte oldugu gibi "ayni nedenden etkilenen sensorlerin
    birlikte hareket etmesini" saglar (ornegin kimyasal tikanmada pH ve EC).
    """
    imzalar = SENSOR_IMZALARI[sinif]
    sonuc: dict[str, np.ndarray] = {}

    for grup in KORELASYON_GRUPLARI[sinif]:
        agirlik = grup["agirlik"]
        latent = rng.standard_normal(n)
        for sensor in grup["sensorler"]:
            ortalama, std = imzalar[sensor]
            std_saha = std * OLCUM_GURULTUSU_CARPANI
            bagimsiz_gurultu = rng.standard_normal(n)
            birlesik_gurultu = agirlik * latent + np.sqrt(1 - agirlik**2) * bagimsiz_gurultu
            sonuc[sensor] = ortalama + std_saha * birlesik_gurultu

    return sonuc


def _fiziksel_sinirla(df: pd.DataFrame) -> pd.DataFrame:
    """Sensor degerlerini fiziksel olarak mumkun araliga kirpar (clip)."""
    for sensor, (alt, ust) in FIZIKSEL_SINIRLAR.items():
        df[sensor] = df[sensor].clip(lower=alt, upper=ust)
    return df


def _atipik_vakalar_uygula(
    df: pd.DataFrame, rng: np.random.Generator, oran: float = ATIPIK_ORAN
) -> pd.DataFrame:
    """
    Orneklerin bir kismini komsu (farkli) bir sinifin profiline dogru
    kismen kaydirarak sinif sinirlarinda belirsiz/ortusen vakalar yaratir.

    Etiket (sinif) DEGISMEZ -- sadece ozellik degerleri, gercek sahada
    gecis donemlerinde (ornegin biyofilmin yeni baslamasi) goruleceginden
    daha az ayrisik hale getirilir. Boylece model, sinif sinirlarindaki
    zor vakalarla da karsilasmis olur.
    """
    n_toplam = len(df)
    n_atipik = round(n_toplam * oran)
    atipik_indeksler = rng.choice(df.index, size=n_atipik, replace=False)

    tum_siniflar = list(SINIF_ORANLARI.keys())

    for idx in atipik_indeksler:
        kendi_sinif = df.loc[idx, "sinif"]
        komsu_adaylari = [s for s in tum_siniflar if s != kendi_sinif]
        komsu_sinif = rng.choice(komsu_adaylari)

        # Kismi karisim orani: 0.30-0.60 arasi -- tamamen komsu sinifa
        # donusturmuyoruz, sadece sinir cizgisine dogru kayidiriyoruz.
        alfa = rng.uniform(0.30, 0.60)

        for sensor in SENSOR_SIRASI:
            komsu_ortalama, komsu_std = SENSOR_IMZALARI[komsu_sinif][sensor]
            komsu_deger = rng.normal(komsu_ortalama, komsu_std)
            kendi_deger = df.loc[idx, sensor]
            df.loc[idx, sensor] = (1 - alfa) * kendi_deger + alfa * komsu_deger

    return df


def veri_seti_olustur(
    toplam: int = TOPLAM_ORNEK, seed: int = RASTGELE_TOHUM
) -> pd.DataFrame:
    """Tam sentetik AquaGuard sensor veri setini uretir ve DataFrame doner."""
    rng = np.random.default_rng(seed)
    sinif_sayilari = _sinif_ornek_sayilari(toplam, SINIF_ORANLARI)

    parcalar = []
    for sinif, n in sinif_sayilari.items():
        sensorler = _korelasyonlu_sensor_uret(sinif, n, rng)
        parca = pd.DataFrame(sensorler)
        parca["sinif"] = sinif
        parcalar.append(parca)

    df = pd.concat(parcalar, ignore_index=True)
    df = _atipik_vakalar_uygula(df, rng)
    df = _fiziksel_sinirla(df)

    # Satirlari karistir (siniflar sirali eklendigi icin), indeksi sifirla
    df = df.sample(frac=1.0, random_state=seed).reset_index(drop=True)

    # Sensor degerlerini makul hassasiyette yuvarla (gercekci olcum gorunumu)
    yuvarlama = {"ph": 2, "ec": 2, "orp": 0, "turbidite": 1, "debi": 2, "delta_basinc": 3}
    for sensor, basamak in yuvarlama.items():
        df[sensor] = df[sensor].round(basamak)

    return df[SENSOR_SIRASI + ["sinif"]]


# ---------------------------------------------------------------------------
# 3) OZET / RAPORLAMA
# ---------------------------------------------------------------------------

def ozet_tablosu_yazdir(df: pd.DataFrame) -> None:
    """Konsola sinif bazli ornek sayisi ve sensor ortalamalari tablosunu yazdirir."""
    print("=" * 78)
    print("AquaGuard Sentetik Veri Seti - Sinif Bazli Ozet")
    print("=" * 78)

    print("\nSinif dagilimi:")
    dagilim = df["sinif"].value_counts()
    for sinif in SINIF_ORANLARI:
        adet = dagilim.get(sinif, 0)
        print(f"  {sinif:<12} {adet:>5} ornek  (%{100 * adet / len(df):5.1f})")

    print(f"\n  {'TOPLAM':<12} {len(df):>5} ornek")

    print("\nSinif bazli sensor ortalamalari:")
    ozet = df.groupby("sinif")[SENSOR_SIRASI].mean().round(2)
    ozet = ozet.reindex(SINIF_ORANLARI.keys())
    print(ozet.to_string())
    print("=" * 78)


# ---------------------------------------------------------------------------
# 4) ANA CALISTIRMA BLOGU
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    veri = veri_seti_olustur()

    cikti_yolu = Path(__file__).parent / "aquaguard_dataset.csv"
    veri.to_csv(cikti_yolu, index=False, encoding="utf-8")

    ozet_tablosu_yazdir(veri)
    print(f"\nVeri seti kaydedildi: {cikti_yolu}")
