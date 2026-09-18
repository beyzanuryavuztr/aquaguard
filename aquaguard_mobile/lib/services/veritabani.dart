/// AquaGuard - SQLite Veritabani (drift) - Mimari Bolunme Faz 13
/// ===================================================================
///
/// Amac:
///   SharedPreferences'in (JSON-blob + 200 kayit sinirlamasi olan) yerini,
///   SURELI BUYUYEN 4 koleksiyon icin alir: sensor okuma gecmisi (zon
///   basina), aktivite gecmisi, bildirim gecmisi, tarla notlari. Her
///   tablo, satir basina TEK bir JSON blob (`jsonVeri`) tutar -- mevcut
///   model siniflarinin (`SensorOkuma`, `AktiviteKaydi`, `TarlaNotu`)
///   toJson()/fromJson() serilestiricileri BIREBIR yeniden kullanilir;
///   her alani ayri bir SQL kolonuna eslemek (normalize etmek) bu
///   asamada GEREKSIZ karmasiklik olurdu -- sorgular hep "zona/zamana
///   gore filtrele" seviyesinde kaliyor, alan bazinda SQL sorgusu
///   YOK. `zamanMillis` (ve zon/tarla ID'si) AYRI, INDEKSLI birer
///   sutun -- sirali okuma/filtreleme bunlar UZERINDEN yapilir.
///
///   BILEREK SQLite'A TASINMAYAN veriler (bkz. DepolamaServisi, Faz 12b
///   Repository'leri HALA SharedPreferences kullanir): tarlalar, MQTT
///   ayarlari, tema/dil/profil tercihleri, bakim gorevleri -- bunlarin
///   HICBIRI "sinirsiz buyuyen" bir liste degil (bakim gorevleri sabit
///   ~4 kayit, digerleri tekil deger); SQLite'a tasimak gercek bir
///   ihtiyaca degil, asiri mühendislige hizmet ederdi.
///
///   WEB DAHIL TUM PLATFORMLARDA gercek SQLite kullanilir (drift_flutter
///   + sqlite3.wasm/drift_worker.dart.js, bkz. web/ klasoru) -- kullanici
///   TERCIHEN web'de de mobil ile AYNI depolama motorunu istedi (bkz.
///   proje karari, 2026-09-17).
///
/// Tarih:  2026-09-17
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'veritabani.g.dart';

/// Zon basina biriken sensor okuma gecmisi (bkz. models/sensor_okuma.dart).
class SensorOkumalari extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get zone => integer()();
  IntColumn get zamanMillis => integer()();
  TextColumn get jsonVeri => text()();
}

/// Zon basina SON BILINEN okuma (cevrimdisi mod icin) -- BILEREK
/// [SensorOkumalari]'nden AYRI bir tablo: cagiran taraf
/// (CihazIletisimProvider) her yeni veride HEM gecmise ekler HEM son
/// okumayi ayrica yazar (2 farkli cagri) -- ayni tabloda olsalardi ayni
/// okuma IKI KEZ satir olarak eklenir, gecmis/istatistikler bozulurdu.
/// Zon basina TEK satir (upsert, `INSERT OR REPLACE`).
class SonOkumalar extends Table {
  IntColumn get zone => integer()();
  TextColumn get jsonVeri => text()();

  @override
  Set<Column> get primaryKey => {zone};
}

/// Tum zonlardaki onemli olaylarin kalici gecmisi (bkz. models/aktivite_kaydi.dart).
class AktiviteKayitlari extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get zamanMillis => integer()();
  TextColumn get jsonVeri => text()();
}

/// Aktivite gecmisinin, gercekten bir bildirime donusmus ALT KUMESI.
class BildirimGecmisi extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get zamanMillis => integer()();
  TextColumn get jsonVeri => text()();
}

/// Operatorun tarla basina serbest metin notlari (bkz. models/tarla_notu.dart).
class TarlaNotlari extends Table {
  TextColumn get id => text()();
  TextColumn get tarlaId => text()();
  IntColumn get zamanMillis => integer()();
  TextColumn get jsonVeri => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SensorOkumalari,
    SonOkumalar,
    AktiviteKayitlari,
    BildirimGecmisi,
    TarlaNotlari,
  ],
)
class AquaGuardVeritabani extends _$AquaGuardVeritabani {
  AquaGuardVeritabani([QueryExecutor? executor])
    : super(executor ?? (testBaglantiFabrikasi ?? _baglantiOlustur)());

  AquaGuardVeritabani.test(super.executor);

  @override
  int get schemaVersion => 1;

  // Su an schemaVersion HALA 1 -- semaya HENUZ hicbir sutun/tablo
  // eklenmedi, bu yuzden `onUpgrade` asagida bos/no-op. Iskelet BILEREK
  // simdiden eklendi: ileride bir sutun eklenirse (orn. E1 -- sensor
  // semasina sicaklik alani eklenmesi, kalibrasyon_sabitleri.dart'taki
  // sicaklik kompanzasyonu icin) `schemaVersion`'i artirip BURAYA
  // (m.addColumn(...) gibi) gercek bir ALTER TABLE adimi eklemek yeterli
  // olacak -- aksi halde kullanicinin CIHAZINDAKI mevcut veritabani
  // dosyasi, yeni sutunu BEKLEYEN yeni kod surumuyle UYUSMAZ ve
  // kullanici verisi kaybi riski dogar.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, eskiSurum, yeniSurum) async {
      // Henuz gercek bir migrasyon adimi YOK -- schemaVersion hala 1.
    },
  );

  /// SADECE testler icin: `driftDatabase()`'in gercek (native) yolu
  /// `path_provider` platform kanalini kullanir -- bu kanal duz
  /// `flutter test` host'unda MOCK'LANMADIGI icin `MissingPluginException`
  /// firlatir. `test/flutter_test_config.dart`, bu alani (dosya
  /// sistemine/path_provider'a hic ihtiyac duymayan) bellek-ici bir
  /// veritabani fabrikasiyla GLOBAL olarak override eder -- boylece 334
  /// mevcut test dosyasi (hepsi parametresiz `UygulamaDurumu()` kullanir)
  /// DEGISMEDEN calisir; her cagri KENDI izole bellek-ici veritabanini
  /// alir (dosya sistemi paylasimi/testler-arasi veri kirlenmesi OLMAZ).
  static QueryExecutor Function()? testBaglantiFabrikasi;

  static QueryExecutor _baglantiOlustur() {
    return driftDatabase(
      name: 'aquaguard_veritabani',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
