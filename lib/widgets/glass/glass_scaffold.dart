import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';
import '../../theme/lux_tokens.dart';
import '../../theme/app_theme.dart';
import 'mesh_background.dart';

/// Shaffof AppBar va mesh fon bilan scaffold.
/// [embeddedInShell] — MainScreen tab ichida: fon takrorlanmaydi, SafeArea qo'llanadi.
class GlassScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final bool embeddedInShell;
  final bool? resizeToAvoidBottomInset;

  /// Ilova light bo'lsa ham shu ekranni MAJBURAN dark ko'rsatadi (dark fon +
  /// dark tema). Dark uchun ishlangan "mini-ilova" ekranlari uchun.
  final bool forceDark;

  /// Pastdagi tizim paneli (Android uch tugmasi / iPhone chizig'i) uchun
  /// joy qoldirilsinmi.
  ///
  /// DIQQAT: standart `true`. Ilgari `SafeArea(bottom: false)` edi va
  /// ekran oxiridagi tugmalar (masalan kaloriya "Saqlash") tizim
  /// paneli ostida qolib KESILIB ketardi — foydalanuvchi ularni bosa
  /// olmasdi. Xarita kabi butun ekranni egallashi kerak bo'lgan
  /// ekranlarda `false` qilinadi.
  final bool safeAreaBottom;

  const GlassScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.bottom,
    this.embeddedInShell = false,
    this.resizeToAvoidBottomInset,
    this.forceDark = false,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    if (embeddedInShell) {
      return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: Colors.transparent,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          bottom: safeAreaBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                _ShellHeader(
                  title: title!,
                  showBackButton: showBackButton,
                  actions: actions,
                ),
              ?bottom,
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    // Fon rangi TEMADAN olinadi (AppProvider.isDarkMode dan emas).
    //
    // NEGA: ilova temasi `main.dart` da ThemeMode.dark bilan majburan
    // qorong'i qilingan, lekin `isDarkMode` bayrog'i false qolgan edi.
    // Natijada matn oq (temadan), fon esa OQ (bayroqdan) bo'lib, ekran
    // o'qib bo'lmas holga kelardi. Tema yagona haqiqat manbai bo'lishi kerak.
    final isDark =
        forceDark || Theme.of(context).brightness == Brightness.dark;

    final scaffold = Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        Scaffold(
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: title != null,
          appBar: title == null
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  leading: showBackButton
                      ? IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: GlassTokens.primaryText(context),
                            size: 20,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        )
                      : null,
                  title: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: LuxTokens.body,
                      color: GlassTokens.primaryText(context),
                      letterSpacing: -0.4,
                    ),
                  ),
                  actions: actions,
                  bottom: bottom,
                ),
          body: SafeArea(bottom: safeAreaBottom, child: body),
          floatingActionButton: floatingActionButton,
        ),
      ],
    );

    // forceDark — butun ekranni dark tema ichida (matn/ikonlar oq bo'ladi)
    return forceDark
        ? Theme(data: AppTheme.darkTheme, child: scaffold)
        : scaffold;
  }
}

class _ShellHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const _ShellHeader({
    required this.title,
    required this.showBackButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: GlassTokens.primaryText(context),
                size: 20,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
          Expanded(
            child: Text(
              title,
              textAlign: showBackButton ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: LuxTokens.body,
                color: GlassTokens.primaryText(context),
                letterSpacing: -0.4,
              ),
            ),
          ),
          ...?actions,
          if (actions == null && showBackButton) const SizedBox(width: 48),
        ],
      ),
    );
  }
}
