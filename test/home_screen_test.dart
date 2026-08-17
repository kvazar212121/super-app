// Bosh sahifa haqiqatan render bo'ladimi va kerakli bo'limlar bormi.
//
// Telefon USB dan uzilib qolgani uchun ekranni ko'zim bilan ko'ra
// olmadim. Bu test o'sha bo'shliqni qisman yopadi: Flutter'ning
// haqiqiy render mexanizmi bilan bosh sahifa qurilib, ichida
// aksiya banneri va usta paneliga kirish joyi borligi tekshiriladi.
//
// Bu "fayl ichida matn bormi" degan tekshiruv EMAS — vidjet daraxti
// haqiqatan quriladi, ya'ni kompilyatsiya, provider'lar va build
// metodlari ishlashi shart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/home_screen.dart';
import 'package:super_app/widgets/campaign_banner.dart';
import 'package:super_app/widgets/provider_portal_entry.dart';

Widget _wrap(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('Bosh sahifa xatosiz quriladi', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    // Qurilish paytida istisno bo'lsa test shu yerda yiqiladi
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('Bosh sahifada aksiya banneri joyi bor',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump();

    // Banner vidjeti daraxtda bo'lishi kerak. (Aksiya yo'q bo'lsa u
    // o'zini yashiradi, lekin vidjetning O'ZI joyida turishi shart —
    // aks holda aksiya e'lon qilinganda ham hech narsa chiqmaydi.)
    expect(
      find.byType(CampaignBanner),
      findsOneWidget,
      reason: 'Aksiya e\'lon qilinganda banner shu joyda chiqadi',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('Bosh sahifada usta paneliga kirish joyi bor',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump();

    // Usta shu yerdan o'z paneliga (va undagi "E'lonlar" tabiga) kiradi
    expect(find.byType(ProviderPortalEntry), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });
}
