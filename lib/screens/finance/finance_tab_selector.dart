import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';

class FinanceTabSelector extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onChanged;

  const FinanceTabSelector({
    super.key,
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassTokens.glassBorder(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(0),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeTab == 0
                            ? const Color(0xFF102A43)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Tahlil & Tarix".tr,
                        style: TextStyle(
                          color: activeTab == 0
                              ? Colors.white
                              : GlassTokens.secondaryText(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(1),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeTab == 1
                            ? const Color(0xFF102A43)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Rejali to'lovlar".tr,
                        style: TextStyle(
                          color: activeTab == 1
                              ? Colors.white
                              : GlassTokens.secondaryText(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
