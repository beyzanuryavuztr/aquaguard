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
 * Tarih:  2026-09-03
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_ANA_VANA_H
#define AQUAGUARD_ANA_VANA_H

#include <Arduino.h>
#include "config.h"

static bool _anaVanaAcik = true;   // varsayilan: sulama normal calisir

void anaVanaBaslat() {
  pinMode(PIN_ANA_VANA, OUTPUT);
  digitalWrite(PIN_ANA_VANA, HIGH);   // HIGH = vana acik (role tipine gore ters olabilir)
  _anaVanaAcik = true;
}

void anaVanayiKapat() {
  digitalWrite(PIN_ANA_VANA, LOW);
  _anaVanaAcik = false;
}

void anaVanayiAc() {
  digitalWrite(PIN_ANA_VANA, HIGH);
  _anaVanaAcik = true;
}

bool anaVanaAcikMi() {
  return _anaVanaAcik;
}

#endif // AQUAGUARD_ANA_VANA_H
