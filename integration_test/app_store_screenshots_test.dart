// App Store Connect uchun ekran rasmlarini avtomatik oladi.
//
// Ishga tushirish (iPhone 16 Pro Max simulyatori yagona "booted" qurilma
// bo'lishi kerak — drayver `simctl io booted` ishlatadi):
//
//   xcrun simctl status_bar <UDID> override --time "9:41" \
//     --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_store_screenshots_test.dart -d <UDID>
//
// Rasmlar `screenshots/` papkasiga tushadi.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_app/app_navigator.dart';
import 'package:super_app/main.dart' as app;
import 'package:super_app/screens/all_categories_screen.dart';
import 'package:super_app/screens/calorie/calorie_home_screen.dart';
import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/screens/service_hub_screen.dart';
import 'package:super_app/screens/fitness/fitness_home_screen.dart';
import 'package:super_app/screens/home_screen.dart';

/// `pumpAndSettle` bu ilovada ishlamaydi: navigatsiya panelidagi "orb" va
/// bannerlar uzluksiz animatsiya qiladi, ya'ni kadrlar hech qachon tinchimaydi.
/// Shuning uchun belgilangan vaqt davomida qo'lda kadr chizamiz.
Future<void> kut(WidgetTester tester, {required int soniya}) async {
  for (int i = 0; i < soniya * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Ilova haqiqatan chizilguncha kutadi.
///
/// Qat'iy kutish (masalan 15 soniya) mo'rt: sovuq startda splash, til yuklash
/// va boshlang'ich API so'rovlari uzoqroq cho'zilsa, surat "Test starting..."
/// ekranini olib qoladi. Shuning uchun bosh ekran daraxtda paydo bo'lgunicha
/// kadr chizaveramiz.
Future<void> kutgunchaTayyor(WidgetTester tester, {int maxSoniya = 120}) async {
  for (int i = 0; i < maxSoniya * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (navigatorKey.currentState != null &&
        find.byType(HomeScreen).evaluate().isNotEmpty) {
      // Bosh ekran chiqdi — kontent (ob-havo, valyuta, bannerlar) to'lishi uchun.
      await kut(tester, soniya: 6);
      return;
    }
  }
  fail('Bosh ekran $maxSoniya soniyada yuklanmadi.');
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store ekran rasmlari', (WidgetTester tester) async {
    app.main();
    await kutgunchaTayyor(tester);
    await binding.takeScreenshot('01_asosiy');

    // Ekranlarni navigator orqali to'g'ridan-to'g'ri ochamiz: kartalarni bosish
    // (finder) rasm ichiga yozilgan matnlar sababli mo'rt bo'lardi.
    final List<(String, Widget)> ekranlar = <(String, Widget)>[
      ('02_xizmatlar', const AllCategoriesScreen()),
      (
        '03_sartarosh',
        ServiceHubScreen(
          kind: ServiceHubKind.sartarosh,
          accentColor: ServiceHubKind.sartarosh.accent,
        ),
      ),
      (
        '04_usta',
        ServiceHubScreen(
          kind: ServiceHubKind.usta,
          accentColor: ServiceHubKind.usta.accent,
        ),
      ),
      ('05_fitnes', const FitnessHomeScreen()),
      ('06_kaloriya', const CalorieHomeScreen()),
    ];

    for (final (String nom, Widget ekran) in ekranlar) {
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(builder: (BuildContext _) => ekran),
        ),
      );
      await kut(tester, soniya: 6);

      // Kaloriya ekrani "Kechki ovqat qildingizmi?" oynasini o'zi ochadi —
      // u xira fon ustida turadi va App Store rasmiga to'g'ri kelmaydi.
      if (find.textContaining('qildingizmi').evaluate().isNotEmpty) {
        navigatorKey.currentState!.pop();
        await kut(tester, soniya: 2);
      }
      await binding.takeScreenshot(nom);

      navigatorKey.currentState!.pop();
      await kut(tester, soniya: 3);
    }
  });
}
