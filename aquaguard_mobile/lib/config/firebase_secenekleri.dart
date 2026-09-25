/// AquaGuard - Firebase Yapılandırması (YER TUTUCU)
/// ===================================================
///
/// Amaç:
///   E-posta/şifre ile gerçek çoklu kullanıcı hesabı için Firebase
///   Authentication kullanılıyor. Bu dosyadaki değerler YER TUTUCUDUR --
///   gerçek bir Firebase projesi kurulana kadar giriş/kayıt ekranı hiç
///   gösterilmez, uygulama BUGÜNKÜ GİBİ çalışmaya devam eder (bkz.
///   [firebaseYapilandirildiMi] ve providers/kimlik_dogrulama_provider.dart
///   -- Firebase.initializeApp() yer tutucu değerlerle HİÇ çağrılmaz).
///
///   Bu, firmware/config.h'deki WIFI_SSID yer tutucusuyla AYNI disiplin:
///   kod tamamen hazır, sadece dışarıdan (bu projede Beyzanur'un kendi
///   Google hesabıyla) bir kere yapılması gereken bir kurulum adımı
///   bekleniyor.
///
/// Nasıl doldurulur (bkz. docs/FIREBASE_KURULUM.md -- adım adım):
/// 1. https://console.firebase.google.com adresinde ÜCRETSİZ bir proje
///    oluşturun.
/// 2. Authentication > Sign-in method > E-posta/Şifre sağlayıcısını
///    ETKİNLEŞTİRİN.
/// 3. Projeye bir Web uygulaması ekleyin ("</> Web" simgesi) -- size
///    apiKey/appId/messagingSenderId/projectId/authDomain/storageBucket
///    değerlerini içeren bir yapılandırma nesnesi gösterecek.
/// 4. Aşağıdaki `web` sabitindeki YER_TUTUCU değerlerin HEPSİNİ, konsoldan
///    kopyaladığınız gerçek değerlerle DEĞİŞTİRİN.
///
///   (FlutterFire CLI kuruluysa `flutterfire configure` çalıştırıp onun
///   ürettiği lib/firebase_options.dart'ı da kullanabilirsiniz -- bu
///   durumda main.dart'taki importu o dosyaya yönlendirip bu dosyayı
///   silebilirsiniz; ikisi de aynı `FirebaseOptions` sınıfını üretir.)
library;

import 'package:firebase_core/firebase_core.dart';

/// Yer tutucu değerlerin ortak imzası -- gerçek bir Firebase apiKey'i
/// asla bu alt dizeyi içermez, bu yüzden basit bir "içeriyor mu" kontrolü
/// güvenilir bir yapılandırılmışlık testi olarak yeterlidir.
const String _yerTutucuIsareti = 'YER_TUTUCU';

/// main.dart ve KimlikDogrulamaProvider bu değeri kontrol ederek gerçek
/// bir Firebase bağlantısı deneyip denemeyeceğine karar verir. false
/// iken: Firebase.initializeApp() hiç çağrılmaz, giriş/kayıt ekranı hiç
/// gösterilmez, uygulama Firebase paketleri hiç eklenmemiş gibi davranır.
bool get firebaseYapilandirildiMi =>
    !FirebaseSecenekleri.web.apiKey.contains(_yerTutucuIsareti);

class FirebaseSecenekleri {
  /// Şimdilik sadece Web platformu (bu ortamda derlenip doğrulanabilen tek
  /// hedef -- bkz. proje hafızası, Android SDK'sı yok). Android/iOS için
  /// `flutterfire configure` ayrı config dosyaları (google-services.json
  /// vb.) üretir, bu oturumun kapsamı dışında.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YER_TUTUCU_API_KEY',
    appId: 'YER_TUTUCU_APP_ID',
    messagingSenderId: 'YER_TUTUCU_SENDER_ID',
    projectId: 'YER_TUTUCU_PROJECT_ID',
    authDomain: 'YER_TUTUCU.firebaseapp.com',
    storageBucket: 'YER_TUTUCU.appspot.com',
  );
}
