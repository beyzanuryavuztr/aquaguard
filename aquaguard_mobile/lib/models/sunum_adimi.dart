/// AquaGuard - Sunum Adimi (Juri Sunum Modu icin)
/// ===================================================
///
/// Amac:
///   Juri/izleyici karsisinda akici bir demo icin, onceden hazirlanmis
///   sabit bir "sunum senaryosu" -- her adimda ne soylenecegini ve (varsa)
///   tek dokunuslu hangi aksiyonun yapilacagini tasir.
///
///   BILEREK ekranlar arasi OTOMATIK gezinme YOK: bazi adimlar
///   `opsiyonelDemoSenaryosu` araciligiyla mevcut
///   UygulamaDurumu.demoSenaryosuTetikle()'yi dogrudan cagirir (ayni ekranda
///   kalinir), digerleri ise SADECE bir metin talimati verir ("simdi Tedavi
///   Gecmisi'ne gecin") -- sunucu bu adimlari kendi eliyle, kendi hizinda
///   ilerletir. Bu, Flutter'da güvenilir sekilde test edilmesi zor olan
///   coklu-ekran otomatik gezinme mantigindan bilerek kacinir.
///
/// Tarih:  2026-09-15
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import '../providers/uygulama_durumu.dart' show DemoSenaryosu;

class SunumAdimi {
  final String baslik;
  final String konusmaMetni;
  final DemoSenaryosu? opsiyonelDemoSenaryosu;

  const SunumAdimi({
    required this.baslik,
    required this.konusmaMetni,
    this.opsiyonelDemoSenaryosu,
  });
}

/// Sabit sunum senaryosu -- sira ONEMLIDIR, sunum akisi bu sirayla tasarlandi.
const List<SunumAdimi> sunumAdimlari = [
  SunumAdimi(
    baslik: 'Açılış',
    konusmaMetni:
        'AquaGuard, toprak altı damla sulama sistemlerinde emitör '
        'tıkanmasını türüne göre otonom teşhis eden ve uygun tedaviyi '
        'kendi kendine uygulayan bir sistemdir. Şimdi canlı bir demo ile '
        'gösterelim.',
  ),
  SunumAdimi(
    baslik: 'Sağlıklı Sistem',
    konusmaMetni:
        'Sistem normalde böyle çalışır: 4 zon da sağlıklı, tüm sensör '
        'değerleri referans aralığında. [Bu Adımı Tetikle] butonuna basın.',
    opsiyonelDemoSenaryosu: DemoSenaryosu.saglikli,
  ),
  SunumAdimi(
    baslik: 'Kimyasal Tıkanma Tespiti',
    konusmaMetni:
        'Şimdi Zon 2\'de bir kimyasal tıkanma simüle ediyoruz. Sistem pH '
        've EC\'nin BİRLİKTE yükseldiğini (8.3 / 2.75 imzası) tanıyıp asit '
        'dozlama tedavisini otonom olarak başlatacak.',
    opsiyonelDemoSenaryosu: DemoSenaryosu.kimyasal,
  ),
  SunumAdimi(
    baslik: 'Açıklanabilirlik',
    konusmaMetni:
        'Şimdi Zon 2\'ye dokunup "Neden Bu Karar?" panelini gösterelim — '
        'sistem sadece "kimyasal" demiyor, üç türün de (kimyasal/biyolojik/'
        'fiziksel) güven skorunu ayrı ayrı gösteriyor. Bu şeffaflık, '
        'rakiplerde bulunmayan bir özellik.',
  ),
  SunumAdimi(
    baslik: 'Mutex Kilidi (Güvenlik)',
    konusmaMetni:
        'Şimdi güvenlik mekanizmasını gösterelim: Zon 2\'de klor '
        'enjeksiyonu sürerken sistem AYNI ZONDA asit dozlamayı REDDEDER — '
        'asit ve klor asla aynı anda çalışamaz, toksik gaz riski var.',
    opsiyonelDemoSenaryosu: DemoSenaryosu.mutexKilidi,
  ),
  SunumAdimi(
    baslik: 'Uzaktan/Manuel Kontrol',
    konusmaMetni:
        'AquaGuard sadece otonom teşhis yapmaz, operatöre manuel kontrol '
        'de sunar. Şimdi Genel Bakış\'ın sağ üstündeki "⋮" menüsünden '
        'Uzaktan Sulama\'ya geçin — bir çiftlik ve zon seçip süre girerek '
        'sulamayı tek dokunuşla başlatabilirsiniz; çiftliğin GPS konumu '
        'varsa hava durumuna göre basit bir sulama önerisi de görünür. '
        'Aynı menüden Besin Takviyesi\'ne geçip sıvı/toz dozlamayı da '
        'gösterebilirsiniz.',
  ),
  SunumAdimi(
    baslik: 'Rapor ve Analiz',
    konusmaMetni:
        'Şimdi Tedavi Geçmişi sekmesine geçip, tıkanma türü dağılımını, '
        'başarı oranını ve tek dokunuşla oluşturulan PDF raporu '
        'gösterelim.',
  ),
  SunumAdimi(
    baslik: 'İş Modeli',
    konusmaMetni:
        'Son olarak Ayarlar > Hakkında > İş Fizibilitesi\'ne geçip maliyet, '
        'hedef satış fiyatı ve rakip karşılaştırmasını gösterelim.',
  ),
  SunumAdimi(
    baslik: 'Kapanış',
    konusmaMetni:
        'AquaGuard, sensör tabanlı tıkanma türü teşhisini, türe özgü '
        'otonom tedavi kararıyla tek bir kapalı döngüde birleştiren ilk '
        'sistemdir. Sorularınızı bekliyoruz.',
  ),
];
