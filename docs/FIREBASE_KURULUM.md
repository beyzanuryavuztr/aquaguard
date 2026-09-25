# AquaGuard — Gerçek Kullanıcı Hesabı (Firebase) Kurulumu

Bu belge, e-posta/şifre ile giriş/kayıt özelliğinin kodu **zaten hazır** —
sadece bir kere yapılması gereken, dışarıdan (Beyzanur'un kendi Google
hesabıyla) bir kurulum adımını anlatır. Bu adım tamamlanana kadar
uygulama **bugünkü gibi** çalışır: giriş/kayıt ekranı hiç gösterilmez,
hiçbir şey bozulmaz.

## Neden bu adım gerekiyor?

Gerçek bir "hesap" kavramı (e-posta+şifre, başka biri çalsa bile sizin
hesabınız olduğunu kanıtlayan bir sistem) mutlaka bir sunucu/bulut
servisi gerektirir — bunu sadece kod yazarak, bilgisayarda simüle
edemeyiz. Bu proje için ücretsiz, kod tarafı zaten hazır olan
**Firebase Authentication** seçildi (Google'ın servisi, küçük ölçekli
kullanım tamamen ücretsiz kotada kalır).

## Adımlar (yaklaşık 10 dakika)

1. https://console.firebase.google.com adresine gidin, Google
   hesabınızla giriş yapın.
2. "Proje ekle" (Add project) ile yeni bir proje oluşturun — istediğiniz
   ismi verin (örn. "aquaguard"). Google Analytics sorusu gelirse
   kapatabilirsiniz, gerekli değil.
3. Sol menüden **Authentication** > **Get started**'a tıklayın.
4. **Sign-in method** sekmesinde **E-posta/Şifre** (Email/Password)
   sağlayıcısını bulup **Enable** yapın, kaydedin.
5. Proje ana sayfasında **"</>"** (Web) simgesine tıklayarak yeni bir Web
   uygulaması ekleyin. İsim verin (örn. "aquaguard-web"), Firebase
   Hosting'i işaretlemenize gerek yok.
6. Size şuna benzer bir kod bloğu gösterecek:
   ```js
   const firebaseConfig = {
     apiKey: "AIzaSy...",
     authDomain: "aquaguard-xxxxx.firebaseapp.com",
     projectId: "aquaguard-xxxxx",
     storageBucket: "aquaguard-xxxxx.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abcdef"
   };
   ```
7. Bu 6 değeri `aquaguard_mobile/lib/config/firebase_secenekleri.dart`
   dosyasındaki aynı isimli alanlara **birebir kopyalayın** (her
   `YER_TUTUCU...` metnini gerçek değerle değiştirin — `authDomain` →
   `authDomain`, `storageBucket` → `storageBucket`, vb.).
8. Dosyayı kaydedin, uygulamayı yeniden başlatın (`flutter run` veya
   yeni bir `flutter build web`) — giriş/kayıt ekranı artık otomatik
   olarak görünecek.

## Test etme

Kurulumdan sonra: uygulamayı açın, "Kayıt Ol"a geçip gerçek bir e-posta
(kendi e-postanız yeterli, doğrulama e-postası gerekmez) + en az 6
karakterlik bir şifreyle bir hesap oluşturun. Firebase konsolunda
**Authentication > Users** sekmesinde yeni kullanıcıyı görmelisiniz.

## Önemli sınırlama (bilerek)

Bu hesap sistemi **sadece giriş/çıkışı** yönetir. Çiftlik/sensör/tedavi
verisi hâlâ **cihazda yerel olarak** (SharedPreferences/SQLite) tutulur
— hesaplar arasında veri ayrımı veya bulut senkronizasyonu YOKTUR. Aynı
cihazda farklı hesaplarla giriş yapan iki kişi aynı çiftlik verisini
görür. Gerçek çoklu-cihaz/çoklu-kullanıcı veri ayrımı, Firestore gibi
ayrı bir bulut veritabanı gerektiren, çok daha büyük bir sonraki adımdır
— bu oturumun kapsamında değildir.

## Jüri demosu için not

Giriş ekranında **"Misafir olarak devam et"** seçeneği var — saha
Wi-Fi'sinde bir sorun olursa (Firebase Auth internet gerektirir) demo asla
bloklanmaz, tıpkı Demo Modu'nun donanım bağımlılığını ortadan kaldırması
gibi.
