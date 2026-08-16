import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/main.dart';
import 'package:super_app/screens/main_screen.dart';
import 'package:super_app/widgets/glass/glass_bottom_bar.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Super App - bosh sahifa yuklanadi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // MaterialApp mavjudligini tekshirish
    expect(find.byType(MaterialApp), findsOneWidget);

    // MainScreen yuklanganligini tekshirish
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Super App - pastki navigatsiya ko\'rsatiladi',
      (WidgetTester tester) async {
    // Splash ekranida cheksiz animatsiya bor, shuning uchun MyApp emas,
    // to'g'ridan-to'g'ri MainScreen sinaladi (pumpAndSettle qotib qolmasin).
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(GlassBottomBar), findsOneWidget);

    // Ekran ochilishida ketgan tarmoq so'rovlarining taymerlari tugashi uchun
    // (aks holda test tugagach "Timer is still pending" xatosi chiqadi).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 60));
  });
}
