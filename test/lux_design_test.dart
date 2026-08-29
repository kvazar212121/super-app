import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// `RenderRepaintBoundary` uchun: material.dart uni qayta eksport qilmaydi.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:super_app/l10n/locale_controller.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/all_categories_screen.dart';
import 'package:super_app/screens/home_screen.dart';
import 'package:super_app/screens/orders_screen.dart';
import 'package:super_app/screens/profile_screen.dart';
import 'package:super_app/theme/app_theme.dart';
import 'package:super_app/theme/lux_tokens.dart';

/// "Qora + oltin" dizayn migratsiyasining HAQIQIY natijasini tekshiradi.
///
/// NEGA BU TEST KERAK: `flutter analyze` faqat kod to'g'riligini ko'radi.
/// Rang almashtirishdan keyin kod bexato kompilyatsiya bo'lishi, lekin
/// ekran OQ qolishi yoki matn fon bilan qo'shilib ketishi mumkin. Bu test
/// ekranni HAQIQATAN chizadi va piksellarni o'lchaydi.
///
/// Tekshiriladigan talablar (foydalanuvchi so'ragan natijaga bog'langan):
///   T1. Sahifa foni QORA (oq emas) — "butun tizim yangi dizaynda".
///   T2. Ekranda oq/ochiq FON yuzasi yo'q (eski oq kartalar qolmagan).
///   T3. Matn fon bilan yetarli KONTRASTGA ega (o'qib bo'ladi).
///   T4. Kundalik kartalarida ikon MATNDAN katta (oxirgi so'rov).
///   T5. Hech bir ekranda overflow (RenderFlex) xatosi yo'q.
void main() {
  /// Ekranni RepaintBoundary bilan o'rab, uni rasmga aylantiradi.
  ///
  /// NEGA RepaintBoundary: `Layer.toImage` bu Flutter versiyasida ochiq
  /// emas. `RenderRepaintBoundary.toImage()` esa rasman qo'llab-quvvatlanadi
  /// va aynan shu vidjet daraxti chizilgan piksellarni beradi.
  final rasmKaliti = GlobalKey();

  Widget ilova(Widget bola) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // main.dart dagi bilan bir xil: ilova doim dark.
        themeMode: ThemeMode.dark,
        locale: LocaleController.instance.locale,
        home: RepaintBoundary(
          key: rasmKaliti,
          child: Scaffold(body: bola),
        ),
      ),
    );
  }

  /// Rangning yorug'ligi (0 = qora, 1 = oq). WCAG nisbiy yorug'lik.
  double yoruglik(Color c) {
    double kanal(double v) {
      v = v / 255.0;
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * kanal(c.r * 255) +
        0.7152 * kanal(c.g * 255) +
        0.0722 * kanal(c.b * 255);
  }

  /// Renderlangan ekranning piksellarini o'qiydi.
  Future<List<Color>> piksellar(WidgetTester tester) async {
    final chegara = rasmKaliti.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final rasm = await chegara.toImage();
    final baytlar = await rasm.toByteData(format: ui.ImageByteFormat.rawRgba);
    final n = baytlar!.lengthInBytes ~/ 4;
    return [
      for (int i = 0; i < n; i++)
        Color.fromARGB(
          baytlar.getUint8(i * 4 + 3),
          baytlar.getUint8(i * 4),
          baytlar.getUint8(i * 4 + 1),
          baytlar.getUint8(i * 4 + 2),
        ),
    ];
  }

  /// Ochiq (oq-ga yaqin) piksellar ULUSHI. Qora dizaynda kichik bo'lishi
  /// kerak: faqat matn va ayrim rasmlar oq bo'ladi, katta yuzalar emas.
  double ochUlush(List<Color> px) {
    if (px.isEmpty) return 0;
    final och = px.where((c) => yoruglik(c) > 0.55).length;
    return och / px.length;
  }

  group('T1+T2: ekran foni qora, oq yuzalar yo\'q', () {
    /// Har ekran uchun: fon qora va ochiq piksellar ulushi kichik.
    ///
    /// 25% chegara: matn, ikon va promo rasmlari ochiq bo'lishi mumkin,
    /// lekin butun boshli oq karta/panel bo'lsa ulush undan oshadi.
    ///
    /// DIQQAT: `pumpAndSettle` ISHLATILMAYDI. Bu ekranlarda cheksiz
    /// animatsiya (AiHub orbi, karusel) va tarmoq so'rovlari bor —
    /// `pumpAndSettle` hech qachon tugamaydi va test osilib qoladi.
    /// Bir marta `pump()` yetarli: birinchi kadr chizilgach ranglarni
    /// o'lchash mumkin.
    Future<void> tekshir(
      WidgetTester tester,
      String nom,
      Widget ekran, {
      double chegara = 0.25,
    }) async {
      await tester.pumpWidget(ilova(ekran));
      await tester.pump();

      final px = await piksellar(tester);
      final ulush = ochUlush(px);

      // Daraxtni bo'shatamiz: aks holda ochiq taymer/so'rovlar testni
      // tugatishga qo'ymaydi.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));

      expect(
        ulush,
        lessThan(chegara),
        reason:
            '$nom: ekranning ${(ulush * 100).toStringAsFixed(1)}% i OCHIQ '
            'rangda. Qora dizaynda bu ${(chegara * 100).round()}% dan '
            'kam bo\'lishi kerak — oq karta yoki panel qolgan bo\'lishi mumkin.',
      );
    }

    testWidgets('Bosh sahifa', (t) async {
      await tekshir(t, 'HomeScreen', const HomeScreen());
    });

    testWidgets('Barcha xizmatlar', (t) async {
      // Xizmat kartalarida OQ fonli 3D rasmlar bor (bu normal), shuning
      // uchun chegara yuqoriroq. Muhimi: SAHIFA foni qora bo'lsin.
      await tekshir(
        t,
        'AllCategoriesScreen',
        const AllCategoriesScreen(),
        chegara: 0.45,
      );
    });

    testWidgets('Buyurtmalar', (t) async {
      await tekshir(t, 'OrdersScreen', const OrdersScreen(embedded: true));
    });

    testWidgets('Profil', (t) async {
      await tekshir(t, 'ProfileScreen', const ProfileScreen());
    });
  });

  group('T1: tema qiymatlari lux palitrasiga bog\'langan', () {
    test('Dark tema foni LuxTokens.bg', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, LuxTokens.bg);
    });

    test('Dark tema urg\'usi OLTIN (ko\'k emas)', () {
      final p = AppTheme.darkTheme.colorScheme.primary;
      expect(p, LuxTokens.gold);
      // Ko'k komponent qizildan katta bo'lmasligi kerak — oltin issiq rang.
      expect(p.b, lessThan(p.r));
    });

    test('Dark tema shrifti Plus Jakarta Sans', () {
      expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily,
          LuxTokens.body);
    });
  });

  group('T3: matn kontrasti yetarli', () {
    /// LuxTokens matn ranglari qora sirt ustida o'qilishi shart.
    /// WCAG AA: oddiy matn uchun 4.5:1, yirik matn uchun 3:1.
    double nisbat(Color old, Color fon) {
      final a = yoruglik(old) + 0.05;
      final b = yoruglik(fon) + 0.05;
      return a > b ? a / b : b / a;
    }

    test('Asosiy matn qora fonda AA (>= 4.5:1)', () {
      expect(nisbat(LuxTokens.text, LuxTokens.surface),
          greaterThanOrEqualTo(4.5));
    });

    test('Ikkilamchi matn qora fonda AA (>= 4.5:1)', () {
      expect(nisbat(LuxTokens.textMuted, LuxTokens.surface),
          greaterThanOrEqualTo(4.5));
    });

    test('Xira matn qora fonda kamida 3:1 (yirik/yordamchi)', () {
      expect(nisbat(LuxTokens.textFaint, LuxTokens.surface),
          greaterThanOrEqualTo(3.0));
    });

    test('Oltin urg\'u qora fonda kamida 3:1', () {
      expect(nisbat(LuxTokens.goldSoft, LuxTokens.surface),
          greaterThanOrEqualTo(3.0));
      expect(nisbat(LuxTokens.gold, LuxTokens.surface),
          greaterThanOrEqualTo(3.0));
    });

    test('Sirt va chegara farqlanadi (karta ko\'rinadi)', () {
      expect(LuxTokens.surface, isNot(LuxTokens.bg));
      expect(LuxTokens.border, isNot(LuxTokens.surface));
    });
  });

  group('T4: kundalik kartasida ikon matndan katta', () {
    testWidgets('Ikon o\'lchami qiymat matnidan katta', (t) async {
      await t.pumpWidget(ilova(const HomeScreen()));
      await t.pump();

      // Kundalik kartalaridagi ikonlar — oltin rangli, 26px.
      final ikonlar = t
          .widgetList<Icon>(find.byType(Icon))
          .where((i) => i.color == LuxTokens.goldSoft && i.size != null)
          .toList();
      expect(ikonlar, isNotEmpty, reason: 'Oltin ikon topilmadi');

      final engKatta =
          ikonlar.map((i) => i.size!).reduce((a, b) => a > b ? a : b);

      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(seconds: 5));
      expect(
        engKatta,
        greaterThanOrEqualTo(40),
        reason: 'Ikon ikki marta kattalashtirildi (28 -> 52 -> 88 quti, '
            'ikon 46px). Kutilgan: >= 40px, topilgan: $engKatta',
      );

      // Qiymat matni o'z holatiga qaytarildi (22px).
      final qiymatUslubi = LuxTokens.value(size: 22);
      expect(
        engKatta,
        greaterThan(qiymatUslubi.fontSize!),
        reason: 'Ikon ($engKatta) qiymat matnidan '
            '(${qiymatUslubi.fontSize}) katta bo\'lishi kerak',
      );
    });
  });

  group('T5: overflow yo\'q', () {
    // Tor va keng ekranda ham kartalar sig'ishi kerak. Overflow bo'lsa
    // Flutter istisno tashlaydi va `takeException` uni qaytaradi.
    for (final olcham in const [Size(320, 640), Size(430, 932)]) {
      testWidgets('HomeScreen ${olcham.width}px', (t) async {
        t.view.physicalSize = olcham;
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.reset);

        await t.pumpWidget(ilova(const HomeScreen()));
        await t.pump();
        final xato = t.takeException();

        await t.pumpWidget(const SizedBox.shrink());
        await t.pump(const Duration(seconds: 5));

        expect(
          xato,
          isNull,
          reason: '${olcham.width}px enida overflow/xato: $xato',
        );
      });
    }
  });
}
