import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/lux_tokens.dart';
import '../../utils/phone_utils.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// +998 prefiksi oldindan, foydalanuvchi faqat 9 raqam kiritadi.
class UzPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final bool enabled;

  const UzPhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Telefon raqam',
    this.enabled = true,
  });

  static String digitsOnly(String text) => text.replaceAll(RegExp(r'\D'), '');

  static String fullPhone(TextEditingController c) =>
      normalizeUzPhone(digitsOnly(c.text));

  static String? validateNineDigits(String? value) =>
      validateUzMobileDigits(value);

  @override
  Widget build(BuildContext context) {
    // Ilova dizayni oq/oltin — telefon maydoni har doim och fon, to'q matn.
    // (Ilgari dark rejimda qora panel chiqib, matn ko'rinmay qolardi.)
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintText: '901234567 yoki 200163068'.tr,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(LucideIcons.phone, size: 20, color: LuxTokens.gold),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 4, right: 4),
          child: Text(
            '+998 ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LuxTokens.gold, width: 1.8),
        ),
      ),
      validator: validator ?? validateNineDigits,
    );
  }
}
