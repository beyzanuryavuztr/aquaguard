/*
 * AquaGuard - Tedavi Kontrol Katmani (GUVENLIK KRITIK)
 * =======================================================
 *
 * Amac:
 *   3 tedavi kanalini (asit dozlama, klor enjeksiyonu, yuksek basincli
 *   yikama) kontrol eder. Bu dosyanin en onemli gorevi GUVENLIKTIR:
 *
 *   1) MUTEX KILIDI: Asit ve klor pompalari ASLA AYNI ANDA calisamaz
 *      (birlikte tepkimeye girip toksik gaz -- klor gazi -- acigi cikarma
 *      riski vardir). Bu dosyada tum tedavi kanallari icin TEK BIR aktif
 *      tedavi kurali uygulanir: herhangi bir tedavi calisirken (veya
 *      durulama surerken) YENI BIR TEDAVI BASLATILAMAZ.
 *
 *   2) ZORUNLU DURULAMA: Her tedavi tamamlandiktan sonra, bir sonraki
 *      tedavi baslamadan once DURULAMA_SURESI_MS kadar zorunlu bekleme
 *      (durulama) uygulanir. Bu sure dolmadan mutex acilmaz.
 *
 *   3) NON-BLOCKING TASARIM: Hicbir fonksiyon delay() kullanmaz. Tum
 *      zamanlama millis() karsilastirmasiyla yapilir; bu sayede ana
 *      dongude sensor okuma / MQTT / loglama ES ZAMANLI devam edebilir.
 *
 *   4) ACIL DURDURMA: tedaviAcilDurdur() tum aktuatorleri aninda kapatir
 *      (ornegin sensor okumasi mantikdisi bir deger verirse cagirilabilir).
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_TREATMENT_H
#define AQUAGUARD_TREATMENT_H

#include <Arduino.h>
#include <Servo.h>
#include "config.h"
#include "decision_engine.h"

// ============================================================================
// TIPLER
// ============================================================================

enum TedaviTuru {
  TEDAVI_YOK,
  TEDAVI_ASIT,
  TEDAVI_KLOR,
  TEDAVI_YIKAMA
};

const char* tedaviAdiGetir(TedaviTuru tedavi) {
  switch (tedavi) {
    case TEDAVI_ASIT:    return "asit_dozlama";
    case TEDAVI_KLOR:    return "klor_enjeksiyon";
    case TEDAVI_YIKAMA:  return "yuksek_basincli_yikama";
    default:              return "yok";
  }
}

// Tikanma turunden uygun tedaviye esleme (brief SS3'teki tedavi tablosu)
TedaviTuru tedaviTuruBelirle(TikanmaTuru tur) {
  switch (tur) {
    case TUR_KIMYASAL:  return TEDAVI_ASIT;
    case TUR_BIYOLOJIK: return TEDAVI_KLOR;
    case TUR_FIZIKSEL:  return TEDAVI_YIKAMA;
    default:              return TEDAVI_YOK;
  }
}

// ============================================================================
// DAHILI DURUM MAKINESI (MUTEX'IN KENDISI BUDUR)
// ============================================================================

static TedaviTuru _aktifTedavi = TEDAVI_YOK;
static unsigned long _tedaviBaslangicMs = 0;
static bool _durulamaAktif = false;
static unsigned long _durulamaBaslangicMs = 0;

static Servo _yikamaServo;

// Bir tedavi turunun konfigurasyondaki suresini dondurur
static unsigned long _tedaviSuresiGetir(TedaviTuru tedavi) {
  switch (tedavi) {
    case TEDAVI_ASIT:    return TEDAVI_ASIT_SURESI_MS;
    case TEDAVI_KLOR:    return TEDAVI_KLOR_SURESI_MS;
    case TEDAVI_YIKAMA:  return TEDAVI_YIKAMA_SURESI_MS;
    default:              return 0;
  }
}

// Aktuatoru fiziksel olarak ac/kapat -- SADECE bu fonksiyon pinlere dokunur
static void _aktuatoruAyarla(TedaviTuru tedavi, bool acik) {
  switch (tedavi) {
    case TEDAVI_ASIT:
      digitalWrite(PIN_POMPA_ASIT, acik ? HIGH : LOW);
      break;
    case TEDAVI_KLOR:
      digitalWrite(PIN_POMPA_KLOR, acik ? HIGH : LOW);
      break;
    case TEDAVI_YIKAMA:
      _yikamaServo.write(acik ? 90 : 0);   // 0=kapali, 90=acik (mekanizmaya gore ayarlanmali)
      break;
    default:
      break;
  }
}

// ============================================================================
// KURULUM
// ============================================================================

void tedaviSistemBaslat() {
  pinMode(PIN_POMPA_ASIT, OUTPUT);
  pinMode(PIN_POMPA_KLOR, OUTPUT);
  digitalWrite(PIN_POMPA_ASIT, LOW);
  digitalWrite(PIN_POMPA_KLOR, LOW);

  _yikamaServo.attach(PIN_SERVO_YIKAMA);
  _yikamaServo.write(0);   // baslangicta valf kapali

  _aktifTedavi = TEDAVI_YOK;
  _durulamaAktif = false;
}

// ============================================================================
// TEDAVI BASLATMA -- MUTEX KONTROLU BURADA UYGULANIR
// ============================================================================

// Basariliysa true, mutex nedeniyle reddedildiyse false doner.
bool tedaviBaslat(TedaviTuru istenenTedavi) {
  if (istenenTedavi == TEDAVI_YOK) {
    return false;
  }

  // *** GUVENLIK KILIDI ***
  // Baska bir tedavi aktifken VEYA durulama surerken YENI TEDAVI BASLAMAZ.
  // Bu tek kural, asit ve klorun asla ayni anda calismamasini garanti eder.
  if (_aktifTedavi != TEDAVI_YOK || _durulamaAktif) {
    return false;
  }

  _aktifTedavi = istenenTedavi;
  _tedaviBaslangicMs = millis();
  _aktuatoruAyarla(istenenTedavi, true);

  return true;
}

// ============================================================================
// ACIL DURDURMA
// ============================================================================

void tedaviAcilDurdur() {
  _aktuatoruAyarla(TEDAVI_ASIT, false);
  _aktuatoruAyarla(TEDAVI_KLOR, false);
  _aktuatoruAyarla(TEDAVI_YIKAMA, false);
  _aktifTedavi = TEDAVI_YOK;
  _durulamaAktif = false;
}

// ============================================================================
// ANA DONGUDE HER TURDA CAGRILMASI GEREKEN GUNCELLEME FONKSIYONU
// (non-blocking durum makinesini ilerletir: tedavi -> durulama -> bosta)
// ============================================================================

void tedaviGuncelle() {
  unsigned long simdi = millis();

  // 1) Aktif bir tedavi varsa: suresi doldu mu kontrol et
  if (_aktifTedavi != TEDAVI_YOK) {
    unsigned long suresi = _tedaviSuresiGetir(_aktifTedavi);
    if (simdi - _tedaviBaslangicMs >= suresi) {
      _aktuatoruAyarla(_aktifTedavi, false);   // pompayi/valfi kapat
      _aktifTedavi = TEDAVI_YOK;
      _durulamaAktif = true;                    // zorunlu durulamaya gec
      _durulamaBaslangicMs = simdi;
    }
    return;
  }

  // 2) Durulama suruyorsa: suresi doldu mu kontrol et
  if (_durulamaAktif) {
    if (simdi - _durulamaBaslangicMs >= DURULAMA_SURESI_MS) {
      _durulamaAktif = false;   // mutex serbest kaldi, yeni tedavi baslatilabilir
    }
  }
}

// ============================================================================
// DURUM SORGULAMA (mqtt_handler.h / logger.h icin)
// ============================================================================

TedaviTuru aktifTedaviGetir() {
  return _aktifTedavi;
}

bool durulamaAktifMi() {
  return _durulamaAktif;
}

bool tedaviMesgulMu() {
  return (_aktifTedavi != TEDAVI_YOK) || _durulamaAktif;
}

// Bir tedavi turunun yapilandirilmis suresini disariya acar (loglama icin)
unsigned long tedaviSuresiGetir(TedaviTuru tedavi) {
  return _tedaviSuresiGetir(tedavi);
}

#endif // AQUAGUARD_TREATMENT_H
