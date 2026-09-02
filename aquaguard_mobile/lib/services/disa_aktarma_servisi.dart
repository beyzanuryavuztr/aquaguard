/// AquaGuard - Rapor / CSV Disa Aktarma Servisi
/// ================================================
///
/// Amac:
///   Sensor gecmisini, sahadaki agronomist/muhendisin kendi Excel/Google
///   Sheets analizinde kullanabilmesi icin standart CSV formatinda disa
///   aktarir. CSV metnini uretmek TAMAMEN platform bagimsizdir (bu dosya);
///   diski nereye/nasil yazacagini (Web'de tarayici indirmesi, mobil/masaustu
///   dosya sistemi) `disa_aktarma_factory.dart` kosullu ithalati cozer --
///   ayni desen mqtt_istemci_factory.dart'ta zaten kullaniliyor.
///
///   UTF-8 BOM ile basliyoruz: Excel (ozellikle Windows'ta), BOM olmadan
///   UTF-8 CSV'lerdeki Turkce karakterleri (ş, ğ, ı, ö, ü, ç) bozuk gosterir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:intl/intl.dart';

import '../models/sensor_okuma.dart';

class DisaAktarmaServisi {
  DisaAktarmaServisi._();

  /// Excel (özellikle Windows'ta), BOM olmadan UTF-8 CSV'lerdeki Türkçe
  /// karakterleri (ş, ğ, ı, ö, ü, ç) bozuk gösterir -- platforma özgü
  /// kaydetme kodları (disa_aktarma_io/web.dart) dosya içeriğinin başına
  /// bunu eklemelidir.
  static const String utf8Bom = '\uFEFF';

  static final DateFormat _zamanBicimi = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Bir alanı CSV icin guvenli hale getirir: virgul, tirnak veya satir
  /// sonu iceriyorsa cift tirnak icine alir (RFC 4180).
  static String _alan(Object deger) {
    final metin = deger.toString();
    if (metin.contains(',') || metin.contains('"') || metin.contains('\n')) {
      return '"${metin.replaceAll('"', '""')}"';
    }
    return metin;
  }

  static const List<String> _basliklar = [
    'Zaman',
    'Zon',
    'pH',
    'EC (mS/cm)',
    'ORP (mV)',
    'Türbidite (NTU)',
    'Debi (LPM)',
    'Diferansiyel Basınç (bar)',
    'Durum',
    'Tıkanma Türü',
    'Güven (%)',
    'Aktif Tedavi',
    'Durulama Aktif',
  ];

  static List<String> _satir(SensorOkuma o) => [
    _alan(_zamanBicimi.format(o.zaman)),
    _alan(o.zone),
    _alan(o.ph.toStringAsFixed(2)),
    _alan(o.ec.toStringAsFixed(2)),
    _alan(o.orp.toStringAsFixed(0)),
    _alan(o.turbidite.toStringAsFixed(1)),
    _alan(o.debi.toStringAsFixed(2)),
    _alan(o.deltaBasinc.toStringAsFixed(3)),
    _alan(durumEtiketi(o.durum)),
    _alan(turEtiketi(o.tikanmaTuru)),
    _alan(o.guven.toStringAsFixed(1)),
    _alan(tedaviEtiketi(o.tedaviAktif)),
    _alan(o.durulamaAktif ? 'Evet' : 'Hayır'),
  ];

  /// [gecmis] herhangi bir sirada olabilir -- disa aktarilan CSV, okunurlugu
  /// icin her zaman KRONOLOJIK (eskiden yeniye) sirali yazilir.
  static String csvOlustur(List<SensorOkuma> gecmis) {
    final kronolojik = [...gecmis]..sort((a, b) => a.zaman.compareTo(b.zaman));
    final buffer = StringBuffer()..writeln(_basliklar.map(_alan).join(','));
    for (final okuma in kronolojik) {
      buffer.writeln(_satir(okuma).join(','));
    }
    return buffer.toString();
  }

  static String dosyaAdiUret(String etiket) {
    final zamanDamgasi = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final guvenliEtiket = etiket
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    return 'aquaguard_${guvenliEtiket}_$zamanDamgasi.csv';
  }
}
