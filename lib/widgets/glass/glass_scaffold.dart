import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/glass_tokens.dart';
import 'mesh_background.dart';

/// Shaffof AppBar va mesh fon bilan scaffold.
class GlassScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const GlassScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;

    return Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        Scaffold(
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
          body: body,
          floatingActionButton: floatingActionButton,
        ),
      ],
    );
  }
}
