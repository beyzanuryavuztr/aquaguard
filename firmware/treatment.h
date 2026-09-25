/*
 * AquaGuard - Tedavi Kontrol Katmani (GUVENLIK KRITIK)
 * =======================================================
 *
 * Amac:
 *   5 tedavi kanalini (asit dozlama, klor enjeksiyonu, yuksek basincli
 *   yikama + Faz 3'te eklenen besin takviyesi sivi/toz -- bkz. asagida
 *   TedaviTuru) kontrol eder. Bu dosyanin en onemli gorevi GUVENLIKTIR:
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
// NOT: Klasik Arduino "Servo.h" kutuphanesi AVR (Uno/Mega) donanim
// zamanlayicilarina gore yazilmistir ve Deneyap Kart gibi ESP32 tabanli
// kartlarda GUVENILIR CALISMAZ/derlenmez. ESP32 icin dogru kutuphane
// "ESP32Servo" (Kutuphane Yoneticisi'nden kurulur, API'si ayni: attach()/
// write()) -- bu yuzden burada onu kullaniyoruz.
#include <ESP32Servo.h>
#include "config.h"
#include "decision_engine.h"

// ============================================================================
// TIPLER
// ============================================================================

enum TedaviTuru {
  TEDAVI_YOK,
  TEDAVI_ASIT,
  TEDAVI_KLOR,
  TEDAVI_YIKAMA,
  // Besin/takviye dozlama (Faz 3, 2026-09-25) -- tikanma teshisinden
  // BAGIMSIZ, SADECE operatorun manuel komutuyla baslar (bkz.
  // tedaviTuruBelirle() -- bu ikisini ASLA dondurmez, otonom tetiklenmezler).
  // Ayni GUVENLIK KILIDINE (mutex) tabidirler -- asit/klor/yikama ile ASLA
  // ayni anda calismazlar (hepsi ayni paylasimli ana hatta enjekte ediyor).
  TEDAVI_BESIN_SIVI,
  TEDAVI_BESIN_TOZ
};

const char* tedaviAdiGetir(TedaviTuru tedavi) {
  switch (tedavi) {
    case TEDAVI_ASIT:       return "asit_dozlama";
    case TEDAVI_KLOR:       return "klor_enjeksiyon";
    case TEDAVI_YIKAMA:     return "yuksek_basincli_yikama";
    case TEDAVI_BESIN_SIVI: return "besin_sivi";
    case TEDAVI_BESIN_TOZ:  return "besin_toz";
    default:                 return "yok";
  }
}

// Tikanma turunden uygun tedaviye esleme (brief SS3'teki tedavi tablosu).
// BILEREK SADECE 3 klasik tedaviyi dondurur -- besin/takviye dozlama
// tikanma teshisiyle TETIKLENMEZ, sadece operator elle baslatabilir
// (bkz. mqtt_handler.h "besin_dozlama_baslat").
TedaviTuru tedaviTuruBelirle(TikanmaTuru tur) {
  switch (tur) {
    case TUR_KIMYASAL:  return TEDAVI_ASIT;
    case TUR_BIYOLOJIK: return TEDAVI_KLOR;
    case TUR_FIZIKSEL:  return TEDAVI_YIKAMA;
    default:              return TEDAVI_YOK;
  }
}

// tedaviAdiGetir()'in TERSI -- MQTT komut mesajindaki "tedavi_turu" JSON
// alanini (operatorun manuel sectigi tedavi) TedaviTuru'ye cevirir.
// bkz. mqtt_handler.h _komutMesajGeldiginde()
TedaviTuru tedaviTuruAyristir(const char* ad) {
  if (strcmp(ad, "asit_dozlama") == 0)              return TEDAVI_ASIT;
  if (strcmp(ad, "klor_enjeksiyon") == 0)           return TEDAVI_KLOR;
  if (strcmp(ad, "yuksek_basincli_yikama") == 0)    return TEDAVI_YIKAMA;
  if (strcmp(ad, "besin_sivi") == 0)                return TEDAVI_BESIN_SIVI;
  if (strcmp(ad, "besin_toz") == 0)                 return TEDAVI_BESIN_TOZ;
  return TEDAVI_YOK;
}

// ============================================================================
// DAHILI DURUM MAKINESI (MUTEX'IN KENDISI BUDUR)
// ============================================================================

static TedaviTuru _aktifTedavi = TEDAVI_YOK;
// HANGI zon icin tedavi/durulama surdugu (2026-09-25, tek-kart/4-zon
// mimarisi) -- mutex hala GLOBAL (ayni anda sadece 1 zon tedavi gorebilir,
// dozlama ORTAK ana hatta enjekte ediyor), ama vana izolasyonu (ana_vana.h
// digerZonlarinVanasiniAyarla) HANGI zonun HARIC TUTULACAGINI bilmeli.
// Tedavi/durulama YOKKEN anlamsizdir (0).
static int _tedaviZonu = 0;
static unsigned long _tedaviBaslangicMs = 0;
static bool _durulamaAktif = false;
static unsigned long _durulamaBaslangicMs = 0;

static Servo _yikamaServo;

// TEDAVI_BESIN_TOZ icin iki fazli akisin HANGI fazda oldugunu tutar --
// karistirma fazinda false, pompalama fazina geciste true'ya doner (bkz.
// tedaviGuncelle() ici faz gecis kontrolu). Diger tum tedaviler tek fazli
// oldugu icin bu degiskeni kullanmaz.
static bool _tozPompalamaFazindaMi = false;

// Bir tedavi turunun konfigurasyondaki suresini dondurur
static unsigned long _tedaviSuresiGetir(TedaviTuru tedavi) {
  switch (tedavi) {
    case TEDAVI_ASIT:       return TEDAVI_ASIT_SURESI_MS;
    case TEDAVI_KLOR:       return TEDAVI_KLOR_SURESI_MS;
    case TEDAVI_YIKAMA:     return TEDAVI_YIKAMA_SURESI_MS;
    case TEDAVI_BESIN_SIVI: return TEDAVI_BESIN_SIVI_SURESI_MS;
    case TEDAVI_BESIN_TOZ:  return TEDAVI_BESIN_TOZ_SURESI_MS;
    default:                 return 0;
  }
}

// Aktuatoru fiziksel olarak ac/kapat -- SADECE bu fonksiyon pinlere dokunur.
// TEDAVI_BESIN_TOZ ISTISNADIR: iki fazli (once karistir, sonra pompala) --
// acik=true SADECE karistiriciyi baslatir (pompa fazina gecis
// tedaviGuncelle() icinde, bkz. asagida). acik=false (bitis/acil durdurma)
// HER IKI aktuatoru de guvenlik icin kapatir, hangi fazda olursa olsun.
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
    case TEDAVI_BESIN_SIVI:
      digitalWrite(PIN_POMPA_BESIN_SIVI, acik ? HIGH : LOW);
      break;
    case TEDAVI_BESIN_TOZ:
      // GUVENLIK (2026-09-25): PIN_KARISTIRICI_TOZ/PIN_POMPA_BESIN_TOZ, pin
      // yetersizligi nedeniyle config.h'de PIN_SERVO_YIKAMA ile AYNI pine
      // (D3) atanmis durumda (bkz. config.h #warning) -- bu aktuatoru
      // GERCEKTEN tetiklemek yikama valfini de tetikler/bozar. Bu fonksiyon
      // BILEREK HICBIR PINE DOKUNMAZ; tedaviBaslat() zaten bu turu en
      // basta REDDEDER (bkz. asagisi), buraya normal akista hic girilmez --
      // bu sadece savunma amacli ikinci bir guvenlik katmani.
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

  // ESP32Servo icin onerilen kurulum: standart 50Hz servo darbe frekansi.
  _yikamaServo.setPeriodHertz(50);
  _yikamaServo.attach(PIN_SERVO_YIKAMA, 500, 2400);
  _yikamaServo.write(0);   // baslangicta valf kapali

  // Besin/takviye dozlama (Faz 3, sivi) -- bkz. config.h PIN_POMPA_BESIN_SIVI.
  pinMode(PIN_POMPA_BESIN_SIVI, OUTPUT);
  digitalWrite(PIN_POMPA_BESIN_SIVI, LOW);

  // NOT (2026-09-25): PIN_KARISTIRICI_TOZ/PIN_POMPA_BESIN_TOZ icin BILEREK
  // pinMode() cagrilmiyor -- bu pinler su an PIN_SERVO_YIKAMA (D3) ile
  // CAKISIYOR (bkz. config.h #warning, _aktuatoruAyarla yorumu). Enver pin
  // atamasini netlestirdiginde buraya geri eklenmeli.

  _aktifTedavi = TEDAVI_YOK;
  _tedaviZonu = 0;
  _durulamaAktif = false;
}

// ============================================================================
// TEDAVI BASLATMA -- MUTEX KONTROLU BURADA UYGULANIR
// ============================================================================

// zon: bu tedavinin HANGI zon icin baslatildigi (1..TOPLAM_ZON_SAYISI) --
// ana_vana.h digerZonlarinVanasiniAyarla() bu zonu HARIC TUTAR (bkz.
// mqtt_handler.h tedaviBaslatZonIzoleyerek).
// Basariliysa true, mutex nedeniyle reddedildiyse false doner.
bool tedaviBaslat(TedaviTuru istenenTedavi, int zon) {
  if (istenenTedavi == TEDAVI_YOK) {
    return false;
  }

  // GUVENLIK (2026-09-25): toz dozlama pinleri su an yikama valfiyle
  // CAKISIYOR (bkz. config.h #warning) -- Enver dogrulayana kadar KESINLIKLE
  // reddedilir, TAHMINLE tetiklenmez.
  if (istenenTedavi == TEDAVI_BESIN_TOZ) {
    Serial.println(F("[TEDAVI] REDDEDILDI: toz dozlama pinleri henuz dogrulanmadi (config.h PIN_KARISTIRICI_TOZ/PIN_POMPA_BESIN_TOZ)."));
    return false;
  }

  // *** GUVENLIK KILIDI ***
  // Baska bir tedavi aktifken VEYA durulama surerken YENI TEDAVI BASLAMAZ.
  // Bu tek kural, asit ve klorun asla ayni anda calismamasini garanti eder.
  if (_aktifTedavi != TEDAVI_YOK || _durulamaAktif) {
    return false;
  }

  _aktifTedavi = istenenTedavi;
  _tedaviZonu = zon;
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
  _aktuatoruAyarla(TEDAVI_BESIN_SIVI, false);
  _aktifTedavi = TEDAVI_YOK;
  _tedaviZonu = 0;
  _durulamaAktif = false;
}

// ============================================================================
// OPERATOR MUDAHALESI (MQTT komutuyla tetiklenir -- bkz. mqtt_handler.h)
// ============================================================================
//
// tedaviAcilDurdur()'den FARKLI: bu, GUVENLIKLI bir erken sonlandirmadir --
// aktuatoru kapatir ama zorunlu durulama adimina GECER (mutex hemen acilmaz).
// tedaviAcilDurdur() ise gercek bir arizada mutex'i de aninda sifirlayan
// tam bir "sifirlama"dir. Sahadaki bir operatorun normal kullanim senaryosu
// icin dogru fonksiyon budur.
bool tedaviErkenDurdur() {
  if (_aktifTedavi == TEDAVI_YOK) {
    return false;   // durdurulacak aktif bir tedavi yok
  }
  _aktuatoruAyarla(_aktifTedavi, false);
  _aktifTedavi = TEDAVI_YOK;
  _durulamaAktif = true;
  _durulamaBaslangicMs = millis();
  return true;
}

// ============================================================================
// ANA DONGUDE HER TURDA CAGRILMASI GEREKEN GUNCELLEME FONKSIYONU
// (non-blocking durum makinesini ilerletir: tedavi -> durulama -> bosta)
// ============================================================================

// Donus degeri: bu cagrida durulama TAM OLARAK bitip mutex'in serbest
// kaldigi an ise true (SADECE o tek turda) -- cagiran taraf (aquaguard_main.ino)
// bunu, dozlama icin gecici kapatilmis DIGER zon vanalarini yeniden acmak
// icin kullanir (bkz. mqtt_handler.h "digerZonlarinVanasiniAyarla").
bool tedaviGuncelle() {
  unsigned long simdi = millis();

  // 1) Aktif bir tedavi varsa: suresi doldu mu kontrol et
  if (_aktifTedavi != TEDAVI_YOK) {
    // TEDAVI_BESIN_TOZ ISTISNASI: karistirma fazi bitince (pompalama fazina
    // henuz gecilmediyse) karistiriciyi kapat, pompayi baslat -- tedavinin
    // KENDISI bitmedi, sadece ic fazi degisti (bkz. _aktuatoruAyarla dosya
    // ici "iki fazli" notu).
    if (_aktifTedavi == TEDAVI_BESIN_TOZ && !_tozPompalamaFazindaMi &&
        simdi - _tedaviBaslangicMs >= BESIN_TOZ_KARISTIRMA_SURESI_MS) {
      _tozPompalamaFazindaMi = true;
      digitalWrite(PIN_KARISTIRICI_TOZ, LOW);
      digitalWrite(PIN_POMPA_BESIN_TOZ, HIGH);
    }

    unsigned long suresi = _tedaviSuresiGetir(_aktifTedavi);
    if (simdi - _tedaviBaslangicMs >= suresi) {
      _aktuatoruAyarla(_aktifTedavi, false);   // pompayi/valfi/karistiriciyi kapat
      _aktifTedavi = TEDAVI_YOK;
      _durulamaAktif = true;                    // zorunlu durulamaya gec
      _durulamaBaslangicMs = simdi;
    }
    return false;
  }

  // 2) Durulama suruyorsa: suresi doldu mu kontrol et
  if (_durulamaAktif) {
    if (simdi - _durulamaBaslangicMs >= DURULAMA_SURESI_MS) {
      _durulamaAktif = false;   // mutex serbest kaldi, yeni tedavi baslatilabilir
      _tedaviZonu = 0;          // izolasyon artik gerekmiyor (bkz. tedaviZonuGetir)
      return true;
    }
  }
  return false;
}

// ============================================================================
// DURUM SORGULAMA (mqtt_handler.h / logger.h icin)
// ============================================================================

TedaviTuru aktifTedaviGetir() {
  return _aktifTedavi;
}

// Aktif tedavi/durulamanin HANGI zon icin surdugunu dondurur (tedavi/
// durulama yoksa 0). bkz. ana_vana.h digerZonlarinVanasiniAyarla.
int tedaviZonuGetir() {
  return _tedaviZonu;
}

bool durulamaAktifMi() {
  return _durulamaAktif;
}

bool tedaviMesgulMu() {
  return (_aktifTedavi != TEDAVI_YOK) || _durulamaAktif;
}

// ============================================================================
// DURULAMA ZAMANLAYICISI SIFIRLAMA (ana vana ile etkilesim -- bkz. cagri
// yerleri: mqtt_handler.h "sulama_durdur"/"sulama_baslat", aquaguard_main.ino
// vana-kapali guvenlik yedegi)
// ============================================================================
//
// ACIMASIZ DENETIM DUZELTMESI (2026-09-14): daha once ana vana durulama
// SURERKEN kapatildiginda tedaviAcilDurdur() cagriliyordu -- bu fonksiyon
// _durulamaAktif'i de KOSULSUZ false yapar, yani mutex ANINDA acilirdi.
// Sonuc: operator vanayi kapatip aninda yeniden acarsa (veya baska bir
// nedenle kisa sureli kapanirsa), YARIM KALMIS bir durulama "tamamlandi"
// sayilip hat GERCEKTEN yikanmadan yeni bir tedaviye izin verilirdi --
// dosyanin kendi basindaki "Bu sure dolmadan mutex acilmaz" guvencesini
// (bkz. yukarida madde 2) bozan gercek bir guvenlik acigi.
//
// Fix: vana kapaliyken SADECE gercekten CALISAN bir pompa varsa
// tedaviAcilDurdur() cagrilir (mutex sifirlanir -- bu gercek bir ariza/
// beklenmeyen durumdur). SADECE durulama suruyorsa (pompa zaten kapali),
// mutex ACIK birakilir ve bunun yerine bu fonksiyon cagrilarak durulama
// zamanlayicisi "simdi"ye sifirlanir -- boylece:
//   (a) vana kapaliyken CAGRILIRSA (periyodik, OKUMA_ARALIGI_MS=5sn'de bir --
//       bkz. aquaguard_main.ino): sure hep "simdi"den sayildigi icin
//       DURULAMA_SURESI_MS (45sn)'ye HICBIR ZAMAN ulasamaz, yani akissiz
//       gecen sure durulama sayilmaz (5sn << 45sn, guvenli marj);
//   (b) vana YENIDEN ACILDIGINDA (sulama_baslat, bir kez) cagrilirsa:
//       durulama suresi flow GERCEKTEN geri geldigi andan itibaren
//       SIFIRDAN baslar -- yarim kalmis ilerlemeye guvenilmez, en guvenli
//       yaklasim TAM sureyi yeniden saymaktir.
// _durulamaAktif false ise (durulama zaten yok/bitmis) hicbir etkisi yoktur.
void durulamaZamanlayicisiniSifirla() {
  if (_durulamaAktif) {
    _durulamaBaslangicMs = millis();
  }
}

// Bir tedavi turunun yapilandirilmis suresini disariya acar (loglama icin)
unsigned long tedaviSuresiGetir(TedaviTuru tedavi) {
  return _tedaviSuresiGetir(tedavi);
}

#endif // AQUAGUARD_TREATMENT_H
