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
    const ink = Colors.black;
    const primary = Colors.black;
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: base.colorScheme.copyWith(
          primary: primary,
          surface: Colors.white,
          onSurface: ink,
          outline: Colors.black,
          outlineVariant: Colors.black54,
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
