import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Xaritani 3D (perspektiv) ko'rinishga keltiruvchi o'ram.
///
/// Nega shunday: `flutter_map` da Yandex/Google'dagidek haqiqiy kamera
/// egilishi (tilt) YO'Q — u tekis rasterli xarita. Shuning uchun
/// perspektiva `Matrix4` bilan beriladi: xarita widget'i uch o'lchamli
/// fazoda ekran ostiga qarab egiltiriladi. Natijada foydalanuvchi
/// "oldinga qarab ketayotgan" ko'rinishni oladi, marshrut esa uzoqqa
/// cho'zilgandek tuyuladi.
///
/// Chegara: tile'lar rasm bo'lgani uchun binolar baland bo'lib
/// ko'rinmaydi. Bu haqiqiy 3D bino emas, kamera burchagi.
class Map3DView extends StatelessWidget {
  const Map3DView({
    super.key,
    required this.child,
    required this.tilt,
    this.bearing = 0,
  });

  /// Xarita (odatda `FlutterMap`).
  final Widget child;

  /// Egilish darajasi: 0 = tekis (2D), 1 = to'liq egilgan (3D).
  /// Oraliq qiymatlar animatsiya uchun.
  final double tilt;

  /// Ko'rish yo'nalishi (radian). Marshrut yo'nalishiga qaratiladi.
  final double bearing;

  /// Maksimal egilish burchagi (radian). 55° dan oshirilsa uzoqdagi
  /// tile'lar cho'zilib, o'qib bo'lmaydigan bo'lib qoladi.
  static const double maxTiltAngle = 0.95; // ~54°

  /// Perspektiva kuchi. Kichikroq son = kuchliroq chuqurlik hissi.
  static const double _perspective = 0.0015;

  @override
  Widget build(BuildContext context) {
    if (tilt <= 0.001) {
      // 2D holat: hech qanday transform qo'llanmaydi, ya'ni odatdagi
      // xarita bilan bir xil ishlaydi (bosish, siljitish aniq).
      return child;
    }

    final angle = maxTiltAngle * tilt.clamp(0.0, 1.0);

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, _perspective) // perspektiva
      ..rotateX(angle) // ekran ostiga egish = 3D hissi
      ..rotateZ(bearing); // yo'nalish bo'yicha burish

    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        // Egilganda tepada bo'sh joy qolmasligi uchun xaritani
        // kattalashtiramiz (egilish qancha kuchli — shuncha ko'p).
        child: Transform.scale(
          scale: 1.0 + 0.45 * tilt,
          child: child,
        ),
      ),
    );
  }
}

/// Marshrutning boshlanish yo'nalishini hisoblaydi (radian).
///
/// Xarita shu burchakka burilganda foydalanuvchi doim "oldinga"
/// qaragan bo'ladi, xuddi navigatorlardagidek.
double bearingBetween(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLng = _rad(lng2 - lng1);
  final y = math.sin(dLng) * math.cos(_rad(lat2));
  final x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
      math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(dLng);
  return math.atan2(y, x);
}

double _rad(double deg) => deg * math.pi / 180.0;
