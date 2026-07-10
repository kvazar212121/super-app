import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: '901234567 yoki 200163068'.tr,
        prefixIcon: const Icon(LucideIcons.phone, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Text(
            '+998 ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
      validator: validator ?? validateNineDigits,
    );
  }
}
