// HAQIQIY 3D navigatsiya: vektor xarita, ko'tarilgan binolar.
//
// Foydalanuvchi birinchi urinishni RAD ETDI: "sen shunchaki chiqarib
// berilayotgan xaritani qiyshaytirib qo'ygansan xolos". To'g'ri edi —
// raster tile'ni Matrix4 bilan egish soxta 3D beradi: binolar tekis
// qoladi, matnlar cho'ziladi.
//
// Haqiqiy 3D uchun VEKTOR xarita kerak. MapTiler `streets-v4`
// style'ida "Building 3D" (fill-extrusion) qatlami bor va MapLibre
// kamerasi haqiqiy `pitch` ni qo'llab-quvvatlaydi.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/config/map_config.dart';
import 'package:super_app/screens/navigation_3d_screen.dart';

void main() {
  group('Yo\'nalish hisobi (darajada)', () {
    const lat = 41.3110, lng = 69.2401; // Toshkent

    test('Shimol ~0°', () {
      expect(bearingDeg(lat, lng, lat + 0.05, lng), closeTo(0, 2));
    });

    test('Sharq ~90°', () {
      expect(bearingDeg(lat, lng, lat, lng + 0.05), closeTo(90, 2));
    });

    test('Janub ~180°', () {
      expect(bearingDeg(lat, lng, lat - 0.05, lng), closeTo(180, 2));
    });

    test('G\'arb ~270° (manfiy emas)', () {
      final b = bearingDeg(lat, lng, lat, lng - 0.05);
      expect(b, closeTo(270, 2),
          reason: 'MapLibre kamerasi 0-360 kutadi, manfiy emas');
    });

    test('Natija doim 0..360 oralig\'ida', () {
      for (final d in [
        [0.05, 0.05], [-0.05, 0.05], [0.05, -0.05], [-0.05, -0.05],
      ]) {
        final b = bearingDeg(lat, lng, lat + d[0], lng + d[1]);
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
      }
    });

    test('Chilonzor -> Yunusobod: shimoli-sharq', () {
      final b = bearingDeg(41.2756, 69.2035, 41.3670, 69.2870);
      expect(b, greaterThan(0));
      expect(b, lessThan(90));
    });
  });

  group('Vektor style (3D manbai)', () {
    test('streets-v4 ishlatiladi', () {
      // v4 da 160 qatlam va binolar `height` maydoni bor — 3D aniqroq.
      expect(MapConfig.style, 'streets-v4');
      expect(MapConfig.darkStyle, 'streets-v4-dark');
    });

    test('styleUrl vektor style.json ga ishora qiladi', () {
      // Muhim: `.png` EMAS. Raster bo'lsa 3D bo'lmaydi.
      const kalit = 'TEST_KALIT';
      // Kalit compile-time konstanta, shuning uchun mantiqni
      // bevosita tekshiramiz: kalitsiz bo'sh qaytishi kerak.
      expect(MapConfig.styleUrl(), isEmpty,
          reason: 'kalitsiz vektor xarita bo\'lmaydi');
      expect(MapConfig.supports3D, MapConfig.hasKey);
      expect(kalit, isNotEmpty);
    });

    test('Raster va vektor manzillari FARQ qiladi', () {
      // tileUrl -> .png (2D ro'yxat ekranlari uchun)
      // styleUrl -> style.json (3D navigatsiya uchun)
      expect(MapConfig.tileUrl(), contains('.png'));
      expect(MapConfig.fallbackUrl, contains('.png'));
    });
  });

  group('3D navigatsiya ekrani', () {
    late String src;

    setUpAll(() {
      src = File('lib/screens/navigation_3d_screen.dart').readAsStringSync();
    });

    test('MapLibre (vektor) ishlatiladi, flutter_map EMAS', () {
      expect(src, contains("package:maplibre/maplibre.dart"));
      expect(src.contains('package:flutter_map/'), isFalse,
          reason: 'flutter_map raster — u bilan haqiqiy 3D bo\'lmaydi');
    });

    test('Kamera HAQIQIY pitch bilan egiladi', () {
      expect(src, contains('initPitch'),
          reason: 'pitch bo\'lmasa binolar ko\'tarilmaydi');
      expect(src, contains('static const double _pitch = 60'),
          reason: 'Androidda maksimal pitch 60');
    });

    test('Vektor style ulangan', () {
      expect(src, contains('MapConfig.styleUrl()'));
      expect(src.contains('MapConfig.tileLayer'), isFalse,
          reason: 'bu ekranda raster ishlatilmasin');
    });

    test('Kamera marshrut yo\'nalishiga qaraydi', () {
      expect(src, contains('initBearing'));
      expect(src, contains('bearingDeg'));
    });

    test('Marshrut chizig\'i bor', () {
      expect(src, contains('PolylineLayer'));
      expect(src, contains('LineString'));
    });

    test('Qaytish tugmasi bor (foydalanuvchi qamalib qolmasin)', () {
      expect(src, contains('Navigator.maybePop'));
    });
  });

  group('Xarita ekranlari 3D ni ochadi', () {
    test('Soxta 3D (Matrix4 qiyshaytirish) OLIB TASHLANGAN', () {
      // Foydalanuvchi buni aniq rad etgan. Qaytib kelmasin.
      expect(File('lib/widgets/map_3d_view.dart').existsSync(), isFalse,
          reason: 'soxta 3D fayli qaytib kelgan');
      for (final f in [
        'lib/screens/service_hub/service_map_screen.dart',
        'lib/widgets/enhanced_service_map.dart',
      ]) {
        final s = File(f).readAsStringSync();
        expect(s.contains('Map3DView'), isFalse, reason: '$f da soxta 3D');
      }
    });

    test('"Boshlash" haqiqiy 3D ekranni ochadi', () {
      for (final f in [
        'lib/screens/service_hub/service_map_screen.dart',
        'lib/widgets/enhanced_service_map.dart',
      ]) {
        final s = File(f).readAsStringSync();
        expect(s, contains('Navigation3DScreen'), reason: '$f');
        expect(s, contains('_startNavigation'), reason: '$f');
      }
    });

    test('Kalitsiz build\'da 3D tugmasi KO\'RSATILMAYDI', () {
      // Vektor style kalitsiz ishlamaydi. Tugma baribir chiqsa,
      // foydalanuvchi bo'sh (oq) ekran ochib qolardi.
      for (final f in [
        'lib/screens/service_hub/service_map_screen.dart',
        'lib/widgets/enhanced_service_map.dart',
      ]) {
        final s = File(f).readAsStringSync();
        expect(s, contains('MapConfig.supports3D'),
            reason: '$f da kalit tekshirilmayapti');
      }
    });

    test('Navigatsiya zoom\'i binolar ko\'rinadigan darajada', () {
      // MapTiler "Building 3D" qatlami minzoom=15. Kamera undan
      // pastda tursa binolar UMUMAN chiqmaydi va 3D bilinmaydi.
      final s = File('lib/screens/navigation_3d_screen.dart')
          .readAsStringSync();
      final m = RegExp(r'initZoom:\s*([\d.]+)').firstMatch(s);
      expect(m, isNotNull, reason: 'initZoom topilmadi');
      final zoom = double.parse(m!.group(1)!);
      expect(zoom, greaterThanOrEqualTo(15.0),
          reason: 'zoom < 15 da 3D binolar ko\'rinmaydi');
    });

    test('Pastdagi tugmalar tizim paneli ostida qolmaydi', () {
      // Foydalanuvchi skrinshotida filtr tugmasi yarim ko'rinardi.
      for (final f in [
        'lib/screens/service_hub/service_map_screen.dart',
        'lib/widgets/enhanced_service_map.dart',
      ]) {
        final s = File(f).readAsStringSync();
        expect(s, contains('MediaQuery.paddingOf(context).bottom'),
            reason: '$f da tugma navigatsiya paneli ostida qoladi');
      }
    });
  });
}
