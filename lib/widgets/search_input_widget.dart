import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

class SearchInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const SearchInputWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      borderRadius: GlassTokens.radiusLg,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        style: TextStyle(color: GlassTokens.primaryText(context)),
        decoration: InputDecoration(
          hintText: 'Xizmatlarni qidirish...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          prefixIcon: Icon(LucideIcons.search, color: GlassTokens.secondaryText(context)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: GlassTokens.secondaryText(context)),
                  onPressed: onClear,
                )
              : null,
          hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
        ),
      ),
    );
  }
}
