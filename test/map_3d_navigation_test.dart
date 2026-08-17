// Xarita 3D (navigatsiya) ko'rinishi.
//
// Foydalanuvchi talabi: "xarita maydonida xaritani 3d ko'rish
// imkoniyati... qayerNIdir bosganda boshlash belgisi chiqib 3d
// xolatga kelib anashu tomonga chizma chizilishi kerak".
//
// Matematik qism (burchak hisobi, transform) haqiqiy widget bilan
// sinaladi; ekran mantiqi manba kodi qoidalari bilan qo'riqlanadi.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/widgets/map_3d_view.dart';

void main() {
  group('Yo\'nalish hisobi (bearing)', () {
    // Toshkent markazi
    const lat = 41.3110, lng = 69.2401;

    test('Shimolga yurish ~0 radian', () {
      final b = bearingBetween(lat, lng, lat + 0.05, lng);
      expect(b.abs(), lessThan(0.05), reason: 'shimol = 0');
    });

    test('Sharqqa yurish ~90 daraja', () {
      final b = bearingBetween(lat, lng, lat, lng + 0.05);
      expect(b, closeTo(math.pi / 2, 0.05));
    });

    test('Janubga yurish ~180 daraja', () {
      final b = bearingBetween(lat, lng, lat - 0.05, lng);
      expect(b.abs(), closeTo(math.pi, 0.05));
    });

    test('G\'arbga yurish ~-90 daraja', () {
      final b = bearingBetween(lat, lng, lat, lng - 0.05);
      expect(b, closeTo(-math.pi / 2, 0.05));
    });

    test('Bir joyning o\'ziga — qulamaydi', () {
      final b = bearingBetween(lat, lng, lat, lng);
      expect(b.isNaN, isFalse);
      expect(b.isFinite, isTrue);
    });

    test('Haqiqiy marshrut: Chilonzordan Yunusobodga (shimoli-sharq)', () {
      // Chilonzor 41.2756/69.2035 -> Yunusobod 41.3670/69.2870
      final b = bearingBetween(41.2756, 69.2035, 41.3670, 69.2870);
      // Shimoli-sharq = 0 va 90 daraja orasida
      expect(b, greaterThan(0));
      expect(b, lessThan(math.pi / 2));
    });
  });

  group('Map3DView', () {
    testWidgets('tilt=0 da xarita TEGILMAYDI (2D holat)', (tester) async {
      // Muhim: 2D da transform qo'llanmasligi kerak, aks holda
      // bosish nuqtalari siljib, foydalanuvchi noto'g'ri joyni bosadi.
      const kalit = Key('xarita');
      await tester.pumpWidget(const MaterialApp(
        home: Map3DView(tilt: 0, child: SizedBox(key: kalit, width: 100)),
      ));
      expect(find.byKey(kalit), findsOneWidget);
      expect(find.byType(Transform), findsNothing,
          reason: '2D holatda hech qanday transform bo\'lmasin');
    });

    testWidgets('tilt>0 da perspektiv transform qo\'llanadi', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Map3DView(tilt: 1, child: SizedBox(width: 100)),
      ));
      expect(find.byType(Transform), findsWidgets,
          reason: '3D holatda transform bo\'lishi kerak');
      expect(find.byType(ClipRect), findsWidgets,
          reason: 'egilgan xarita chegaradan chiqmasligi kerak');
    });

    testWidgets('Bola widget har ikki holatda ham ko\'rinadi', (tester) async {
      for (final t in [0.0, 0.5, 1.0]) {
        await tester.pumpWidget(MaterialApp(
          home: Map3DView(tilt: t, child: const Text('xarita')),
        ));
        expect(find.text('xarita'), findsOneWidget,
            reason: 'tilt=$t da xarita yo\'qolib qoldi');
      }
    });

    test('Egilish burchagi o\'qilarli chegarada', () {
      // 60 darajadan oshsa uzoqdagi tile'lar cho'zilib ketadi.
      expect(Map3DView.maxTiltAngle, lessThan(1.05));
      expect(Map3DView.maxTiltAngle, greaterThan(0.5),
          reason: 'juda kichik burchakda 3D hissi bo\'lmaydi');
    });
  });

  group('Xarita ekrani: navigatsiya oqimi', () {
    late String src;

    setUpAll(() {
      src = File('lib/screens/service_hub/service_map_screen.dart')
          .readAsStringSync();
    });

    test('Xarita 3D o\'ramga solingan', () {
      expect(src, contains('Map3DView'));
      expect(src, contains('_tiltCtrl'),
          reason: '2D-3D o\'tish silliq bo\'lishi kerak');
    });

    test('"Boshlash" tugmasi joy tanlanganda chiqadi', () {
      expect(src, contains('_startNavButton'));
      expect(src, contains('if (_selected != null && _route.length >= 2)'),
          reason: 'tugma faqat marshrut tayyor bo\'lganda chiqsin');
    });

    test('Boshlash 3D rejimni yoqadi va yaqinlashtiradi', () {
      final start = src.indexOf('void _startNavigation');
      expect(start, greaterThan(-1));
      final body = src.substring(start, start + 1200);
      expect(body, contains('_navMode = true'));
      expect(body, contains('_tiltCtrl.forward()'));
      expect(body, contains('bearingBetween'),
          reason: 'xarita marshrut tomoniga burilishi kerak');
      expect(body, contains('_map.move'),
          reason: 'boshlanish nuqtasiga yaqinlashishi kerak');
    });

    test('Navigatsiyadan chiqish mumkin', () {
      expect(src, contains('_stopNavigation'));
      expect(src, contains('_stopNavButton'));
      final start = src.indexOf('void _stopNavigation');
      final body = src.substring(start, start + 400);
      expect(body, contains('_tiltCtrl.reverse()'));
    });

    test('Navigatsiyada tasodifiy bosish marshrutni o\'chirmaydi', () {
      final start = src.indexOf('void _clearSelection');
      final body = src.substring(start, start + 600);
      expect(body, contains('if (_navMode) return;'),
          reason: 'aks holda foydalanuvchi marshrutni yo\'qotadi');
    });

    test('Animatsiya kontrolleri bo\'shatiladi (xotira sizmasin)', () {
      final start = src.indexOf('void dispose()');
      final body = src.substring(start, start + 300);
      expect(body, contains('_tiltCtrl.dispose()'));
    });

    test('Ikkinchi xarita widget\'ida ham 3D bor', () {
      // enhanced_service_map ham xarita ekrani — u ham 3D bo'lishi
      // kerak, aks holda foydalanuvchi bir joyda 3D ko'rib, boshqa
      // joyda ko'rmaydi.
      final w = File('lib/widgets/enhanced_service_map.dart')
          .readAsStringSync();
      expect(w, contains('Map3DView'));
      expect(w, contains('_startNavigation'));
      expect(w, contains("'Boshlash'.tr"));
      expect(w, contains('_tiltCtrl.dispose()'),
          reason: 'xotira sizmasin');
      final clear = w.indexOf('void _clearRoute');
      expect(w.substring(clear, clear + 300), contains('if (_navMode) return;'));
    });

    test('Yangi matnlar ruschaga tarjima qilingan', () {
      final tr = File('lib/l10n/translations.dart').readAsStringSync();
      for (final k in ["'Boshlash':", "'Yakunlash':", "'Rasm tayyor':"]) {
        expect(tr, contains(k), reason: '$k tarjimasi yo\'q');
      }
    });

    test('Marshrut chizig\'i saqlanib qolgan', () {
      // 3D qo'shilganda mavjud marshrut chizmasi buzilmasligi kerak.
      expect(src, contains('PolylineLayer'));
      expect(src, contains('points: _route'));
    });
  });
}
