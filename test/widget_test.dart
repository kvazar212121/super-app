import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:super_app/main.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/main_screen.dart';
import 'package:super_app/widgets/glass/glass_bottom_bar.dart';

void main() {
  testWidgets('Super App - ilova ishga tushadi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Asosiy ekranda GlassBottomBar va 5 ta tab bor', (tester) async {
    // MyApp splash ekrandan boshlanadi va u tarmoq javobini kutadi, shuning
    // uchun test muhitida MainScreen'ni to'g'ridan-to'g'ri tekshiramiz.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pump();

    // Ilova Material BottomNavigationBar emas, o'zining GlassBottomBar'ini
    // ishlatadi.
    expect(find.byType(GlassBottomBar), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    // 5 ta tab: Asosiy, Xizmatlar, AiHub (markaziy orb), Aloqa, Buyurtmalar.
    final bar = tester.widget<GlassBottomBar>(find.byType(GlassBottomBar));
    expect(bar.items.length, 5);
    expect(bar.centerIndex, 2, reason: 'AiHub markaziy orb');

    // MainScreen fonda qo'ng'iroq WebSocket'ini ulaydi va qayta ulanish
    // taymerini qoldiradi. Testdan chiqishdan oldin uni bo'shatamiz.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  });
}
