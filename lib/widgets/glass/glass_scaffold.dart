import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/glass_tokens.dart';
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
          bottom: false,
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

    final isDark = forceDark || context.watch<AppProvider>().isDarkMode;

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
                      color: GlassTokens.primaryText(context),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  actions: actions,
                  bottom: bottom,
                ),
          body: SafeArea(bottom: false, child: body),
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
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: GlassTokens.primaryText(context),
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
