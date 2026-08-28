import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';
import 'glass/glass_surface.dart';
import 'package:super_app/l10n/locale_controller.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final field = TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: TextStyle(
        color: GlassTokens.primaryText(context),
        fontFamily: isDark ? LuxTokens.body : null,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Xizmatlarni qidirish...'.tr,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        prefixIcon: Icon(
          LucideIcons.search,
          size: 18,
          color: isDark
              ? LuxTokens.goldSoft
              : GlassTokens.secondaryText(context),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: GlassTokens.secondaryText(context),
                ),
                onPressed: onClear,
              )
            : null,
        hintStyle: TextStyle(
          color: isDark
              ? LuxTokens.textFaint
              : GlassTokens.secondaryText(context),
          fontFamily: isDark ? LuxTokens.body : null,
          fontSize: 14,
        ),
      ),
    );

    // PREMIUM: shisha effekt o'rniga qat'iy qora kapsula + nozik chegara.
    if (isDark) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: LuxTokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LuxTokens.border),
        ),
        child: Center(child: field),
      );
    }

    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      borderRadius: GlassTokens.radiusLg,
      child: field,
    );
  }
}
