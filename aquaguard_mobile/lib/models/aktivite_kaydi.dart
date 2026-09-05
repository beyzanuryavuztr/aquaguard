/// AquaGuard - Aktivite Kaydi Veri Modeli
/// ==========================================
///
/// Amac:
///   Uygulama genelinde ("Genel Bakış" ekraninda) gosterilen, tum
///   zonlardaki onemli olaylarin (durum degisikligi, tedavi baslangici/
///   bitisi) KALICI (uygulama acikken bellekte tutulan) kaydidir. Transient
///   SnackBar bildirimlerinden farkli olarak, bu liste bir ekranda
///   goruntulenip geriye donup incelenebilir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import 'sensor_okuma.dart';

enum AktiviteTuru {
  tespit,
  belirsiz,
  normaleDonus,
  tedaviBaslangic,
  tedaviBitis,
  manuelMudahale,
  dusukPil,
}

/// Iki ARDISIK okuma arasindaki durum/tedavi GECISLERINDEN aktivite kaydi
/// uretir (saf fonksiyon, yan etkisi yok). Hem UygulamaDurumu (canli akis
/// sirasinda) hem de GecmisVeriUreticisi (gecmise donuk toplu veri
/// uretirken) AYNI bu fonksiyonu kullanir -- ayni mesaj/kural mantigi iki
/// yerde elle kopyalanmasin diye (bkz. feedback: "Schema single source of
/// truth" -- bu projede daha once tam olarak bu tur bir kopyalanma bir
/// hataya sebep olmustu).
List<AktiviteKaydi> gecisAktiviteleriniUret(
  SensorOkuma onceki,
  SensorOkuma yeni,
) {
  final sonuc = <AktiviteKaydi>[];

  if (onceki.durum != yeni.durum) {
    switch (yeni.durum) {
      case TeshisDurumu.tespitEdildi:
        sonuc.add(
          AktiviteKaydi(
            zaman: yeni.zaman,
            zone: yeni.zone,
            mesaj:
                'Zon ${yeni.zone}: ${turEtiketi(yeni.tikanmaTuru)} tıkanma tespit edildi '
                '(güven %${yeni.guven.toStringAsFixed(0)})',
            tur: AktiviteTuru.tespit,
          ),
        );
        break;
      case TeshisDurumu.belirsiz:
        sonuc.add(
          AktiviteKaydi(
            zaman: yeni.zaman,
            zone: yeni.zone,
            mesaj:
                'Zon ${yeni.zone}: Tıkanma şüphesi var, operatör kontrolü gerekiyor',
            tur: AktiviteTuru.belirsiz,
          ),
        );
        break;
      case TeshisDurumu.normal:
        if (onceki.durum != TeshisDurumu.bilinmiyor) {
          sonuc.add(
            AktiviteKaydi(
              zaman: yeni.zaman,
              zone: yeni.zone,
              mesaj: 'Zon ${yeni.zone}: Durum normale döndü',
              tur: AktiviteTuru.normaleDonus,
            ),
          );
        }
        break;
      case TeshisDurumu.bilinmiyor:
        break;
    }
  }

  if (onceki.tedaviAktif != yeni.tedaviAktif) {
    if (yeni.tedaviAktif != TedaviTuru.yok) {
      sonuc.add(
        AktiviteKaydi(
          zaman: yeni.zaman,
          zone: yeni.zone,
          mesaj:
              'Zon ${yeni.zone}: ${tedaviEtiketi(yeni.tedaviAktif)} başlatıldı',
          tur: AktiviteTuru.tedaviBaslangic,
        ),
      );
    } else if (onceki.tedaviAktif != TedaviTuru.yok) {
      sonuc.add(
        AktiviteKaydi(
          zaman: yeni.zaman,
          zone: yeni.zone,
          mesaj: 'Zon ${yeni.zone}: Tedavi tamamlandı, durulama başladı',
          tur: AktiviteTuru.tedaviBitis,
        ),
      );
    }
  }

  return sonuc;
}

class AktiviteKaydi {
  final DateTime zaman;
  final int zone;
  final String mesaj;
  final AktiviteTuru tur;

  const AktiviteKaydi({
    required this.zaman,
    required this.zone,
    required this.mesaj,
    required this.tur,
  });

  IconData get ikon {
    switch (tur) {
      case AktiviteTuru.tespit:
        return Icons.warning_amber;
      case AktiviteTuru.belirsiz:
        return Icons.help_outline;
      case AktiviteTuru.normaleDonus:
        return Icons.check_circle_outline;
      case AktiviteTuru.tedaviBaslangic:
        return Icons.build_circle_outlined;
      case AktiviteTuru.tedaviBitis:
        return Icons.water_drop_outlined;
      case AktiviteTuru.manuelMudahale:
        return Icons.pan_tool_outlined;
      case AktiviteTuru.dusukPil:
        return Icons.battery_alert;
    }
  }

  Color renkGetir(BuildContext context) {
    switch (tur) {
      case AktiviteTuru.tespit:
        return const Color(0xFFC62828);
      case AktiviteTuru.belirsiz:
        return const Color(0xFFF9A825);
      case AktiviteTuru.normaleDonus:
        return const Color(0xFF2E7D32);
      case AktiviteTuru.tedaviBaslangic:
      case AktiviteTuru.tedaviBitis:
        return const Color(0xFF1565C0);
      case AktiviteTuru.manuelMudahale:
        return Theme.of(context).colorScheme.primary;
      case AktiviteTuru.dusukPil:
        return const Color(0xFFF9A825);
    }
  }

  Map<String, dynamic> toJson() => {
    'zaman': zaman.toIso8601String(),
    'zone': zone,
    'mesaj': mesaj,
    'tur': tur.name,
  };

  factory AktiviteKaydi.fromJson(Map<String, dynamic> json) => AktiviteKaydi(
    zaman: DateTime.tryParse(json['zaman'] as String? ?? '') ?? DateTime.now(),
    zone: (json['zone'] as num?)?.toInt() ?? 0,
    mesaj: json['mesaj'] as String? ?? '',
    tur: AktiviteTuru.values.firstWhere(
      (e) => e.name == json['tur'],
      orElse: () => AktiviteTuru.normaleDonus,
    ),
  );
}

/// Yerel bildirim (BildirimServisi) ve SnackBar basligi olarak kullanilir --
/// [AktiviteKaydi.mesaj] zaten zon/detay iceren govde metnidir, bu sadece
/// kisa bir kategori basligidir.
String bildirimBasligiGetir(AktiviteTuru tur) {
  switch (tur) {
    case AktiviteTuru.tespit:
      return 'Tıkanma Tespit Edildi';
    case AktiviteTuru.belirsiz:
      return 'Operatör Kontrolü Gerekiyor';
    case AktiviteTuru.normaleDonus:
      return 'Durum Normale Döndü';
    case AktiviteTuru.tedaviBaslangic:
      return 'Tedavi Başladı';
    case AktiviteTuru.tedaviBitis:
      return 'Tedavi Tamamlandı';
    case AktiviteTuru.manuelMudahale:
      return 'Operatör Müdahalesi';
    case AktiviteTuru.dusukPil:
      return 'Düşük Pil Uyarısı';
  }
}

/// Bir [AktiviteKaydi] icin yerel bildirim ID'si uretir -- ACIMASIZ
/// DENETIM NOTU (2026-09-06): daha once dogrudan `kayit.hashCode`
/// (Object'in VARSAYILAN kimlik-tabanli hashCode'u) kullaniliyordu. Bunun
/// iki sorunu var: (1) Android'in bildirim ID'si 32-bit IMZALI bir `int`
/// olmak ZORUNDADIR -- Dart'in kimlik hashCode'unun bu araliga sigacagi
/// GARANTI DEGILDIR, platform kanalinda beklenmeyen kesilme/tasma riski
/// tasir; (2) kimlik-tabanli hashCode her nesne ornegi icin FARKLIDIR,
/// yani ayni ICERIGE sahip iki kayit bile asla ayni ID'yi almaz (kasitli
/// bir tekillestirme/guncelleme ihtiyaci olmasa da, bu ongorulemez bir
/// davranistir). Bunun yerine ZAMAN+ZON+TUR'den turetilen, 31-bit pozitif
/// araliga (0x7FFFFFFF ile maskelenerek) SIKISTIRILMIS deterministik bir
/// ID kullanilir -- her platformda guvenli VE ayni kayit icin tekrarlanabilir.
int bildirimIdGetir(AktiviteKaydi kayit) {
  final ham =
      kayit.zaman.millisecondsSinceEpoch ^
      (kayit.zone * 1000003) ^
      (kayit.tur.index * 7919);
  return ham & 0x7FFFFFFF;
}
