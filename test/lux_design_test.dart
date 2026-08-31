import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/theme/app_theme.dart';
import 'package:super_app/theme/lux_tokens.dart';

/// Dizayn tizimining SIFAT talablarini tekshiradi.
///
/// NEGA BU TEST BOR: `flutter analyze` faqat kod to'g'riligini ko'radi.
/// Palitra o'zgartirilganda (masalan qora fondan oq fonga o'tilganda) kod
/// bexato qoladi, lekin matn fon bilan qo'shilib ketishi mumkin. Bu test
/// aynan shuni ushlaydi.
///
/// MUHIM QAROR: test palitraning AYNAN QANDAY rang ekanini TEKSHIRMAYDI
/// (qora yoki oq). Dizayn yo'nalishi biznes qarori va u o'zgarishi mumkin.
/// Test faqat MUNOSABATLARNI tekshiradi:
///   • matn fondan yetarlicha farq qiladimi (o'qiladimi),
///   • karta fondan ajralib turadimi,
///   • tema haqiqatan LuxTokens ga bog'langanmi.
/// Shu sabab test palitra o'zgarganda ham foydali bo'lib qoladi.
void main() {
  /// WCAG nisbiy yorug'lik (0 = qora, 1 = oq).
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

  /// Ikki rang orasidagi kontrast nisbati (1:1 dan 21:1 gacha).
  double nisbat(Color old, Color fon) {
    final a = yoruglik(old) + 0.05;
    final b = yoruglik(fon) + 0.05;
    return a > b ? a / b : b / a;
  }

  String hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  group('Matn o\'qiladimi (WCAG kontrast)', () {
    test('Asosiy matn karta ustida AA (>= 4.5:1)', () {
      final n = nisbat(LuxTokens.text, LuxTokens.surface);
      expect(
        n,
        greaterThanOrEqualTo(4.5),
        reason:
            'Asosiy matn ${hex(LuxTokens.text)} karta foni '
            '${hex(LuxTokens.surface)} ustida ${n.toStringAsFixed(1)}:1 — '
            'o\'qish qiyin. WCAG AA uchun 4.5:1 kerak.',
      );
    });

    test('Ikkilamchi matn karta ustida AA (>= 4.5:1)', () {
      final n = nisbat(LuxTokens.textMuted, LuxTokens.surface);
      expect(
        n,
        greaterThanOrEqualTo(4.5),
        reason:
            'Ikkilamchi matn ${hex(LuxTokens.textMuted)} '
            '${n.toStringAsFixed(1)}:1 — 4.5:1 kerak.',
      );
    });

    test('Xira matn kamida AA-large (>= 3:1)', () {
      final n = nisbat(LuxTokens.textFaint, LuxTokens.surface);
      expect(
        n,
        greaterThanOrEqualTo(3.0),
        reason: 'Xira matn ${hex(LuxTokens.textFaint)} '
            '${n.toStringAsFixed(1)}:1 — kamida 3:1 kerak.',
      );
    });

    test('Asosiy matn sahifa foni ustida ham o\'qiladi', () {
      final n = nisbat(LuxTokens.text, LuxTokens.bg);
      expect(
        n,
        greaterThanOrEqualTo(4.5),
        reason: 'Matn sahifa foni ${hex(LuxTokens.bg)} ustida '
            '${n.toStringAsFixed(1)}:1',
      );
    });
  });

  group('Oltin urg\'u ko\'rinadimi', () {
    test('Oltin karta ustida kamida 2:1 farq qiladi', () {
      // Oltin — urg'u rangi, ko'pincha yirik element yoki ikon.
      // 2:1 minimal: undan past bo'lsa urg'u umuman sezilmaydi.
      final n = nisbat(LuxTokens.gold, LuxTokens.surface);
      expect(
        n,
        greaterThanOrEqualTo(2.0),
        reason: 'Oltin ${hex(LuxTokens.gold)} karta ustida '
            '${n.toStringAsFixed(1)}:1 — sezilmaydi.',
      );
    });

    test('goldDim eng to\'q, goldSoft eng och oltin', () {
      // Oltin shkalasi tartibli bo'lishi kerak: kod shu tartibga tayanadi
      // (masalan `.shade700 -> goldDim` almashtirishlari).
      expect(
        yoruglik(LuxTokens.goldDim),
        lessThan(yoruglik(LuxTokens.gold)),
        reason: 'goldDim gold dan to\'qroq bo\'lishi kerak',
      );
      expect(
        yoruglik(LuxTokens.goldSoft),
        greaterThanOrEqualTo(yoruglik(LuxTokens.gold)),
        reason: 'goldSoft gold dan ochroq (yoki teng) bo\'lishi kerak',
      );
    });
  });

  group('Yuzalar bir-biridan ajraladi', () {
    test('Karta sahifa fonidan farq qiladi', () {
      expect(
        LuxTokens.surface,
        isNot(LuxTokens.bg),
        reason: 'Karta va sahifa foni bir xil bo\'lsa karta ko\'rinmaydi',
      );
    });

    test('Chegara karta fonidan farq qiladi', () {
      final n = nisbat(LuxTokens.border, LuxTokens.surface);
      expect(
        n,
        greaterThan(1.1),
        reason: 'Chegara ${hex(LuxTokens.border)} karta ustida deyarli '
            'ko\'rinmaydi (${n.toStringAsFixed(2)}:1)',
      );
    });

    test('surfaceHigh va surface farqlanadi', () {
      expect(LuxTokens.surfaceHigh, isNot(LuxTokens.surface));
    });
  });

  group('Tema LuxTokens ga bog\'langan', () {
    test('Sahifa foni LuxTokens.bg dan olinadi', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        LuxTokens.bg,
        reason: 'Tema palitradan uzilib qolgan — ranglarni bir joydan '
            'boshqarish buziladi',
      );
    });

    test('Urg\'u rangi oltin', () {
      expect(AppTheme.darkTheme.colorScheme.primary, LuxTokens.gold);
    });

    test('Shrift lokal asset (tarmoqsiz ishlaydi)', () {
      // google_fonts INTERNETDAN yuklaydi: oflayn qurilmada shrift
      // tushmaydi va widget testlari yiqiladi. Asset shrift shart.
      expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily,
          LuxTokens.body);
      expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily,
          LuxTokens.body);
    });

    test('Uch shrift roli aniq belgilangan', () {
      expect(LuxTokens.body, isNotEmpty);
      expect(LuxTokens.display, isNotEmpty);
      expect(LuxTokens.accent, isNotEmpty);
      // Ular bir-biridan farq qilishi kerak, aks holda rol ajratish yo'q.
      expect({LuxTokens.body, LuxTokens.display, LuxTokens.accent}.length, 3);
    });
  });

  group('Tipografika shkalasi mantiqiy', () {
    test('sectionTitle harf oralig\'i keng (premium ohang)', () {
      expect(LuxTokens.sectionTitle.letterSpacing, greaterThan(1.5));
    });

    test('value() sarlavhadan yirikroq son beradi', () {
      expect(LuxTokens.value().fontSize, greaterThan(12));
    });

    test('label() mayda va katta harfli yorliq uchun', () {
      expect(LuxTokens.label().fontSize, lessThan(12));
      expect(LuxTokens.label().letterSpacing, greaterThan(0.5));
    });
  });
}
