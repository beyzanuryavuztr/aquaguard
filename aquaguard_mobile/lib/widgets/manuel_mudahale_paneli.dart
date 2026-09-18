/// AquaGuard - Operator Mudahale Paneli
/// ========================================
///
/// Amac:
///   AquaGuard'in temel iddiasi OTONOM teshis+tedavidir, ama sahada calisan
///   gercek bir sistemin operatore GUVENLIK/ESNEKLIK sunmasi gerekir:
///     1) "Belirsiz" durumda sistem tikanma turunu yeterli guvenle
///        secemedigi icin, operatorun uygun tedaviyi MANUEL secmesini saglar
///        (ya da durumu yanlis alarm olarak isaretleyip normale doner).
///     2) Su an suren HERHANGI BIR tedavi, operator tarafindan her zaman
///        ERKEN durdurulabilir (ornegin sahada baska bir sorun fark edilirse).
///
///   Bu, daha once "belirsiz -> operatör kontrolü gerekiyor" mesajinin hicbir
///   ic aksiyona baglanmamasi eksikligini giderir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bekleyen_komut.dart';
import '../models/sensor_okuma.dart';
import '../providers/ayarlar_provider.dart';
import '../providers/cihaz_iletisim_provider.dart';

class ManuelMudahalePaneli extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;

  const ManuelMudahalePaneli({
    super.key,
    required this.zonNumarasi,
    required this.okuma,
  });

  @override
  Widget build(BuildContext context) {
    if (okuma.tedaviAktif != TedaviTuru.yok) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _DurdurKarti(zonNumarasi: zonNumarasi, okuma: okuma),
      );
    }
    if (okuma.durum == TeshisDurumu.belirsiz) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _SecimKarti(zonNumarasi: zonNumarasi),
      );
    }
    return const SizedBox.shrink();
  }
}

class _PanelBasligi extends StatelessWidget {
  final String metin;
  const _PanelBasligi({required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.pan_tool_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(metin, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _DurdurKarti extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;
  const _DurdurKarti({required this.zonNumarasi, required this.okuma});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelBasligi(metin: 'Operatör Müdahalesi'),
            const SizedBox(height: 8),
            Text(
              'Devam eden ${tedaviEtiketi(okuma.tedaviAktif)} işlemini sahada gerekli '
              'görürseniz erken sonlandırabilirsiniz. Güvenlik gereği sistem '
              'ardından zorunlu durulama adımına geçecektir.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Tedaviyi Durdur'),
              onPressed: () => _onayDiyaloguGoster(
                context,
                baslik: 'Tedaviyi Durdur',
                icerik:
                    '${tedaviEtiketi(okuma.tedaviAktif)} işlemini erken durdurmak '
                    'istediğinize emin misiniz? Sistem zorunlu durulama adımına geçecektir.',
                onayEtiketi: 'Durdur',
                onOnay: () async {
                  await context
                      .read<CihazIletisimProvider>()
                      .manuelTedaviDurdur(zonNumarasi);
                  return KomutSonucu.uygulandi;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecimKarti extends StatelessWidget {
  final int zonNumarasi;
  const _SecimKarti({required this.zonNumarasi});

  static const _secenekler = [
    TedaviTuru.asitDozlama,
    TedaviTuru.klorEnjeksiyon,
    TedaviTuru.yuksekBasincliYikama,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelBasligi(metin: 'Operatör Kontrolü Gerekiyor'),
            const SizedBox(height: 8),
            Text(
              'Sistem tıkanma türünü yeterli güvenle belirleyemedi. Aşağıdaki '
              '"Neden Bu Karar?" panelindeki güven skorlarını ve sensör '
              'eğilimlerini inceleyerek uygun tedaviyi siz seçebilir ya da '
              'durumu yanlış alarm olarak işaretleyebilirsiniz.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tedavi in _secenekler)
                  OutlinedButton(
                    onPressed: () => _onayDiyaloguGoster(
                      context,
                      baslik: 'Tedaviyi Manuel Başlat',
                      icerik:
                          'Zon $zonNumarasi için "${tedaviEtiketi(tedavi)}" '
                          'tedavisini manuel olarak başlatmak istediğinize emin misiniz? '
                          'Bu işlem geri alınamaz.',
                      onayEtiketi: 'Başlat',
                      // Kimyasal dozlama (asit/klor) GERI ALINAMAZ bir
                      // saha eylemidir -- yanlislikla dokunmayi zorlastirmak
                      // icin 3 saniyelik bir geri sayim eklenir. Tedaviyi
                      // DURDURMAK veya yanlis alarmi normale dondurmek
                      // kimyasal baslatmaz, bu geri sayima ihtiyac duymaz.
                      geriSayimSaniye: 3,
                      onOnay: () => context
                          .read<CihazIletisimProvider>()
                          .manuelTedaviBaslat(zonNumarasi, tedavi),
                    ),
                    child: Text(tedaviEtiketi(tedavi)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Yanlış Alarm — Normale Döndür'),
              onPressed: () => _onayDiyaloguGoster(
                context,
                baslik: 'Yanlış Alarm',
                icerik:
                    'Zon $zonNumarasi için bu durumu yanlış alarm olarak '
                    'işaretleyip herhangi bir tedavi uygulamadan normal izlemeye '
                    'dönmek istediğinize emin misiniz?',
                onayEtiketi: 'Normale Döndür',
                onOnay: () async {
                  await context
                      .read<CihazIletisimProvider>()
                      .manuelNormaleDondur(zonNumarasi);
                  return KomutSonucu.uygulandi;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [onOnay] bir `Future<KomutSonucu>` doner -- ACIMASIZ DENETIM (2026-09-06):
/// onceden `VoidCallback` idi ve SONUCU HIC beklemeden/kontrol etmeden HER
/// ZAMAN "$baslik uygulandı" gosteriyordu. SEMA v2 GENISLEMESI (2026-09-16):
/// eskiden `Future<bool>` idi (basarili/basarisiz), simdi cihazdan ACK/NACK
/// gelene kadar BEKLEYEN gercek MQTT modunda 3. bir durumu (zamanAsimi)
/// da ayirt edebiliyor -- bir "REDDEDİLDİ" mesaji artik SADECE mutex
/// kilidi anlamina gelir, "cihazla iletisim sorunlu" ile KARISTIRILMAZ.
///
/// [geriSayimSaniye] > 0 ise (2026-09-18, guvenlik sertlestirme): onay
/// butonu o kadar saniye DEVRE DISI kalir ve uzerinde geri sayim gosterir --
/// GERI ALINAMAZ kimyasal dozlama eylemlerinde (bkz. cagiran yer) yanlislikla
/// dokunmayi zorlastirmak icin. Varsayilan 0 -- diger (durdur/yanlis alarm)
/// dialoglarin davranisini DEGISTIRMEZ.
void _onayDiyaloguGoster(
  BuildContext context, {
  required String baslik,
  required String icerik,
  required String onayEtiketi,
  required Future<KomutSonucu> Function() onOnay,
  int geriSayimSaniye = 0,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => _OnayDiyalogu(
      disKontext: context,
      baslik: baslik,
      icerik: icerik,
      onayEtiketi: onayEtiketi,
      onOnay: onOnay,
      geriSayimSaniye: geriSayimSaniye,
    ),
  );
}

class _OnayDiyalogu extends StatefulWidget {
  final BuildContext disKontext;
  final String baslik;
  final String icerik;
  final String onayEtiketi;
  final Future<KomutSonucu> Function() onOnay;
  final int geriSayimSaniye;

  const _OnayDiyalogu({
    required this.disKontext,
    required this.baslik,
    required this.icerik,
    required this.onayEtiketi,
    required this.onOnay,
    required this.geriSayimSaniye,
  });

  @override
  State<_OnayDiyalogu> createState() => _OnayDiyaloguState();
}

class _OnayDiyaloguState extends State<_OnayDiyalogu> {
  late int _kalanSaniye = widget.geriSayimSaniye;
  Timer? _sayac;
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    if (_kalanSaniye > 0) {
      _sayac = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _kalanSaniye--);
        if (_kalanSaniye <= 0) _sayac?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  void _hapticTetikle() {
    if (!widget.disKontext.mounted) return;
    if (!widget.disKontext.read<AyarlarProvider>().titresimAktif) return;
    // Kimyasal dozlama baslatma (geri sayimli) ORTA yogunlukta, digerleri
    // (tedaviyi durdur/yanlis alarm) HAFIF yogunlukta titresir -- eylemin
    // geri alinabilirligiyle orantili bir dokunsal ayrim.
    if (widget.geriSayimSaniye > 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _onayla() async {
    _hapticTetikle();
    setState(() => _gonderiliyor = true);
    final sonuc = await widget.onOnay();
    if (mounted) Navigator.of(context).pop();
    if (!widget.disKontext.mounted) return;
    final mesaj = switch (sonuc) {
      KomutSonucu.uygulandi => '${widget.baslik} uygulandı',
      KomutSonucu.reddedildi =>
        '${widget.baslik} REDDEDİLDİ (mutex kilidi — zon zaten '
            'bir tedavi/durulama sürdürüyor)',
      KomutSonucu.zamanAsimi =>
        '${widget.baslik} için cihazdan yanıt alınamadı (zaman aşımı) — '
            'bağlantıyı kontrol edin',
    };
    ScaffoldMessenger.of(
      widget.disKontext,
    ).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final devreDisi = _kalanSaniye > 0 || _gonderiliyor;
    final butonMetni = _kalanSaniye > 0
        ? '${widget.onayEtiketi} ($_kalanSaniye)'
        : widget.onayEtiketi;
    return AlertDialog(
      title: Text(widget.baslik),
      content: Text(widget.icerik),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: devreDisi ? null : _onayla,
          child: Text(butonMetni),
        ),
      ],
    );
  }
}
