/// AquaGuard - Yazı Boyutu (Erişilebilirlik)
/// =============================================
///
/// Amac:
///   Sahada 45+ yaş operatör güneş altında, çoğu zaman gözlükle ekrana
///   bakar -- sabit yazı boyutu bu kullanıcı grubu için gerçek bir okunabilirlik
///   engeli. Operatör Ayarlar'dan 4 seçenekten birini seçer, tüm uygulama
///   (main.dart'taki MediaQuery sarmalayıcısı üzerinden) `TextScaler.linear`
///   ile yeniden ölçeklenir -- tek tek widget'larda ayrı ayrı font boyutu
///   yönetmeye gerek kalmaz.
///
/// Tarih:  2026-09-18
library;

enum YaziBoyutu { kucuk, normal, buyuk, cokBuyuk }

extension YaziBoyutuX on YaziBoyutu {
  double get oran => switch (this) {
    YaziBoyutu.kucuk => 0.85,
    YaziBoyutu.normal => 1.0,
    YaziBoyutu.buyuk => 1.15,
    YaziBoyutu.cokBuyuk => 1.3,
  };

  String get etiket => switch (this) {
    YaziBoyutu.kucuk => 'Küçük',
    YaziBoyutu.normal => 'Normal',
    YaziBoyutu.buyuk => 'Büyük',
    YaziBoyutu.cokBuyuk => 'Çok Büyük',
  };
}
