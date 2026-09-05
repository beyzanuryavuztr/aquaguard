/// AquaGuard - Demo Hızı (Simülasyon Zamanlayıcı Aralığı)
/// =============================================================
///
/// Amac:
///   Demo Modu'nun veri üretim aralığını jüri sunumuna göre ayarlanabilir
///   kılar. Önceki sabit 3 saniyelik aralık gerçekçi bir saha temposu için
///   uygundu, ama canlı bir jüri sunumunda bir tıkanma/tedavi döngüsünün
///   tamamlanmasını beklemek için ÇOK YAVAŞTI. Varsayılan artık "Normal"
///   (1.5s); "Turbo" sadece Demo Senaryo Paneli'nden erişilir ve SADECE
///   demo/sunum amaçlıdır -- gerçek donanımda bu kavramın karşılığı yoktur
///   (cihaz kendi örnekleme hızında veri yollar).
///
/// Tarih:  2026-09-05
library;

enum DemoHizi { yavas, normal, hizli, turbo }

extension DemoHiziX on DemoHizi {
  Duration get sure => switch (this) {
    DemoHizi.yavas => const Duration(seconds: 3),
    DemoHizi.normal => const Duration(milliseconds: 1500),
    DemoHizi.hizli => const Duration(milliseconds: 500),
    DemoHizi.turbo => const Duration(milliseconds: 200),
  };

  String get etiket => switch (this) {
    DemoHizi.yavas => 'Yavaş',
    DemoHizi.normal => 'Normal',
    DemoHizi.hizli => 'Hızlı',
    DemoHizi.turbo => 'Turbo',
  };
}
