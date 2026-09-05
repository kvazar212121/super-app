import 'package:flutter/material.dart';

/// Premium, sokin va professional "Deep Navy + Soft Gold Accent" dizayn tokenlari.
///
/// Ranglar palitrasi (Foydalanuvchi tanlagan arxitektura):
/// - Fon: #F5F7FA (Juda och kulrang-ko'kimtir)
/// - Kartalar: #FFFFFF (Yumshoq oq, #E5E7EB chegara bilan)
/// - Asosiy brend rang (Logo & Sarlavhalar): #102A43 (To'q navy)
/// - Urg'u (Accent): #E5B93D (Yumshoq oltin — faqat aktiv holat/narx/badj uchun)
/// - Muvaffaqiyat (Success): #4F8A6D (Sokin yashil)
/// - Xatolik (Error): #D96C6C (Yumshoq qizil)
/// - Asosiy matn: #17202A (Juda to'q)
/// - Ikkinchi matn: #6B7280 (Kulrang)
abstract final class LuxTokens {
  /// Sahifa foni — sokin, nafis juda och kulrang-ko'kimtir fon (#F5F7FA).
  static const bg = Color(0xFFF5F7FA);

  /// Karta foni — sof yumshoq oq rang.
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFF8FAFC);

  /// Asosiy brend rangi — to'q navy (#102A43).
  static const navy = Color(0xFF102A43);
  static const primaryNavy = Color(0xFF102A43);

  /// Nozik toza chegara — barcha kartalar uchun (#E5E7EB).
  /// Sariq chegaralar o'rniga zamonaviy och kulrang chegara.
  static const border = Color(0xFFE5E7EB);

  /// Asosiy urg'u (Accent) — yumshoq oltin rang (#E5B93D).
  /// Faqat aktiv tugma, narx, chegirma badge va aktiv tab ikonkalari uchun.
  static const gold = Color(0xFFE5B93D);
  static const goldSoft = Color(0xFFF5D77F);
  static const goldDim = Color(0xFFB88C22);

  /// Muvaffaqiyat va Xatolik ranglari.
  static const success = Color(0xFF4F8A6D);
  static const error = Color(0xFFD96C6C);

  /// Matn ierarxiyasi: juda to'q va kulrang matnlar.
  static const text = Color(0xFF17202A);
  static const textMuted = Color(0xFF334155);
  static const textFaint = Color(0xFF6B7280);

  static const radiusSm = 12.0;
  static const radiusMd = 18.0;
  static const radiusLg = 24.0;

  // ── SHRIFT (BITTA MARKAZIY JOY) ────────────────────────────────
  static const fontFamily = 'PlusJakartaSans';
  static const displayFontFamily = 'PlusJakartaSans';

  static const body = fontFamily;
  static const display = fontFamily;
  static const accent = fontFamily;

  /// Yumshoq Oltin Gradient — faqat muhim accent tugma va nishonlar uchun.
  static const goldGradient = LinearGradient(
    colors: [
      Color(0xFFF0CB5B),
      Color(0xFFE5B93D),
      Color(0xFFC79820),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldBarGradient = goldGradient;

  /// Deep Navy Brand Gradient (Brend sarlavhalari va navigatsiya uchun)
  static const navyGradient = LinearGradient(
    colors: [
      Color(0xFF102A43),
      Color(0xFF243B53),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Accent Gold Box Decoration (Faqat asosiylashgan tugmalar va badge uchun)
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B93D).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Metallic Gold 3D Engraved Stamp Text Style
  static const goldEngravedTextStyle = TextStyle(
    color: Color(0xFF102A43),
    fontWeight: FontWeight.w800,
  );

  /// Karta uchun standart bezak (Sof Oq fon + #E5E7EB chegara + nozik yumshoq soya).
  static BoxDecoration card({
    double radius = radiusMd,
    Color? color,
    Color? borderColor,
  }) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? border, width: 1),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF102A43).withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Kichik "chip" (yorliq) bezagi — nozik ramka bilan.
  static BoxDecoration chip({bool accent = false}) => BoxDecoration(
    color: accent ? gold.withValues(alpha: 0.12) : surface,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: accent ? gold : border,
      width: 1,
    ),
  );

  /// Bo'lim sarlavhasi uslubi — To'q Navy (#102A43) rangda.
  static const sectionTitle = TextStyle(
    fontFamily: accent,
    color: navy,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
  );

  static const sectionTitleMuted = TextStyle(
    fontFamily: accent,
    color: textFaint,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
  );

  /// Mayda KATTA HARFLI yorliq (chip, izoh, "MAXSUS TAKLIF").
  static TextStyle label({
    Color color = textFaint,
    double size = 10,
    FontWeight weight = FontWeight.w600,
    double spacing = 1.2,
  }) => TextStyle(
    fontFamily: accent,
    color: color,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
  );

  /// Nafis yirik sarlavha.
  static TextStyle heading({
    Color color = text,
    double size = 26,
    FontWeight weight = FontWeight.w800,
  }) => TextStyle(
    fontFamily: display,
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: 1.1,
    letterSpacing: -0.3,
  );

  /// Son/qiymat uslubi (karta ichidagi asosiy raqam).
  static TextStyle value({
    Color color = navy,
    double size = 21,
  }) => TextStyle(
    fontFamily: accent,
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.2,
  );
}
