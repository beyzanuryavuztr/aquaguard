// AquaGuard - Bekleyen yazim izleme testleri (A5)
//
// unawaited() ile baslatilan yazimlarin bitmesinin beklenebildigini ve
// hata durumunda bile bekleyisin ASLA firlatmadigini dogrular.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/providers/depolama_unawaited.dart';

void main() {
  test(
    'bekleyenYazimlariBekle, baslatilan yazim bitene kadar bekler',
    () async {
      final tamamlayici = Completer<void>();
      var bitti = false;
      unawaited(tamamlayici.future.then((_) => bitti = true));

      final bekleyis = bekleyenYazimlariBekle();
      expect(bitti, isFalse);
      tamamlayici.complete();
      await bekleyis;

      expect(bitti, isTrue);
    },
  );

  test('hata veren yazim bekleyisi patlatmaz', () async {
    unawaited(Future<void>.error(StateError('yazma hatasi')));
    await bekleyenYazimlariBekle();
  });

  test('bekleyen yazim yokken hemen doner', () async {
    await bekleyenYazimlariBekle();
  });
}
