import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/services/bildirim_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bildirimBasligiGetir', () {
    test('her AktiviteTuru icin bos olmayan bir baslik doner', () {
      for (final tur in AktiviteTuru.values) {
        expect(bildirimBasligiGetir(tur), isNotEmpty);
      }
    });

    test('tespit ve tedavi turleri icin beklenen ozel basliklari doner', () {
      expect(bildirimBasligiGetir(AktiviteTuru.tespit), 'Tıkanma Tespit Edildi');
      expect(
        bildirimBasligiGetir(AktiviteTuru.tedaviBaslangic),
        'Tedavi Başladı',
      );
      expect(
        bildirimBasligiGetir(AktiviteTuru.tedaviBitis),
        'Tedavi Tamamlandı',
      );
      expect(
        bildirimBasligiGetir(AktiviteTuru.dusukPil),
        'Düşük Pil Uyarısı',
      );
    });
  });

  group('BildirimServisi', () {
    test(
      'baslat() cagrilmadan goster() cagrilirsa sessizce hicbir sey yapmaz (crash yok)',
      () async {
        await expectLater(
          BildirimServisi.goster(
            id: 1,
            baslik: 'Test',
            icerik: 'Test icerigi',
          ),
          completes,
        );
      },
    );

    test(
      'test ortaminda baslat() platform destegi olmadan bile HATA FIRLATMAZ',
      () async {
        await expectLater(BildirimServisi.baslat(), completes);
      },
    );
  });
}
