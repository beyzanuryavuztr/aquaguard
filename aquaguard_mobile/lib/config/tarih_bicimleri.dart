/// AquaGuard - Paylasilan Tarih/Saat Bicimleri
/// ===================================================
///
/// Amac:
///   KOD TEMIZLIGI (2026-09-06): projede 15 yerde, 7 farkli bicimle
///   tekrarlanan `DateFormat('...')` cagrilarini TEK bir yerde toplar --
///   yeni bir ekran eklerken "bu bicim daha once baska bir dosyada var miydi,
///   hangi string'di" sorusuna gerek birakmaz ve TUM ekranlarin ayni tarihi
///   ayni bicimde gostermesini garanti eder (ayni "tek kaynak" ilkesi,
///   config/sensor_imzalari.dart ve widgets/durum_renkleri.dart ile tutarli).
///
/// Tarih:  2026-09-06
library;

import 'package:intl/intl.dart';

class TarihBicimleri {
  TarihBicimleri._();

  /// Tam tarih+saat+saniye -- aktivite/tespit gunlukleri, PDF rapor
  /// tablolari, cevrimdisi/son guncelleme banner'lari. Ör: "05.09.2026 14:32:10"
  static final tamZamanli = DateFormat('dd.MM.yyyy HH:mm:ss');

  /// Tam tarih+saat, saniyesiz -- bakim takvimi sonraki tarih, tarla
  /// notlari, PDF rapor basligi. Ör: "05.09.2026 14:32"
  static final tamZamanliSaniyesiz = DateFormat('dd.MM.yyyy HH:mm');

  /// Sadece tarih -- bakim gorevi sonraki tarihi. Ör: "05.09.2026"
  static final sadeceTarih = DateFormat('dd.MM.yyyy');

  /// Kompakt tarih+saat+saniye (yil olmadan) -- genel bakis/gecmis loglar
  /// listelerinde yer tasarrufu icin. Ör: "05.09 14:32:10"
  static final kompaktZamanli = DateFormat('dd.MM HH:mm:ss');

  /// Kompakt tarih+saat, saniyesiz -- tedavi once/sonra karsilastirmasi.
  /// Ör: "05.09 14:32"
  static final kompaktZamanliSaniyesiz = DateFormat('dd.MM HH:mm');

  /// Sadece saat -- zon durum karti "son güncelleme" etiketi. Ör: "14:32:10"
  static final sadeceSaat = DateFormat('HH:mm:ss');

  /// Dosya adi icin guvenli zaman damgasi (bosluk/noktalama yok) -- CSV/PDF
  /// disa aktarma dosya adlari. Ör: "20260905_143210"
  static final dosyaAdi = DateFormat('yyyyMMdd_HHmmss');

  /// ISO-benzeri, CSV hucre degeri -- disa aktarilan tablolarda tam
  /// siralama/ayristirma kolayligi icin. Ör: "2026-09-05 14:32:10"
  static final isoBenzeri = DateFormat('yyyy-MM-dd HH:mm:ss');
}
