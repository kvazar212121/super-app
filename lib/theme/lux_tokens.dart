import 'package:flutter/material.dart';

/// Premium "qora + oltin" dizayn tokenlari.
///
/// NEGA alohida fayl: eski `GlassTokens` butun ilovada ishlatiladi va uni
/// o'zgartirish 80+ ekranga ta'sir qiladi. Yangi ko'rinish avval bosh
/// ekranda sinaladi, keyin qolgan ekranlarga bosqichma-bosqich ko'chiriladi.
abstract final class LuxTokens {
  /// Sahifa foni — deyarli qora, ozgina iliq ohang bilan.
  static const bg = Color(0xFF0A0A0B);

  /// Karta foni — fondan bir pog'ona ochiq, chegara bilan ajraladi.
  static const surface = Color(0xFF141416);
  static const surfaceHigh = Color(0xFF1B1B1E);

  /// Nozik chegara — oltin emas, kulrang. Oltin faqat urg'u uchun.
  static const border = Color(0xFF26262A);

  /// Asosiy urg'u — issiq oltin (shampan emas, to'yingan).
  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFE3C766);
  static const goldDim = Color(0xFF6E5A1E);

  /// Matn ierarxiyasi: uch pog'ona yetarli, ko'proq chalkashtiradi.
  static const text = Color(0xFFF2F2F0);
  static const textMuted = Color(0xFF9A9A96);
  static const textFaint = Color(0xFF6B6B68);

  static const radiusSm = 12.0;
  static const radiusMd = 18.0;
  static const radiusLg = 24.0;

  // ── SHRIFTLAR ──────────────────────────────────────────────────
  // Uchta rol, aniq chegara bilan. Aralashtirilsa dizayn buziladi:
  //  • [body]    — barcha oddiy matn, tugma, izoh. Geometrik grotesk.
  //  • [display] — nafis SARLAVHALAR (banner nomi, ekran sarlavhasi).
  //                Serif bo'lgani uchun faqat YIRIK o'lchamda ishlatiladi;
  //                12px dan kichikda ingichka shtrixlari yo'qoladi.
  //  • [accent]  — KATTA HARFLI, keng oraliqli mayda yorliqlar
  //                ("KUNDALIK", "MAXSUS TAKLIF", "KO'RISH").
  static const body = 'PlusJakartaSans';
  static const display = 'CormorantGaramond';
  static const accent = 'Syne';

  /// Oltin gradient — tugma va urg'uli matnlar uchun.
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE3C766), Color(0xFFC9A227), Color(0xFF9C7B15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Karta uchun standart bezak (fon + chegara + radius).
  static BoxDecoration card({
    double radius = radiusMd,
    Color? color,
    Color? borderColor,
  }) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? border, width: 1),
  );

  /// Kichik "chip" (yorliq) bezagi — oltin ramkali shaffof fon.
  static BoxDecoration chip({bool accent = false}) => BoxDecoration(
    color: accent ? gold.withValues(alpha: 0.12) : const Color(0xFF1F1F22),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: accent ? gold.withValues(alpha: 0.45) : border,
      width: 1,
    ),
  );

  /// Bo'lim sarlavhasi uslubi — Syne, keng harf oralig'i "premium" hissini beradi.
  static const sectionTitle = TextStyle(
    fontFamily: accent,
    color: text,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.2,
  );

  static const sectionTitleMuted = TextStyle(
    fontFamily: accent,
    color: textFaint,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.4,
  );

  /// Mayda KATTA HARFLI yorliq (chip, izoh, "MAXSUS TAKLIF").
  static TextStyle label({
    Color color = textFaint,
    double size = 9,
    FontWeight weight = FontWeight.w500,
    double spacing = 1.6,
  }) => TextStyle(
    fontFamily: accent,
    color: color,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
  );

  /// Nafis yirik sarlavha (banner nomi). Serif — faqat 18px+ da.
  static TextStyle heading({
    Color color = text,
    double size = 26,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: display,
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: 1.1,
    letterSpacing: 0.2,
  );

  /// Son/qiymat uslubi (karta ichidagi asosiy raqam).
  ///
  /// NEGA serif EMAS: Cormorant Garamond raqamlari "old-style" (matnli) —
  /// 3, 4, 7 asosiy chiziqdan pastga tushadi va son notekis ko'rinadi.
  /// Statistika uchun bu yaroqsiz, shuning uchun Syne ishlatiladi:
  /// zamonaviy, barcha raqamlari bir balandlikda (tabular ko'rinish).
  static TextStyle value({
    Color color = goldSoft,
    double size = 21,
  }) => TextStyle(
    fontFamily: accent,
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.05,
    letterSpacing: -0.2,
  );
}
