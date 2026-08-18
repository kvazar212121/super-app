/// Firibgarlikdan OGOHLANTIRISH — sotuvchi bilan aloqadan oldin.
///
/// Foydalanuvchi majburiy talab qildi. Dialog har e'lon uchun
/// BIR MARTA chiqadi (ikkinchi marta chiqsa odam o'qimay yopadi va
/// ogohlantirish ma'nosini yo'qotadi).
library;

import 'package:flutter/material.dart';

import '../../theme/glass_tokens.dart';

const String kSafetyWarningText =
    '⚠️ Ehtiyot bo\'ling\n\n'
    'Maklerlar va firibgarlardan saqlaning. Oldindan pul o\'tkazmang.\n\n'
    'Agar sotuvchi e\'londa yozilganidan boshqa gap aytsa yoki shubhali '
    'taklif qilsa — darhol AI yordamchiga murojaat qiling.';

/// Ogohlantirish ko'rsatilgan e'lonlar (sessiya davomida).
final Set<int> _korsatilgan = <int>{};

/// TESTLAR uchun: holatni tozalash.
void resetSafetyWarnings() => _korsatilgan.clear();

enum SafetyChoice { ok, report, dismissed }

/// Aloqadan oldin ogohlantirishni ko'rsatadi.
///
/// Bir e'lon uchun ikkinchi marta chaqirilsa darhol [SafetyChoice.ok]
/// qaytaradi — aloqa to'sib qo'yilmasin.
Future<SafetyChoice> showSafetyWarning(
  BuildContext context,
  int listingId, {
  bool force = false,
}) async {
  if (!force && _korsatilgan.contains(listingId)) return SafetyChoice.ok;
  _korsatilgan.add(listingId);

  final javob = await showDialog<SafetyChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      ),
      title: const Text('Ehtiyot bo\'ling'),
      content: const Text(kSafetyWarningText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(SafetyChoice.report),
          child: const Text('Shikoyat qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(SafetyChoice.ok),
          child: const Text('Tushunarli'),
        ),
      ],
    ),
  );
  return javob ?? SafetyChoice.dismissed;
}

/// Shikoyat sababini so'raydi. Bo'sh bo'lsa ham yuboriladi —
/// operator baribir e'lonni ko'rib chiqadi.
Future<String?> askReportReason(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      ),
      title: const Text('Shikoyat'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Nima bo\'ldi? Qisqacha yozing.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Bekor'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: const Text('Yuborish'),
        ),
      ],
    ),
  );
}
