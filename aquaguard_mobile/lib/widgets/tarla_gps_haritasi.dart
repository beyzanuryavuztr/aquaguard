/// AquaGuard - Tarla GPS Haritasi
/// ===================================
///
/// Amac:
///   Bir tarlanin GERCEK GPS konumunu (enlem/boylam) OpenStreetMap
///   uzerinde gosterir. **BILEREK FARKLI ISIM/DOSYA**: mevcut
///   `widgets/tarla_haritasi.dart` (`TarlaHaritasi`) sematik bir "kutu
///   grid" plan gorunumudur (gercek koordinat KULLANMAZ, sadece zonlari
///   renkli kutucuklar olarak dizer) -- bu widget ise GERCEK harita/
///   koordinat gosterir. Ikisi TAMAMEN FARKLI seyler, isim çakışması
///   proje daha once (Bakim Takvimi/Sensor Kalibrasyonu basliklarinda)
///   kafa karisikligina yol acmisti, o yuzden bilinçli ayristirma.
///
///   flutter_map + OpenStreetMap secildi -- API KEY GEREKTIRMEZ (Google
///   Maps'in aksine), projenin "guvenilmez ag/API-key bagimliligindan
///   kacin" ilkesiyle tutarli (bkz. proje hafizasi: hava durumu/Google
///   Maps ozelliklerinin daha once TAM da bu gerekceyle reddedilmesi).
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TarlaGpsHaritasi extends StatelessWidget {
  final double enlem;
  final double boylam;
  final String? etiket;
  final double yukseklik;

  const TarlaGpsHaritasi({
    super.key,
    required this.enlem,
    required this.boylam,
    this.etiket,
    this.yukseklik = 160,
  });

  @override
  Widget build(BuildContext context) {
    final konum = LatLng(enlem, boylam);
    final vurguRenk = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: yukseklik,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: konum,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.aquaguard.aquaguard_mobile',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: konum,
                  width: 36,
                  height: 36,
                  child: Icon(Icons.location_pin, color: vurguRenk, size: 36),
                ),
              ],
            ),
            const _OsmAtfi(),
          ],
        ),
      ),
    );
  }
}

/// OpenStreetMap kullanim sartlarinin GEREKTIRDIGI atif (attribution) --
/// harita gosteren her uygulamanin kaynagini belirtmesi ZORUNLUDUR.
class _OsmAtfi extends StatelessWidget {
  const _OsmAtfi();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              '© OpenStreetMap katkıda bulunanları',
              style: TextStyle(fontSize: 9, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
