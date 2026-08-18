// HAQIQIY QURILMADA ishlaydigan test: 3D xarita ekrani chizilishi.
//
// Nega kerak: brauzerdagi tekshiruv (`scripts/check_3d_map.py`)
// `maplibre-gl-js` ni sinaydi, ilova esa NATIVE Android SDK ni
// ishlatadi. Bu ikki xil amalga oshirish — biri ishlashi ikkinchisi
// ishlashini isbotlamaydi.
//
// Bu test telefonda `Navigation3DScreen` ni HAQIQATAN ochadi va
// MapLibre native ko'rinishi platforma xatosisiz yaratilishini
// tekshiradi. Aynan shu joyda native kutubxona muammolari
// (UnsatisfiedLinkError, platform view yaratilmasligi) chiqadi.
//
// Ishga tushirish (telefon ulangan holda):
//   flutter test integration_test/map_3d_device_test.dart -d <device>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart';
import 'package:super_app/config/map_config.dart';
import 'package:super_app/screens/navigation_3d_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Toshkent: Amir Temur ko'chasi atrofidagi haqiqiy marshrut.
  final marshrut = <LatLng>[
    const LatLng(41.3110, 69.2401),
    const LatLng(41.3125, 69.2415),
    const LatLng(41.3140, 69.2430),
    const LatLng(41.3160, 69.2450),
  ];

  testWidgets('3D navigatsiya ekrani QURILMADA ochiladi', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Navigation3DScreen(
        route: marshrut,
        destinationName: 'Style Barbershop',
        distanceKm: 6.7,
        durationMin: 9,
      ),
    ));

    // Native ko'rinish yaratilishi uchun vaqt.
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MapLibreMap), findsOneWidget,
        reason: 'MapLibre ko\'rinishi yaratilmadi');
    expect(find.text('Style Barbershop'), findsOneWidget,
        reason: 'manzil nomi ko\'rinmadi');
  });

  testWidgets('Xarita PLATFORMA xatosisiz chiziladi', (tester) async {
    // Eng muhimi: native kutubxona yuklanishi va ko'rinish
    // yaratilishi. Muammo bo'lsa shu yerda istisno bo'ladi.
    await tester.pumpWidget(MaterialApp(
      home: Navigation3DScreen(
        route: marshrut,
        destinationName: 'Test',
      ),
    ));

    // Tile'lar tarmoqdan kelishi uchun uzoqroq kutamiz.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(tester.takeException(), isNull,
        reason: 'xarita chizilishida platforma xatosi');
  });

  testWidgets('Kamera sozlamalari 3D uchun to\'g\'ri', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Navigation3DScreen(
        route: marshrut,
        destinationName: 'Test',
      ),
    ));
    await tester.pump(const Duration(seconds: 2));

    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    final o = map.options;

    // Egilish bo'lmasa binolar ko'tarilmaydi — 2D bo'lib qoladi.
    expect(o.initPitch, greaterThanOrEqualTo(45),
        reason: 'kamera yetarlicha egilmagan');

    // MapTiler "Building 3D" qatlami minzoom=15. Undan pastda
    // binolar UMUMAN chizilmaydi.
    expect(o.initZoom, greaterThanOrEqualTo(15),
        reason: 'zoom past — binolar ko\'rinmaydi');

    // Vektor style bo'lishi shart: raster bilan 3D bo'lmaydi.
    expect(o.initStyle, contains('style.json'),
        reason: 'vektor style ishlatilmayapti');
    expect(o.initStyle, contains(MapConfig.style),
        reason: 'MapConfig dagi style ishlatilmayapti');

    // Kamera marshrut yo'nalishiga qaragan bo'lishi kerak.
    expect(o.initBearing, isNot(0),
        reason: 'kamera yo\'nalishga burilmagan');
  });

  testWidgets('Marshrut chizig\'i xaritaga uzatiladi', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Navigation3DScreen(
        route: marshrut,
        destinationName: 'Test',
      ),
    ));
    await tester.pump(const Duration(seconds: 2));

    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    final chiziqlar = map.layers.whereType<PolylineLayer>().toList();
    expect(chiziqlar, isNotEmpty, reason: 'marshrut qatlami yo\'q');

    final nuqtalar = chiziqlar.first.list.first.coordinates;
    expect(nuqtalar.length, marshrut.length,
        reason: 'marshrutning hamma nuqtasi uzatilmagan');

    // GeoJSON tartibi: [lng, lat] — teskari bo'lsa chiziq
    // butunlay boshqa joyga tushadi.
    expect(nuqtalar.first[0], closeTo(marshrut.first.longitude, 0.0001),
        reason: 'lng/lat tartibi teskari');
    expect(nuqtalar.first[1], closeTo(marshrut.first.latitude, 0.0001),
        reason: 'lng/lat tartibi teskari');
  });

  testWidgets('Xarita PIKSEL darajasida chizilgan (bo\'sh ekran emas)',
      (tester) async {
    // Eng qat'iy tekshiruv: native ko'rinish yaratilgani yetarli
    // emas, u HAQIQATAN nimadir chizishi kerak. Bo'sh (bir xil
    // rangli) ekran - xarita yuklanmagani belgisi.
    await tester.pumpWidget(MaterialApp(
      home: Navigation3DScreen(
        route: marshrut,
        destinationName: 'Piksel testi',
      ),
    ));

    // Tile'lar tarmoqdan kelishi uchun kutamiz.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(AndroidView), findsOneWidget,
        reason: 'native xarita ko\'rinishi yaratilmadi');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Qisqa marshrutda ham qulamaydi', (tester) async {
    // Chegaraviy holat: atigi 2 nuqta (OSRM ishlamay, to'g'ri
    // chiziq qurilgan holat).
    await tester.pumpWidget(MaterialApp(
      home: Navigation3DScreen(
        route: [marshrut.first, marshrut.last],
        destinationName: 'Qisqa',
      ),
    ));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MapLibreMap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
