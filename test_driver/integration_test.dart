// App Store ekran rasmlari uchun drayver (Mac tomonida ishlaydi).
//
// MUHIM: `onScreenshot` test TUGAGANDAN KEYIN, hamma suratlar uchun ketma-ket
// chaqiriladi. Ya'ni bu yerda `simctl` bilan surat olib bo'lmaydi — u faqat
// oxirgi ekranni 5 marta suratga olardi. Shu sababli `takeScreenshot` o'zi
// (iOS'da ilova oynalarini to'liq qurilma o'lchamida chizib) qaytargan
// baytlarni yozamiz — ular kerakli lahzada olingan bo'ladi.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String nom,
      List<int> baytlar, [
      Map<String, Object?>? args,
    ]) async {
      final File fayl = File('screenshots/$nom.png');
      await fayl.parent.create(recursive: true);
      await fayl.writeAsBytes(baytlar);
      stdout.writeln('✓ ${fayl.path} (${baytlar.length} bayt)');
      return true;
    },
  );
}
