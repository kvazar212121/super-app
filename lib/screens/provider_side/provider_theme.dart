import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soha egasi (provider) paneli uchun majburiy yorug' (light) tema.
///
/// Mijoz ilovasi dark rejimda bo'lsa ham, biznes paneli har doim oq fon va
/// qora matnli bo'ladi. Bu `colorScheme.surface` ni shaffof emas, opaque oq
/// qilib, "qora fon" muammosini bartaraf etadi.
class ProviderTheme extends StatelessWidget {
  final Widget child;

  const ProviderTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const primary = Color(0xFF6366F1);
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        colorScheme: base.colorScheme.copyWith(
          primary: primary,
          surface: Colors.white,
          onSurface: ink,
          outlineVariant: const Color(0xFFE2E8F0),
        ),
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      child: child,
    );
  }
}
