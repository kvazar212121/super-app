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
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF475569);
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

  /// Oltin Foil Metall Gradient — Haqiqiy yaltiroq 24K zarhal metall nuri (Specular Gold Foil).
  static const goldGradient = LinearGradient(
    colors: [
      Color(0xFFE5BA53), // Bronza-oltin zamin
      Color(0xFFFFF7C2), // YALTIRAQ NURLI SHIRA (Specular Light Streak)
      Color(0xFFC99427), // Chuqur 24K oltin
      Color(0xFFFFF099), // Ikkinchi yaltiroq nurlanish
      Color(0xFF8A5D0B), // Metall soya va aks
    ],
    stops: [0.0, 0.28, 0.52, 0.76, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Haqiqiy quyma oltin (gold bar) effekti — metall yuzasidagi keskin
  /// yorug'-soya bandlari. Oddiy silliq gradientdan farqi: nur chizig'i
  /// tor va tez o'zgaradi, shuning uchun ko'z uni "yaltiroq metall" deb
  /// qabul qiladi.
  static const goldBarGradient = LinearGradient(
    colors: [
      Color(0xFF8A5D0B), // qirra soyasi
      Color(0xFFC9992B), // 24K zamin
      Color(0xFFF6DC8A), // ko'tarilayotgan nur
      Color(0xFFFFFDF0), // KESKIN SPECULAR CHAQNASH
      Color(0xFFF3D179), // nurdan tushish
      Color(0xFFB8801C), // chuqur metall
      Color(0xFFE8C465), // ikkinchi aks
      Color(0xFFFFF6C8), // ikkinchi chaqnash
      Color(0xFFA9741A), // soya
      Color(0xFF6E4708), // pastki qirra
    ],
    stops: [0.00, 0.10, 0.20, 0.26, 0.33, 0.46, 0.58, 0.68, 0.85, 1.00],
    begin: Alignment(-0.9, -1.0),
    end: Alignment(0.9, 1.0),
  );

  /// Metall yuzasi ustidagi qiya "shisha" nur chizig'i (sheen).
  /// goldBarGradient ustiga qo'yiladi va yaltirashni jonlantiradi.
  static const goldSheenOverlay = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x00FFFFFF),
      Color(0x66FFFFFF),
      Color(0xB3FFFFFF),
      Color(0x59FFFFFF),
      Color(0x00FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.00, 0.30, 0.40, 0.455, 0.51, 0.62, 0.76, 1.00],
    begin: Alignment(-1.0, -0.6),
    end: Alignment(1.0, 0.6),
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
