import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../utils/phone_utils.dart';

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

  static String digitsOnly(String text) =>
      text.replaceAll(RegExp(r'\D'), '');

  static String fullPhone(TextEditingController c) =>
      normalizeUzPhone(digitsOnly(c.text));

  static String? validateNineDigits(String? value) {
    final d = digitsOnly(value ?? '');
    if (d.length != 9) {
      return '9 ta raqam kiriting (masalan: 901234567 yoki 200163068)';
    }
    // O'zbekiston mobil operator prefikslari (2 xona)
    const validPrefixes = [
      '90', '91', '93', '94', '95', '97', '98', '99', // Asosiy
      '33', '88', '77', '20', '50', // Uzmobile, Ucell, Mobiuz, Humans, ...
    ];
    final prefix = d.substring(0, 2);
    if (!validPrefixes.contains(prefix)) {
      return 'Telefon raqam formati noto\'g\'ri';
    }
    return null;
  }

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
        hintText: '901234567',
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
