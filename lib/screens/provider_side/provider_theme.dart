import 'package:flutter/material.dart';
import '../../theme/lux_tokens.dart';

/// Soha egasi (provider) paneli uchun majburiy yorug' (light) tema.
///
/// Mijoz ilovasi dark rejimda bo'lsa ham, biznes paneli har doim oq fon va
/// qora matnli bo'ladi. Shriftlar hajmi soha egalari uchun maxsus 20-30% ga
/// ixchamlashtirilgan.
class ProviderTheme extends StatelessWidget {
  final Widget child;

  const ProviderTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const ink = Colors.black;
    const primary = Colors.black;
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = base.textTheme
        .apply(
          fontSizeFactor: 0.82, // Shriftlar o'lchamini ~25-30% ga ixchamlashtiradi
        )
        .apply(bodyColor: ink, displayColor: ink);

    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: LuxTokens.surface,
        colorScheme: base.colorScheme.copyWith(
          primary: primary,
          surface: Colors.white,
          onSurface: ink,
          outline: Colors.black,
          outlineVariant: LuxTokens.textMuted,
        ),
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: LuxTokens.surface,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      child: child,
    );
  }
}
