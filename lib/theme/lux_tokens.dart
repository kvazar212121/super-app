import 'package:flutter/material.dart';

/// Premium "qora + oltin" dizayn tokenlari.
///
/// NEGA alohida fayl: eski `GlassTokens` butun ilovada ishlatiladi va uni
/// o'zgartirish 80+ ekranga ta'sir qiladi. Yangi ko'rinish avval bosh
/// ekranda sinaladi, keyin qolgan ekranlarga bosqichma-bosqich ko'chiriladi.
abstract final class LuxTokens {
  /// Sahifa foni — toza yorug' fon.
  static const bg = Color(0xFFF8F9FA);

  /// Karta foni — oq rang, chegara va nozik soya bilan.
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFF1F5F9);

  /// Nozik oltin chegara — barcha kartalar va panellar qirg'og'i uchun.
  static const border = Color(0xFFD4AF37);

  /// Asosiy urg'u — issiq to'yingan oltin rang.
  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFD4AF37);
  static const goldDim = Color(0xFF8C6D13);

  /// Matn ierarxiyasi: to'q qora va kulrang matnlar.
  static const text = Color(0xFF000000);
  static const textMuted = Color(0xFF2A2A2A);
  static const textFaint = Color(0xFF64748B);

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

  /// Oltin Foil Metall Gradient — 1 palasali yaltiroq metall yorug'lik chizig'i (Single-band Specular Gleam).
  static const goldGradient = LinearGradient(
    colors: [
      Color(0xFFE0B454), // Yuqori-chap: Oltin zamin
      Color(0xFFFFF9DB), // BIR DONA O'RTA CHIZIQ: 1 PALASA YALTIRAQ NUR! (Single specular streak)
      Color(0xFFC99427), // Oltin tanasi
      Color(0xFF8A5D0B), // Pastki-o'ng: Metall soya
    ],
    stops: [0.0, 0.40, 0.65, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldBarGradient = goldGradient;

  /// Metallic Gold 3D Box Decoration (Tugma, karta, badge va chip uchun)
  static BoxDecoration goldBoxDecoration({
    double radius = radiusMd,
    BorderRadiusGeometry? customRadius,
    bool isCircle = false,
  }) =>
      BoxDecoration(
        gradient: goldGradient,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : (customRadius ?? BorderRadius.circular(radius)),
        border: Border.all(
          color: const Color(0xFFFFF7C2),
          width: 1.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFF7C2),
            blurRadius: 2,
            spreadRadius: -1,
            offset: Offset(-1, -1),
          ),
          BoxShadow(
            color: const Color(0xFFC99427).withValues(alpha: 0.40),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );

  /// Metallic Gold 3D Engraved Stamp Text Style (To'q qora va o'yilgan harflar)
  static const goldEngravedTextStyle = TextStyle(
    color: Color(0xFF140D02),
    fontWeight: FontWeight.w700,
    shadows: [
      Shadow(
        color: Color(0xFFFFF7C2),
        blurRadius: 1,
        offset: Offset(0, 1.0),
      ),
      Shadow(
        color: Color(0x80000000),
        blurRadius: 1,
        offset: Offset(0, -0.8),
      ),
    ],
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

  /// Bo'lim sarlavhasi uslubi — Syne, keng harf oralig'i oltin rangda.
  static const sectionTitle = TextStyle(
    fontFamily: accent,
    color: gold,
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
    FontWeight weight = FontWeight.w600,
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
