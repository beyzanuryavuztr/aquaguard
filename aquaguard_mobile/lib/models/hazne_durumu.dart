/// AquaGuard - Hazne Durumu (Kimyasal Tank Seviyesi)
/// ========================================================
///
/// Amac:
///   Asit/klor haznelerinin doluluk yuzdesini temsil eder. GERCEK
///   donanimda henuz bir hazne seviye sensoru YOK (bkz. firmware/config.h) --
///   bu yuzden bu model SADECE MQTT semasinin (sensor_okuma.dart'taki
///   nullable `hazneAsitSeviyeYuzde`/`hazneKlorSeviyeYuzde` alanlari) veri
///   TASIDIGI durumlarda kullanilir. Veri yoksa (null) UI bu karti HIC
///   GOSTERMEZ -- sahte/varsayilan bir doluluk uydurulmaz (projenin
///   durustluk ilkesi, bkz. proje hafizasi).
///
/// Tarih:  2026-09-16
library;

enum HazneTuru { asit, klor }

extension HazneTuruX on HazneTuru {
  String get etiket => switch (this) {
    HazneTuru.asit => 'Asit Haznesi',
    HazneTuru.klor => 'Klor Haznesi',
  };
}

class HazneDurumu {
  final HazneTuru tur;
  final double dolulukYuzdesi;

  const HazneDurumu({required this.tur, required this.dolulukYuzdesi});

  bool get dusukSeviye => dolulukYuzdesi < 20;
}
