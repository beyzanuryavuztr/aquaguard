/*
 * AquaGuard - Kural Tabanli Karar Motoru (Gomulu Sistem)
 * =========================================================
 *
 * Amac:
 *   python/aquaguard_karar_motoru.py dosyasindaki KATMAN 1 (kural tabanli
 *   esik mantigi) buraya birebir tasinmistir. Katman 2 (Random Forest)
 *   kaynak kisitlari nedeniyle Deneyap Kart uzerinde CALISMAZ -- bu yuzden
 *   sahada nihai karari veren tek mekanizma bu dosyadir. Karar aciklanabilir
 *   ve deterministik olmalidir; guven dusukse tedavi TETIKLENMEZ, sadece
 *   operator bilgilendirilir (bkz. treatment.h / mqtt_handler.h).
 *
 * Iki asamali mantik:
 *   ASAMA A - "Tikanma var mi?"
 *     Debi dususu VEYA basinc artisi VEYA turbidite yuksekligi esiklerinden
 *     herhangi biri asilirsa tikanma var kabul edilir.
 *   ASAMA B - "Hangi turde?"
 *     pH, EC, ORP degerlerinin her turun (kimyasal/biyolojik/fiziksel)
 *     literatur imzasina (ortalama +/- std) ne kadar yakin oldugu, normal
 *     dagilimin log-olabilirligi (log-likelihood) ile olculur. En yuksek
 *     olabilirlige sahip tur secilir; softmax ile 0-100 guven yuzdesine
 *     cevrilir. Guven GUVEN_ESIGI altindaysa durum "belirsiz" olur.
 *
 * ONEMLI: Bu dosyadaki esik/imza sabitleri config.h icinde tanimlidir ve
 * python/aquaguard_karar_motoru.py ile BIREBIR AYNI tutulmalidir.
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_DECISION_ENGINE_H
#define AQUAGUARD_DECISION_ENGINE_H

#include <Arduino.h>
#include <math.h>
#include "config.h"
#include "sensors.h"

// ============================================================================
// TIPLER
// ============================================================================

enum TikanmaTuru {
  TUR_YOK,
  TUR_KIMYASAL,
  TUR_BIYOLOJIK,
  TUR_FIZIKSEL
};

enum TeshisDurumu {
  DURUM_NORMAL,
  DURUM_BELIRSIZ,
  DURUM_TESPIT_EDILDI
};

struct TeshisSonucu {
  TeshisDurumu durum;
  TikanmaTuru tur;
  float guven;              // 0-100 (%)
  bool debiDususVar;
  bool basincArtisVar;
  bool turbiditeYuksekVar;
};

// ============================================================================
// YARDIMCI: ENUM -> METIN (loglama / MQTT icin)
// ============================================================================

const char* turAdiGetir(TikanmaTuru tur) {
  switch (tur) {
    case TUR_KIMYASAL:  return "kimyasal";
    case TUR_BIYOLOJIK: return "biyolojik";
    case TUR_FIZIKSEL:  return "fiziksel";
    default:            return "yok";
  }
}

const char* durumAdiGetir(TeshisDurumu durum) {
  switch (durum) {
    case DURUM_NORMAL:         return "normal";
    case DURUM_BELIRSIZ:       return "belirsiz";
    case DURUM_TESPIT_EDILDI:  return "tespit_edildi";
    default:                   return "bilinmiyor";
  }
}

// ============================================================================
// ASAMA A - TETIKLEYICI KONTROLU
// ============================================================================

void tetikleyicileriKontrolEt(const SensorOkumalari& okuma, TeshisSonucu& sonuc) {
  sonuc.debiDususVar = (REFERANS_DEBI - okuma.debi) >= DEBI_DUSUS_ESIGI;
  sonuc.basincArtisVar = okuma.deltaBasinc >= BASINC_ARTIS_ESIGI;
  sonuc.turbiditeYuksekVar = okuma.turbidite >= TURBIDITE_ESIGI;
}

// ============================================================================
// ASAMA B - TUR SKORLAMA (log-gauss olabilirlik + softmax)
// ============================================================================

static float _logGaussYogunlugu(float x, float ortalama, float std) {
  float z = (x - ortalama) / std;
  return -0.5f * z * z - logf(std * 2.5066283f);  // 2.5066... = sqrt(2*pi)
}

// guvenler[0]=kimyasal, guvenler[1]=biyolojik, guvenler[2]=fiziksel (0-100 arasi, toplami 100)
void turGuvenSkorlariniHesapla(const SensorOkumalari& okuma, float guvenler[3]) {
  float logSkor[3];

  logSkor[0] = _logGaussYogunlugu(okuma.ph, IMZA_KIMYASAL_PH_ORT, IMZA_KIMYASAL_PH_STD)
             + _logGaussYogunlugu(okuma.ec, IMZA_KIMYASAL_EC_ORT, IMZA_KIMYASAL_EC_STD)
             + _logGaussYogunlugu(okuma.orp, IMZA_KIMYASAL_ORP_ORT, IMZA_KIMYASAL_ORP_STD);

  logSkor[1] = _logGaussYogunlugu(okuma.ph, IMZA_BIYOLOJIK_PH_ORT, IMZA_BIYOLOJIK_PH_STD)
             + _logGaussYogunlugu(okuma.ec, IMZA_BIYOLOJIK_EC_ORT, IMZA_BIYOLOJIK_EC_STD)
             + _logGaussYogunlugu(okuma.orp, IMZA_BIYOLOJIK_ORP_ORT, IMZA_BIYOLOJIK_ORP_STD);

  logSkor[2] = _logGaussYogunlugu(okuma.ph, IMZA_FIZIKSEL_PH_ORT, IMZA_FIZIKSEL_PH_STD)
             + _logGaussYogunlugu(okuma.ec, IMZA_FIZIKSEL_EC_ORT, IMZA_FIZIKSEL_EC_STD)
             + _logGaussYogunlugu(okuma.orp, IMZA_FIZIKSEL_ORP_ORT, IMZA_FIZIKSEL_ORP_STD);

  // Sayisal kararlilik icin softmax'tan once en buyugu cikar
  float enBuyuk = logSkor[0];
  if (logSkor[1] > enBuyuk) enBuyuk = logSkor[1];
  if (logSkor[2] > enBuyuk) enBuyuk = logSkor[2];

  float ustel[3];
  float toplamUstel = 0.0f;
  for (int i = 0; i < 3; i++) {
    ustel[i] = expf(logSkor[i] - enBuyuk);
    toplamUstel += ustel[i];
  }
  for (int i = 0; i < 3; i++) {
    guvenler[i] = 100.0f * ustel[i] / toplamUstel;
  }
}

// ============================================================================
// TAM KURAL TABANLI TESHIS (ASAMA A + ASAMA B)
// ============================================================================

TeshisSonucu kuralTabanliTeshis(const SensorOkumalari& okuma) {
  TeshisSonucu sonuc;
  tetikleyicileriKontrolEt(okuma, sonuc);

  bool tikanmaVar = sonuc.debiDususVar || sonuc.basincArtisVar || sonuc.turbiditeYuksekVar;

  if (!tikanmaVar) {
    sonuc.durum = DURUM_NORMAL;
    sonuc.tur = TUR_YOK;
    sonuc.guven = 100.0f;
    return sonuc;
  }

  float guvenler[3];
  turGuvenSkorlariniHesapla(okuma, guvenler);

  int enIyiIndeks = 0;
  for (int i = 1; i < 3; i++) {
    if (guvenler[i] > guvenler[enIyiIndeks]) enIyiIndeks = i;
  }

  TikanmaTuru turler[3] = {TUR_KIMYASAL, TUR_BIYOLOJIK, TUR_FIZIKSEL};
  sonuc.tur = turler[enIyiIndeks];
  sonuc.guven = guvenler[enIyiIndeks];
  sonuc.durum = (sonuc.guven >= GUVEN_ESIGI) ? DURUM_TESPIT_EDILDI : DURUM_BELIRSIZ;

  return sonuc;
}

#endif // AQUAGUARD_DECISION_ENGINE_H
