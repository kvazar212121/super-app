import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:maplibre/maplibre.dart';

import '../config/map_config.dart';
import '../l10n/locale_controller.dart';

/// HAQIQIY 3D navigatsiya ekrani (vektor xarita).
///
/// Nega alohida ekran va nega MapLibre:
///   Asosiy ro'yxat/xarita ekranlari `flutter_map` da (raster tile).
///   Rasterni faqat qiyshaytirish mumkin — bu soxta 3D bo'ladi:
///   binolar tekis qolib, matnlar cho'ziladi.
///
///   Haqiqiy 3D uchun VEKTOR xarita kerak. MapTiler `streets-v2`
///   style'ida "Building 3D" (`fill-extrusion`) qatlami bor, ya'ni
///   kamera egilganda (`pitch`) binolar chinakam ko'tariladi —
///   xuddi Yandex/Google navigatsiyasidagidek.
///
/// Bu ekran faqat "Boshlash" bosilganda ochiladi, shuning uchun
/// vektor xarita trafigi doimiy emas.
class Navigation3DScreen extends StatefulWidget {
  const Navigation3DScreen({
    super.key,
    required this.route,
    required this.destinationName,
    this.accent = const Color(0xFF2563EB),
    this.distanceKm,
    this.durationMin,
  });

  /// Marshrut nuqtalari (birinchisi — foydalanuvchi joyi).
  final List<LatLng> route;

  /// Boradigan joy nomi (tepada ko'rsatiladi).
  final String destinationName;

  final Color accent;
  final double? distanceKm;
  final int? durationMin;

  @override
  State<Navigation3DScreen> createState() => _Navigation3DScreenState();
}

class _Navigation3DScreenState extends State<Navigation3DScreen> {
  MapController? _ctrl;

  /// Kamera egilishi (daraja). 60 — Androidda ruxsat etilgan maksimum.
  /// Shu burchakda binolar yaxshi ko'rinadi, ko'chalar esa hali o'qilarli.
  static const double _pitch = 60;

  /// Marshrut boshidagi yo'nalish — kamera shu tomonga qaraydi.
  double get _bearing {
    if (widget.route.length < 2) return 0;
    final a = widget.route.first;
    // Yaqin nuqta emas, biroz uzoqroq nuqtaga qaraymiz: aks holda
    // kichik burilishlar kamerani keskin aylantirib yuboradi.
    final b = widget.route.length > 3
        ? widget.route[3]
        : widget.route.last;
    return bearingDeg(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  Position get _start => Position(
        widget.route.first.longitude,
        widget.route.first.latitude,
      );

  @override
  Widget build(BuildContext context) {
    final chiziq = LineString(
      coordinates: widget.route
          .map((p) => Position(p.longitude, p.latitude))
          .toList(),
    );

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            options: MapOptions(
              // VEKTOR style — 3D binolar shu yerdan keladi.
              initStyle: MapConfig.styleUrl(),
              initCenter: _start,
              initZoom: 16.5,
              initPitch: _pitch,
              initBearing: _bearing,
              // Foydalanuvchi xohlasa 2D ga qaytara olsin.
              minPitch: 0,
              maxPitch: _pitch,
            ),
            onMapCreated: (c) => _ctrl = c,
            layers: [
              PolylineLayer(
                polylines: [chiziq],
                color: widget.accent,
                width: 8,
              ),
            ],
          ),

          // Tepada — qayerga borilayotgani va masofa.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.black87,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.destinationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (widget.distanceKm != null)
                                    '${widget.distanceKm!.toStringAsFixed(1)} km',
                                  if (widget.durationMin != null)
                                    '${widget.durationMin} ${'daqiqa'.tr}',
                                ].join(' · '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Pastda — boshlanish nuqtasiga qaytarish.
          Positioned(
            right: 16,
            bottom: 32,
            child: FloatingActionButton(
              heroTag: 'nav3dRecenter',
              backgroundColor: widget.accent,
              foregroundColor: Colors.white,
              onPressed: () => _ctrl?.animateCamera(
                center: _start,
                zoom: 16.5,
                pitch: _pitch,
                bearing: _bearing,
                nativeDuration: const Duration(milliseconds: 700),
              ),
              child: const Icon(LucideIcons.locateFixed),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikki nuqta orasidagi yo'nalish, DARAJADA (0 = shimol).
///
/// MapLibre kamerasi darajada ishlaydi, shuning uchun radian emas.
double bearingDeg(double lat1, double lng1, double lat2, double lng2) {
  const toDeg = 180 / math.pi;
  const toRad = math.pi / 180;
  final dLng = (lng2 - lng1) * toRad;
  final y = math.sin(dLng) * math.cos(lat2 * toRad);
  final x = math.cos(lat1 * toRad) * math.sin(lat2 * toRad) -
      math.sin(lat1 * toRad) * math.cos(lat2 * toRad) * math.cos(dLng);
  return (math.atan2(y, x) * toDeg + 360) % 360;
}
