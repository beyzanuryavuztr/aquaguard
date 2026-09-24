/// AquaGuard - Bağlamsal Yardım Metinleri (Tek Kaynak)
/// ==========================================================
///
/// Amac:
///   Her ana ekranin "?" butonuna basinca gosterilecek, teknik olmayan bir
///   ciftci operatore hitap eden 2-3 cumlelik aciklama. Ekran adi -> metin
///   haritasi, `widgets/yardim_butonu.dart` tarafindan tuketilir -- yeni bir
///   ekrana yardim eklemek icin sadece bu haritaya bir satir eklenir.
///
/// Tarih:  2026-09-16
library;

const Map<String, String> yardimMetinleri = {
  'genel_bakis':
      'Bu ekran, tüm zonlarınızın anlık durumunu tek bakışta gösterir. '
      'Yeşil "normal", sarı "kontrol gerekiyor", kırmızı "tıkanma tespit '
      'edildi" ve mavi "tedavi/durulama sürüyor" anlamına gelir. Bir zona '
      'dokunarak ayrıntılı sensör verilerine ulaşabilirsiniz.',
  'zon_detay':
      'Seçtiğiniz zonun 6 sensöründen (pH, EC, ORP, türbidite, debi, '
      'basınç) gelen anlık ve geçmiş verileri gösterir. Bir sensör kartına '
      'dokunarak o sensörün zaman içindeki değişimini büyük grafikte '
      'görebilirsiniz. "Neden Bu Karar?" bölümü, sistemin tespitini hangi '
      'verilere dayandırdığını açıklar.',
  'tedavi_gecmisi':
      'Sistemin bugüne kadar uyguladığı tüm tedavilerin listesini, başarı '
      'oranını ve tahmini su/maliyet etkisini gösterir. Türe göre '
      'filtreleyebilir, CSV veya PDF olarak dışa aktarabilirsiniz.',
  'trend_analizi':
      'Bir zonun 6 sensöründeki değişimi 24 saat, 7 gün veya 30 günlük '
      'pencerede karşılaştırmalı olarak inceleyebilirsiniz. Kesikli çizgiler, '
      'sistemin tıkanma kararı verdiği eşik değerleri gösterir.',
  'ayarlar':
      'Kullanıcı profilinizi, görünüm tercihlerinizi, gerçek donanım '
      'bağlantısını (Demo Modu kapalıyken) ve bildirim/güvenlik '
      'ayarlarınızı buradan yönetirsiniz.',
  'uzaktan_sulama':
      'Tarladan uzaktayken bile sulama başlatabilirsiniz: bir çiftlik ve '
      'sulanacak zon(lar)ı seçin, süreyi (dakika) girin, "Sula" butonuna '
      'basın. Süre dolunca vana kendiliğinden kapanır -- uygulamayı '
      'kapatsanız bile su boşa akmaya devam etmez. Sulama sürerken bir '
      'tıkanma tespit edilirse, sistem sizin müdahalenize gerek kalmadan '
      'otomatik olarak teşhis koyup uygun tedaviyi uygular.',
  'besin_takviyesi':
      'Tıkanma tedavisinden tamamen bağımsız bir özellik: örneğin ziraat '
      'mühendisinin önerdiği bir besin takviyesini (sıvı veya toz) sulama '
      'suyuna katmak için kullanılır. Çiftlik ve hedef zon(lar)ı seçip '
      '"Sıvı" veya "Toz Takviye Başlat" butonuna basmanız yeterli -- süre '
      'sabittir, ayarlamanıza gerek yok. Zon zaten bir tedavi/durulama '
      'sürdürüyorsa istek güvenlik amacıyla reddedilir.',
};
