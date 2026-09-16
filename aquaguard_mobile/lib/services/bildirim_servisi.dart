/// AquaGuard - Yerel Bildirim Servisi
/// =========================================
///
/// Amac:
///   `flutter_local_notifications` (v22+) ile GERÇEK, işletim sistemi/
///   tarayıcı düzeyinde yerel bildirim gösterir -- şu ana kadar
///   `UygulamaDurumu._bildirimKuyrugu`nun tek çıktısı, sadece uygulama ÖN
///   PLANDAYKEN görünen bir SnackBar'dı. Bu paket artık Android/iOS/
///   macOS/Linux/Windows'un yanı sıra WEB'i de (Service Worker + tarayıcı
///   Notification API üzerinden, `flutter_local_notifications_web` federe
///   paketiyle) destekliyor -- bu yüzden CSV/mqtt dosyalarındaki gibi ayrı
///   io/web dosyalarına GEREK YOK, tek bir dosya tüm platformları kapsıyor.
///
///   Başlatma/izin isteme ve gösterme HER ADIMDA try/catch ile korunur:
///   bildirim bir İYİLEŞTİRMEdir, kritik yol değildir -- desteklenmeyen bir
///   platformda (ör. test ortamı, izin reddedilmiş bir tarayıcı) sessizce
///   devre dışı kalır ve uygulama mevcut SnackBar davranışına döner.
///
/// Tarih:  2026-09-05
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/bildirim_onceligi.dart';

class BildirimServisi {
  BildirimServisi._();

  static final FlutterLocalNotificationsPlugin _eklenti =
      FlutterLocalNotificationsPlugin();
  static bool _hazir = false;

  static Future<void> baslat() async {
    if (_hazir) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Aç');
    const windows = WindowsInitializationSettings(
      appName: 'AquaGuard',
      appUserModelId: 'Com.AquaGuard.AquaGuardMobile',
      guid: '5f9c1b8e-6a2d-4b1a-9e3f-2c7d8a1b4e6f',
    );
    const ayarlar = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );
    try {
      final sonuc = await _eklenti.initialize(settings: ayarlar);
      if (sonuc == false) {
        _hazir = false;
        return;
      }
      await _eklenti
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _eklenti
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _hazir = true;
    } catch (_) {
      _hazir = false;
    }
  }

  /// [oncelik]: SEMA v2 (2026-09-16) -- Android tarafinda ayri bir kanal
  /// (channel) ve Importance/Priority seviyesi secer; kritik/yuksek AYRI
  /// bir kanalda ('aquaguard_kritik') gosterilir ki isletim sistemi bunu
  /// dusuk oncelikli bildirimlerle AYNI kurallarla (ornegin "Rahatsiz
  /// Etme" modunda sessize alma) ele almasin -- operator, telefon
  /// ayarlarindan bu kanala ozel izin verebilir. `groupKey` ayni kanaldaki
  /// birden fazla bildirimi Android'de tek bir grup altinda ozetler.
  static Future<void> goster({
    required int id,
    required String baslik,
    required String icerik,
    Oncelik oncelik = Oncelik.orta,
  }) async {
    if (!_hazir) return;
    final kritikMi =
        oncelik == Oncelik.kritik || oncelik == Oncelik.yuksek;
    final importance = switch (oncelik) {
      Oncelik.kritik => Importance.max,
      Oncelik.yuksek => Importance.high,
      Oncelik.orta => Importance.defaultImportance,
      Oncelik.dusuk => Importance.low,
    };
    final priority = switch (oncelik) {
      Oncelik.kritik => Priority.max,
      Oncelik.yuksek => Priority.high,
      Oncelik.orta => Priority.defaultPriority,
      Oncelik.dusuk => Priority.low,
    };
    final detaylar = NotificationDetails(
      android: AndroidNotificationDetails(
        kritikMi ? 'aquaguard_kritik' : 'aquaguard_uyarilar',
        kritikMi ? 'AquaGuard Kritik Uyarılar' : 'AquaGuard Uyarıları',
        channelDescription: kritikMi
            ? 'Tıkanma tespiti ve operatör kontrolü gerektiren acil durumlar'
            : 'Tedavi tamamlanma ve pil durumu gibi bilgilendirici bildirimler',
        importance: importance,
        priority: priority,
        groupKey: 'aquaguard_bildirimleri',
      ),
      linux: const LinuxNotificationDetails(),
      windows: const WindowsNotificationDetails(),
    );
    try {
      await _eklenti.show(
        id: id,
        title: baslik,
        body: icerik,
        notificationDetails: detaylar,
      );
    } catch (_) {
      // SnackBar zaten aynı mesajı gösteriyor -- bildirim basarisiz olsa
      // bile kullanici bilgilendirilmemis olmuyor.
    }
  }
}
