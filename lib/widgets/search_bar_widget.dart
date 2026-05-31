import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      borderRadius: GlassTokens.radiusLg,
      child: TextField(
        style: TextStyle(color: GlassTokens.primaryText(context)),
        decoration: InputDecoration(
          hintText: 'Xizmatlarni qidirish...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          icon: Icon(LucideIcons.search, color: GlassTokens.secondaryText(context)),
          hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
        ),
      ),
    );
  }
}
