/// AquaGuard - PDF Rapor Servisi
/// ====================================
///
/// Amac:
///   Tedavi Geçmişi ekranındaki analiz özetini (tıkanma türü dağılımı,
///   tedavi sayıları, ortalama başarı oranı) ve filtrelenmiş tespit
///   günlüğünü, sahadaki mühendisin yöneticisine/müşteriye gönderebileceği
///   TEK sayfalık bir özet yerine çok sayfalı, yazdırılabilir bir PDF
///   olarak üretir. `printing` paketi web/masaüstü/mobil arasında
///   platform farkı olmadan çalışır (CSV dışa aktarmadaki gibi ayrı
///   web/io dosyalarına gerek yok) -- doğrudan tarayıcının/işletim
///   sisteminin kendi "yazdır/farklı kaydet" önizlemesini açar.
///
///   BİLEREK yarışma/takım bilgisi YOK (kullanıcının kesin talebi --
///   piyasaya çıkacak ürün, yarışma kimliğinden ayrı tutulur).
///
/// Tarih:  2026-09-05
library;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sensor_okuma.dart';
import '../models/tedavi_basari_analizi.dart';
import '../models/tikanma_olayi.dart';

final _renkAna = PdfColor.fromInt(0xFF0D2137);
final _renkVurgu = PdfColor.fromInt(0xFF00BFA6);
final _renkMetin = PdfColor.fromInt(0xFF1A1A1A);
final _renkSoluk = PdfColor.fromInt(0xFF6B7280);

class RaporPdfServisi {
  RaporPdfServisi._();

  static final DateFormat _uzunTarih = DateFormat('dd.MM.yyyy HH:mm');

  /// PDF belgesini oluşturur ve bytes olarak döner (kaydetme/paylaşma
  /// çağıran tarafın sorumluluğunda -- bu fonksiyon saf bir üretici).
  static Future<pw.Document> olustur({
    required Map<TikanmaTuru, int> turSayaclari,
    required Map<TedaviTuru, int> tedaviSayaclari,
    required TedaviBasariAnalizi basariAnalizi,
    required List<TikanmaOlayi> olaylar,
    required String Function(int zone) zonAdiGetir,
  }) async {
    final belge = pw.Document();
    final toplamTespit = turSayaclari.values.fold(0, (a, b) => a + b);
    final olusturmaZamani = _uzunTarih.format(DateTime.now());

    belge.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _baslikOlustur(olusturmaZamani),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _renkSoluk),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text(
            'Tıkanma Türü Dağılımı',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _renkAna,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            toplamTespit == 0
                ? 'Henüz tıkanma tespiti kaydedilmedi.'
                : 'Toplam $toplamTespit tespit — '
                      'Kimyasal: ${turSayaclari[TikanmaTuru.kimyasal] ?? 0}, '
                      'Biyolojik: ${turSayaclari[TikanmaTuru.biyolojik] ?? 0}, '
                      'Fiziksel: ${turSayaclari[TikanmaTuru.fiziksel] ?? 0}',
            style: pw.TextStyle(fontSize: 11, color: _renkMetin),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Tedavi Sayıları',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _renkAna,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _ozetKutusu(
                'Asit Dozlama',
                tedaviSayaclari[TedaviTuru.asitDozlama] ?? 0,
              ),
              pw.SizedBox(width: 10),
              _ozetKutusu(
                'Klor Enjeksiyon',
                tedaviSayaclari[TedaviTuru.klorEnjeksiyon] ?? 0,
              ),
              pw.SizedBox(width: 10),
              _ozetKutusu(
                'Yüksek Basınçlı Yıkama',
                tedaviSayaclari[TedaviTuru.yuksekBasincliYikama] ?? 0,
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Ortalama Başarı Oranı',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _renkAna,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            basariAnalizi.tamamlananSayisi == 0
                ? 'Henüz tamamlanmış tedavi yok.'
                : '%${(basariAnalizi.basariOrani * 100).toStringAsFixed(0)} '
                      '(${basariAnalizi.tamamlananSayisi} tamamlanmış tedaviden '
                      '${basariAnalizi.basariliSayisi} tanesi debiyi referans '
                      'değere döndürdü)',
            style: pw.TextStyle(fontSize: 11, color: _renkMetin),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Tespit Günlüğü (${olaylar.length} kayıt)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _renkAna,
            ),
          ),
          pw.SizedBox(height: 8),
          if (olaylar.isEmpty)
            pw.Text(
              'Seçilen filtrelere uyan kayıt yok.',
              style: pw.TextStyle(fontSize: 11, color: _renkSoluk),
            )
          else
            _gunlukTablosu(olaylar, zonAdiGetir),
        ],
      ),
    );

    return belge;
  }

  static pw.Widget _baslikOlustur(String olusturmaZamani) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'AquaGuard — Tedavi Geçmişi Raporu',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _renkAna,
              ),
            ),
            pw.Container(
              width: 14,
              height: 14,
              decoration: pw.BoxDecoration(
                color: _renkVurgu,
                shape: pw.BoxShape.circle,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Oluşturulma: $olusturmaZamani',
          style: pw.TextStyle(fontSize: 9, color: _renkSoluk),
        ),
        pw.Divider(color: _renkVurgu, thickness: 1.2, height: 16),
      ],
    );
  }

  static pw.Widget _ozetKutusu(String etiket, int sayi) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              '$sayi',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _renkAna,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              etiket,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, color: _renkSoluk),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _gunlukTablosu(
    List<TikanmaOlayi> olaylar,
    String Function(int zone) zonAdiGetir,
  ) {
    final basliklar = ['Zaman', 'Zon', 'Tür', 'Güven'];
    final satirZamani = DateFormat('dd.MM.yyyy HH:mm:ss');
    return pw.TableHelper.fromTextArray(
      headers: basliklar,
      data: [
        for (final olay in olaylar.take(300))
          [
            satirZamani.format(olay.zaman),
            zonAdiGetir(olay.zone),
            turEtiketi(olay.tur),
            '%${olay.guven.toStringAsFixed(0)}',
          ],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _renkAna),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 22,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static String dosyaAdiUret() {
    final zamanDamgasi = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'aquaguard_tedavi_raporu_$zamanDamgasi.pdf';
  }

  /// Belgeyi platformun yazdır/paylaş/kaydet önizlemesinde açar --
  /// `printing` paketi bunu web/masaüstü/mobilde platform ayrımı
  /// olmadan tek çağrıyla halleder.
  static Future<void> onizlemeyiAc(pw.Document belge) async {
    await Printing.layoutPdf(
      onLayout: (format) => belge.save(),
      name: dosyaAdiUret(),
    );
  }
}
