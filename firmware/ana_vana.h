/*
 * AquaGuard - Zon Vanalari Kontrolu
 * ==========================================
 *
 * Amac:
 *   4 zonun (config.h TOPLAM_ZON_SAYISI) her birinin KENDI vanasini acip
 *   kapatir. Bu, treatment.h'deki tedavi aktuatorlerinden (asit/klor/yikama)
 *   FARKLI iki amaca hizmet eder:
 *     1) Operatorun MQTT komutuyla ("sulama_baslat"/"sulama_durdur") o
 *        zonun butun sulamasini durdurmasi (tedavi/teshisle ilgisi yok --
 *        sizinti supheci, bakim vb.).
 *     2) ZON IZOLASYONU: bir zona dozlama yapilirken (bkz. treatment.h),
 *        digerlerinin vanasi GECICI kapatilir -- dozlama pompalari ORTAK
 *        ana hatta enjekte ediyor, izole edilmezse ilac TUM zonlara gider.
 *
 *   2026-09-25 BUYUK DUZELTME: onceki tasarim TEK bir "ana vana" varsayiyordu
 *   (kartin kendi zonu icin) ve DIGER zonlarin vanasini MQTT uzerinden BASKA
 *   cihazlara komut yayinlayarak kontrol ediyordu. Enver'in notu ve kullanici
 *   onayiyla DOGRULANDI: gercekte TEK kart 4 vananin HEPSINI dogrudan
 *   yonetiyor (config.h PIN_VANA1..4) -- artik ag/MQTT GEREKMEZ, tum vana
 *   kontrolu YEREL fonksiyon cagrisidir (daha hizli, daha guvenilir, "ates
 *   et ve devam et" MQTT riski ortadan kalkar).
 *
 *   SURELI SULAMA (2026-09-24, "ciftci evinden sulama baslatsin" ozelligi):
 *   "sulama_baslat" komutu artik opsiyonel bir "sure_dakika" alani
 *   tasiyabilir. Verilirse, vana o sure sonunda KENDILIGINDEN kapanir --
 *   zamanlayici KARTTA (millis() ile, non-blocking) calisir, TELEFONDA
 *   DEGIL. Her zon KENDI zamanlayicisini bagimsiz tutar.
 *
 * Tarih:  2026-09-03 (sureli sulama: 2026-09-24, 4-vana mimarisi: 2026-09-25)
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_ANA_VANA_H
#define AQUAGUARD_ANA_VANA_H

#include <Arduino.h>
#include "config.h"

// 1-indeksli diziler (dizin 0 kullanilmaz) -- zon numaralari 1..TOPLAM_ZON_SAYISI.
static bool _vanaAcik[TOPLAM_ZON_SAYISI + 1];
static unsigned long _vanaKapanmaZamaniMs[TOPLAM_ZON_SAYISI + 1];

// Zon numarasindan fiziksel pine cevirir -- config.h PIN_VANA1..4 ile BIREBIR
// eslesir. Gecersiz zon numarasi (kod hatasi) icin -1 doner.
static int _vanaPiniGetir(int zon) {
  switch (zon) {
    case 1: return PIN_VANA1;
    case 2: return PIN_VANA2;
    case 3: return PIN_VANA3;
    case 4: return PIN_VANA4;
    default: return -1;
  }
}

void anaVanaBaslat() {
  for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
    int pin = _vanaPiniGetir(zon);
    if (pin < 0) continue;
    pinMode(pin, OUTPUT);
    digitalWrite(pin, HIGH);   // HIGH = vana acik (role tipine gore ters olabilir)
    _vanaAcik[zon] = true;
    _vanaKapanmaZamaniMs[zon] = 0;
  }
}

void anaVanayiKapat(int zon) {
  int pin = _vanaPiniGetir(zon);
  if (pin < 0) return;
  digitalWrite(pin, LOW);
  _vanaAcik[zon] = false;
  _vanaKapanmaZamaniMs[zon] = 0;   // kapatildiktan sonra kapanacak bir sey kalmadi
}

// Suresiz ac (eski davranis) -- devam eden bir zamanlayici varsa IPTAL eder
// (operatorun manuel "ac" komutu, otomatik zamanlayicidan ONCELIKLIDIR).
void anaVanayiAc(int zon) {
  int pin = _vanaPiniGetir(zon);
  if (pin < 0) return;
  digitalWrite(pin, HIGH);
  _vanaAcik[zon] = true;
  _vanaKapanmaZamaniMs[zon] = 0;
}

// Belirtilen dakika sonunda KENDILIGINDEN kapanacak sekilde ac.
// dakika <= 0 verilirse suresiz ac (anaVanayiAc ile ayni).
void anaVanayiSureliAc(int zon, long dakika) {
  if (dakika <= 0) {
    anaVanayiAc(zon);
    return;
  }
  int pin = _vanaPiniGetir(zon);
  if (pin < 0) return;
  // Guvenlik: makul olmayan/asiri uzun bir sure girilirse (yanlislikla ya
  // da kotu niyetle) config.h'deki ust sinira kirpilir -- su israfina ve
  // sinirsiz suren bir tedavi riskine karsi.
  if (dakika > SULAMA_MAKS_SURE_DK) {
    dakika = SULAMA_MAKS_SURE_DK;
  }
  digitalWrite(pin, HIGH);
  _vanaAcik[zon] = true;
  _vanaKapanmaZamaniMs[zon] = millis() + (unsigned long)dakika * 60000UL;
}

bool anaVanaAcikMi(int zon) {
  if (zon < 1 || zon > TOPLAM_ZON_SAYISI) return false;
  return _vanaAcik[zon];
}

// Kalan sureyi SANIYE olarak dondurur (zamanlayici yoksa 0). Telemetride
// (mqtt_handler.h -> "sulama_kalan_saniye") uygulamanin geri sayim
// gostermesi icin kullanilir.
unsigned long anaVanaKalanSaniyeGetir(int zon) {
  if (zon < 1 || zon > TOPLAM_ZON_SAYISI) return 0;
  if (_vanaKapanmaZamaniMs[zon] == 0 || !_vanaAcik[zon]) return 0;
  unsigned long simdi = millis();
  if (simdi >= _vanaKapanmaZamaniMs[zon]) return 0;
  return (_vanaKapanmaZamaniMs[zon] - simdi) / 1000UL;
}

// Ana dongude HER TURDA cagrilmali -- suresi dolan zon(lar) varsa kapatir.
// Non-blocking: delay() kullanmaz, millis() karsilastirmasi yapar.
void anaVanaZamanlayiciyiGuncelle() {
  unsigned long simdi = millis();
  for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
    if (_vanaKapanmaZamaniMs[zon] != 0 && _vanaAcik[zon] &&
        simdi >= _vanaKapanmaZamaniMs[zon]) {
      anaVanayiKapat(zon);
      Serial.print(F("[SULAMA] Zon "));
      Serial.print(zon);
      Serial.println(F(": sureli sulama tamamlandi, vana otomatik kapatildi."));
    }
  }
}

// ============================================================================
// ZON IZOLASYONU (bkz. treatment.h) -- artik YEREL, MQTT GEREKMEZ
// ============================================================================
// Bir zona dozlama baslarken DIGER TUM zonlarin vanasini gecici kapatir
// (veya tedavi/durulama tamamen bitince hepsini geri acar). haricTutulanZon
// dozlanan zonun kendisidir -- ONUN vanasina DOKUNULMAZ (kendi ayarini
// tedaviBaslatZonIzoleyerek zaten yonetiyor, bkz. treatment.h).
void digerZonlarinVanasiniAyarla(int haricTutulanZon, bool acik) {
  for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
    if (zon == haricTutulanZon) continue;
    if (acik) {
      anaVanayiAc(zon);
    } else {
      anaVanayiKapat(zon);
    }
  }
}

#endif // AQUAGUARD_ANA_VANA_H
