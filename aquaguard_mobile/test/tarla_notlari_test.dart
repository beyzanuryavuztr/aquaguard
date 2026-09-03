// AquaGuard - UygulamaDurumu Tarla Notlari Testleri
//
// notEkle/notSil'in dogru sekilde calistigini, tarla bazinda filtrelendigini,
// kalici depoya yazildigini ve bir tarla silindiginde yetim notlarin da
// temizlendigini dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('notEkle: yeni not tarlaNotlari(tarlaId) listesinde en basta gorunur', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.notEkle('tarla-1', 'İlk not');
    await durum.notEkle('tarla-1', 'İkinci not');

    final notlar = durum.tarlaNotlari('tarla-1');
    expect(notlar.length, 2);
    expect(notlar.first.metin, 'İkinci not'); // en yeni once

    durum.dispose();
  });

  test('notEkle: bos/bosluk-only metin eklenmez', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.notEkle('tarla-1', '   ');
    expect(durum.tarlaNotlari('tarla-1'), isEmpty);

    durum.dispose();
  });

  test('tarlaNotlari: farkli tarlalarin notlari birbirine karismaz', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.notEkle('tarla-1', 'Tarla 1 notu');
    await durum.notEkle('tarla-2', 'Tarla 2 notu');

    expect(durum.tarlaNotlari('tarla-1').single.metin, 'Tarla 1 notu');
    expect(durum.tarlaNotlari('tarla-2').single.metin, 'Tarla 2 notu');

    durum.dispose();
  });

  test('notSil: verilen id ile notu kaldirir', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.notEkle('tarla-1', 'Silinecek not');
    final notId = durum.tarlaNotlari('tarla-1').single.id;

    await durum.notSil(notId);
    expect(durum.tarlaNotlari('tarla-1'), isEmpty);

    durum.dispose();
  });

  test('notlar kalici depodan yeniden acilista geri yuklenir', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.notEkle('tarla-1', 'Kalici not');
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.tarlaNotlari('tarla-1').single.metin, 'Kalici not');
    durum2.dispose();
  });

  test('tarlaSil: silinen tarlanin notlari da temizlenir', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.notEkle('tarla-1', 'Bu not silinmeli');
    await durum.tarlaSil('tarla-1');

    expect(durum.tarlaNotlari('tarla-1'), isEmpty);

    durum.dispose();
  });

  group('Tarla profil guncellemesi (fotograf/konum/aciklama)', () {
    test('tarlaGuncelle profil alanlarini kalici olarak degistirir', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      final tarla = durum.tarlalar.first;
      await durum.tarlaGuncelle(
        tarla.kopyalaVeGuncelle(
          konum: 'Yeni Konum',
          aciklama: 'Yeni açıklama',
          fotografBase64: 'aGVsbG8=',
        ),
      );

      final guncellenen = durum.tarlalar.firstWhere((t) => t.id == tarla.id);
      expect(guncellenen.konum, 'Yeni Konum');
      expect(guncellenen.aciklama, 'Yeni açıklama');
      expect(guncellenen.fotografBase64, 'aGVsbG8=');

      durum.dispose();
    });
  });
}
