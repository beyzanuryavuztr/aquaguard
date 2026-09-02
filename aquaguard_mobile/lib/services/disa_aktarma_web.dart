/// AquaGuard - CSV Kaydetme (Web -- tarayici indirmesi)
/// =========================================================
///
/// Amac:
///   Web'de gercek bir dosya sistemi yoktur; CSV'yi bir Blob'a paketleyip
///   tarayicinin standart "dosya indir" akisini tetikleriz (gorunmez bir
///   <a download> etiketine tiklatarak).
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

// Bu dosya SADECE Web derlemesinde secilir (bkz. disa_aktarma_factory.dart
// kosullu ithalati) -- "web-only kutuphane kullanma" uyarisi burada
// kasitlidir, mqtt_istemci_web.dart'taki ayni desenle tutarlidir.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'disa_aktarma_servisi.dart';

/// CSV indirmesini baslatir, kullaniciya gosterilecek dosya adini doner
/// (web'de gercek bir "yol" kavrami yoktur).
Future<String> csvKaydet(String dosyaAdi, String icerik) async {
  final bayt = utf8.encode(DisaAktarmaServisi.utf8Bom + icerik);
  final blob = html.Blob([bayt], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final baglanti = html.AnchorElement(href: url)
    ..setAttribute('download', dosyaAdi)
    ..style.display = 'none';
  html.document.body?.append(baglanti);
  baglanti.click();
  baglanti.remove();
  html.Url.revokeObjectUrl(url);
  return dosyaAdi;
}
