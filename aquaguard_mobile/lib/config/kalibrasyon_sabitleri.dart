/// AquaGuard - Sensor Kalibrasyon Sabitleri (Ayarlar'da salt-okunur gösterim)
/// ================================================================================
///
/// Amac:
///   firmware/config.h'deki YER TUTUCU kalibrasyon sabitlerinin (saha
///   kalibrasyonu henüz yapılmadı -- bkz. o dosyanın SS3 başlığı) Dart
///   tarafındaki birebir aynısı. Uygulama bu değerleri DEĞİŞTİREMEZ --
///   kalibrasyon Deneyap Kart üzerinde, gerçek tampon çözeltileriyle
///   (pH 4.01/6.86/9.18, EC 1.413/12.88 mS/cm, ORP 225/475 mV) yapılır.
///   Ayarlar ekranında SADECE bilgi amaçlı, salt-okunur gösterilir --
///   operatör "cihaz şu an hangi sabitlerle çalışıyor" sorusuna
///   uygulamadan bakabilsin diye.
///
/// TEK KAYNAK UYARISI: bu sabitler firmware/config.h SS3 ile BİREBİR AYNI
///   olmalıdır. Biri değişirse ikisi de güncellenmelidir.
///
/// Tarih:  2026-09-05
library;

class KalibrasyonSabitleri {
  KalibrasyonSabitleri._();

  static const double phOfset = 7.00;
  static const double phEgim = -5.556;
  static const double phNotrVoltaj = 2.50;

  static const double ecOfset = 0.10;
  static const double ecEgim = 1.05;

  static const double orpOfsetVoltaj = 1.50;
  static const double orpKazanc = 250.0;

  static const double turbiditeTemizVoltaj = 4.20;
  static const double turbiditeEgim = 40.0;
}
