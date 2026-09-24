/*
 * AquaGuard - Ana Sulama Vanasi Kontrolu
 * ==========================================
 *
 * Amac:
 *   Zonun ana su hattini (butun sulamayi) tedavi/teshis akisindan TAMAMEN
 *   BAGIMSIZ olarak acip kapatir. treatment.h'deki tedavi aktuatorlerinden
 *   (asit/klor/yikama) farki: bu, operatorun sahada BASKA bir sebeple
 *   (sizinti supheci, bakim, komsu parselde is vb.) butun sulamayi
 *   durdurmak istemesi icin bir GUVENLIK anahtaridir -- karar motorunun
 *   tikanma teshisiyle hicbir ilgisi yoktur, MQTT operator komutuyla
 *   (bkz. mqtt_handler.h "sulama_durdur"/"sulama_baslat") tetiklenir.
 *
 *   SURELI SULAMA (2026-09-24, "ciftci evinden sulama baslatsin" ozelligi):
 *   "sulama_baslat" komutu artik opsiyonel bir "sure_dakika" alani
 *   tasiyabilir. Verilirse, vana o sure sonunda KENDILIGINDEN kapanir --
 *   zamanlayici KARTTA (millis() ile, non-blocking) calisir, TELEFONDA
 *   DEGIL: uygulama kapansa/baglanti kesilse bile su bosa akmaya devam
 *   etmez. Suresiz (eski davranis, sure_dakika verilmemis) acma/kapama
 *   AYNEN calismaya devam eder -- geriye donuk uyumlu.
 *
 * Tarih:  2026-09-03 (sureli sulama: 2026-09-24)
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_ANA_VANA_H
#define AQUAGUARD_ANA_VANA_H

#include <Arduino.h>
#include "config.h"

static bool _anaVanaAcik = true;   // varsayilan: sulama normal calisir
// 0 = zamanlayici YOK (suresiz acik/kapali). >0 ise, bu millis() degerine
// ulasildiginda vana OTOMATIK kapanir.
static unsigned long _sulamaKapanmaZamaniMs = 0;

void anaVanaBaslat() {
  pinMode(PIN_ANA_VANA, OUTPUT);
  digitalWrite(PIN_ANA_VANA, HIGH);   // HIGH = vana acik (role tipine gore ters olabilir)
  _anaVanaAcik = true;
  _sulamaKapanmaZamaniMs = 0;
}

void anaVanayiKapat() {
  digitalWrite(PIN_ANA_VANA, LOW);
  _anaVanaAcik = false;
  _sulamaKapanmaZamaniMs = 0;   // kapatildiktan sonra kapanacak bir sey kalmadi
}

// Suresiz ac (eski davranis) -- devam eden bir zamanlayici varsa IPTAL eder
// (operatorun manuel "ac" komutu, otomatik zamanlayicidan ONCELIKLIDIR).
void anaVanayiAc() {
  digitalWrite(PIN_ANA_VANA, HIGH);
  _anaVanaAcik = true;
  _sulamaKapanmaZamaniMs = 0;
}

// Belirtilen dakika sonunda KENDILIGINDEN kapanacak sekilde ac.
// dakika <= 0 verilirse suresiz ac (anaVanayiAc ile ayni).
void anaVanayiSureliAc(long dakika) {
  if (dakika <= 0) {
    anaVanayiAc();
    return;
  }
  // Guvenlik: makul olmayan/asiri uzun bir sure girilirse (yanlislikla ya
  // da kotu niyetle) config.h'deki ust sinira kirpilir -- su israfina ve
  // sinirsiz suren bir tedavi riskine karsi.
  if (dakika > SULAMA_MAKS_SURE_DK) {
    dakika = SULAMA_MAKS_SURE_DK;
  }
  digitalWrite(PIN_ANA_VANA, HIGH);
  _anaVanaAcik = true;
  _sulamaKapanmaZamaniMs = millis() + (unsigned long)dakika * 60000UL;
}

bool anaVanaAcikMi() {
  return _anaVanaAcik;
}

// Kalan sureyi SANIYE olarak dondurur (zamanlayici yoksa 0). Telemetride
// (mqtt_handler.h -> "sulama_kalan_saniye") uygulamanin geri sayim
// gostermesi icin kullanilir.
unsigned long anaVanaKalanSaniyeGetir() {
  if (_sulamaKapanmaZamaniMs == 0 || !_anaVanaAcik) return 0;
  unsigned long simdi = millis();
  if (simdi >= _sulamaKapanmaZamaniMs) return 0;
  return (_sulamaKapanmaZamaniMs - simdi) / 1000UL;
}

// Ana dongude HER TURDA cagrilmali -- suresi dolan bir sulama varsa kapatir.
// Non-blocking: delay() kullanmaz, millis() karsilastirmasi yapar (bkz.
// treatment.h ayni desen).
void anaVanaZamanlayiciyiGuncelle() {
  if (_sulamaKapanmaZamaniMs != 0 && _anaVanaAcik &&
      millis() >= _sulamaKapanmaZamaniMs) {
    anaVanayiKapat();
    Serial.println(F("[SULAMA] Sureli sulama tamamlandi, vana otomatik kapatildi."));
  }
}

#endif // AQUAGUARD_ANA_VANA_H
