/// AquaGuard - MQTT Baglanti Guvenlik Uyarilari (K4 + Y4)
/// ===========================================================
///
/// Amac:
///   Gercek moda gecen operatorun, guvensiz bir yapilandirmayi FARK ETMEDEN
///   kullanmasini onlemek. Saf fonksiyonlardir (UI'dan bagimsiz, test edilir).
library;

/// Herkese acik, kimliksiz TEST broker'lari -- bu konulara YAYIN yapabilen
/// herkes sahte veri basabilir VE (kimlik yoksa) komut konusuna yazip
/// kimyasal dozlama baslatabilir/vanayi kapatabilir.
const _genelBrokerlar = [
  'mosquitto.org',
  'hivemq.com',
  'emqx.io',
  'eclipseprojects.io',
];

/// [host] herkese acik bir test broker'i ise uyari metni, degilse null.
String? genelBrokerUyarisi(String host) {
  final kucuk = host.trim().toLowerCase();
  if (kucuk.isEmpty) return null;
  final genelMi = _genelBrokerlar.any(
    (b) => kucuk == b || kucuk.endsWith('.$b'),
  );
  if (!genelMi) return null;
  return 'Herkese açık bir TEST broker\'ı kullanıyorsunuz: konuyu bilen herkes '
      'sahte veri yayınlayabilir ve cihaza komut gönderebilir (kimyasal '
      'dozlama, vana). Gerçek kullanımda kendi broker\'ınızı, kullanıcı '
      'adı/parola ve TLS ile çalıştırın.';
}

/// https ile yayinlanan bir web sayfasi, sifresiz WebSocket (ws://)
/// baglantisini TARAYICI olarak engeller (karisik icerik). Bu durumda TLS
/// (wss://) sart oldugu icin uyari metni, degilse null.
String? webTlsUyarisi({
  required bool web,
  required bool https,
  required bool guvenli,
}) {
  if (!web || !https || guvenli) return null;
  return 'Bu sayfa https ile açıldığı için tarayıcı şifresiz WebSocket '
      'bağlantısını ENGELLER. Gerçek cihaza bağlanmak için Güvenli Bağlantı '
      '(TLS) açık olmalı ve broker WSS (örn. 8081) desteklemelidir.';
}
