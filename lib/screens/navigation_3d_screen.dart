import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:maplibre/maplibre.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Marshrutni tashqi navigatorda ochadi.
  ///
  /// Avval ilovaning o'zini (`yandexnavi://`, `google.navigation:`)
  /// sinaymiz; o'rnatilmagan bo'lsa brauzer versiyasiga tushamiz —
  /// shunda tugma HAR DOIM ishlaydi.
  Future<void> _tashqiNavigator({required bool google}) async {
    final boshi = widget.route.first;
    final oxiri = widget.route.length > 1 ? widget.route.last : boshi;

    final urinishlar = google
        ? [
            Uri.parse('google.navigation:q=${oxiri.latitude},'
                '${oxiri.longitude}&mode=d'),
            Uri.parse('https://www.google.com/maps/dir/?api=1'
                '&origin=${boshi.latitude},${boshi.longitude}'
                '&destination=${oxiri.latitude},${oxiri.longitude}'
                '&travelmode=driving'),
          ]
        : [
            Uri.parse('yandexnavi://build_route_on_map'
                '?lat_to=${oxiri.latitude}&lon_to=${oxiri.longitude}'
                '&lat_from=${boshi.latitude}&lon_from=${boshi.longitude}'),
            Uri.parse('https://yandex.uz/maps/?rtext='
                '${boshi.latitude},${boshi.longitude}~'
                '${oxiri.latitude},${oxiri.longitude}&rtt=auto'),
          ];

    for (final uri in urinishlar) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {
        // Keyingi variantga o'tamiz (ilova o'rnatilmagan bo'lishi mumkin).
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xaritani ochib bo\'lmadi'.tr)),
    );
  }

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
            children: [
              // NAVIGATOR KURSORI — uchli strelka.
              //
              // Ilgari xaritada foydalanuvchi qayerdaligi UMUMAN
              // ko'rinmasdi: faqat chiziq bor edi va odam o'zini
              // yo'qotardi. `WidgetLayer` oddiy Flutter widgetini
              // xarita ustiga, ANIQ koordinataga qo'yadi.
              WidgetLayer(
                markers: [
                  Marker(
                    point: _start,
                    size: const Size(72, 72),
                    // `flat` — kursor xarita bilan birga yotadi
                    // (3D ko'rinishda tik turmaydi).
                    flat: true,
                    // `rotate` — xarita burilganda kursor ham buriladi,
                    // ya'ni u DOIM yurish yo'nalishini ko'rsatadi.
                    rotate: true,
                    child: _NavigatorKursori(rang: widget.accent),
                  ),
                  // Manzil belgisi — qayerga borilayotgani.
                  if (widget.route.length > 1)
                    Marker(
                      point: Position(
                        widget.route.last.longitude,
                        widget.route.last.latitude,
                      ),
                      size: const Size(40, 48),
                      alignment: Alignment.bottomCenter,
                      child: _ManzilBelgisi(rang: widget.accent),
                    ),
                ],
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
            bottom: 110,
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

          // TASHQI NAVIGATOR — Google yoki Yandex.
          //
          // Bizning 3D ko'rinish yo'lni ko'rsatadi, lekin ovozli
          // yo'riqnoma bermaydi. Haydovchi haqiqiy navigatsiyani
          // xohlasa shu yerdan o'tadi (ilova o'rnatilmagan bo'lsa
          // brauzerda ochiladi).
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: _TashqiTugma(
                      matn: 'Google Xarita',
                      rang: const Color(0xFF1A73E8),
                      onTap: () => _tashqiNavigator(google: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TashqiTugma(
                      matn: 'Yandex Navi',
                      rang: const Color(0xFFFC3F1D),
                      onTap: () => _tashqiNavigator(google: false),
                    ),
                  ),
                ],
              ),
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


/// Navigator kursori — uchli strelka.
///
/// Yandex/Google navigatsiyasidagi kabi: konus shaklidagi "nur"
/// yo'nalishni ko'rsatadi, o'rtadagi doira esa aniq joyni.
/// Ilgari xaritada foydalanuvchi belgisi UMUMAN yo'q edi.
class _NavigatorKursori extends StatelessWidget {
  const _NavigatorKursori({required this.rang});

  final Color rang;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(painter: _KursorChizuvchi(rang)),
    );
  }
}

class _KursorChizuvchi extends CustomPainter {
  const _KursorChizuvchi(this.rang);

  final Color rang;

  @override
  void paint(Canvas canvas, Size size) {
    final markaz = Offset(size.width / 2, size.height / 2);

    // 1) Yo'nalish nuri (konus) — qayerga qarab ketayotgani.
    final nur = Paint()
      ..shader = RadialGradient(
        colors: [rang.withValues(alpha: 0.45), rang.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: markaz, radius: size.width / 2));
    canvas.drawArc(
      Rect.fromCircle(center: markaz, radius: size.width / 2),
      -math.pi / 2 - 0.6,  // yuqoriga qarab, 70 gradus keng
      1.2,
      true,
      nur,
    );

    // 2) Uchli strelka. Telefonda yaxshi ko'rinishi uchun
    // yetarlicha katta (kichik strelka 3D fon ustida yo'qoladi).
    final ucli = ui.Path()
      ..moveTo(markaz.dx, markaz.dy - 22)          // uchi (oldinga)
      ..lineTo(markaz.dx - 15, markaz.dy + 17)     // chap orqa
      ..lineTo(markaz.dx, markaz.dy + 8)           // o'rta o'yiq
      ..lineTo(markaz.dx + 15, markaz.dy + 17)     // o'ng orqa
      ..close();

    // Oq hoshiya — har qanday xarita rangida ko'rinsin.
    canvas.drawPath(
      ucli,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(ucli, Paint()..color = rang);
  }

  @override
  bool shouldRepaint(_KursorChizuvchi eski) => eski.rang != rang;
}

/// Manzil belgisi — marshrut oxiri.
class _ManzilBelgisi extends StatelessWidget {
  const _ManzilBelgisi({required this.rang});

  final Color rang;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 48,
      child: Icon(Icons.location_on, color: rang, size: 44,
          shadows: const [Shadow(color: Colors.white, blurRadius: 6)]),
    );
  }
}

/// Tashqi navigatorni ochish tugmasi (Google / Yandex).
class _TashqiTugma extends StatelessWidget {
  const _TashqiTugma({
    required this.matn,
    required this.rang,
    required this.onTap,
  });

  final String matn;
  final Color rang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: rang,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: const Icon(LucideIcons.navigation, size: 18),
        label: Text(
          matn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
