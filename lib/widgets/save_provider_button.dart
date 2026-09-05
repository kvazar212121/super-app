import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_controller.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';

/// "Saqlab qo'yish" tugmasi — istalgan xizmat/provayder profilida ishlatiladi.
/// Bosilganда joy "Saqlanganlar" (Barcha xizmatlar > Saqlanganlar) ro'yxatiga
/// qo'shiladi yoki olib tashlanadi.
class SaveProviderButton extends StatelessWidget {
  final String id;
  final String categoryKey;
  final String name;
  final String address;
  final double rating;
  final String type;
  final Map<String, dynamic> rawJson;

  /// true — to'liq kenglikdagi tugma (call tugmasi ostiga); false — ixcham.
  final bool fullWidth;

  const SaveProviderButton({
    super.key,
    required this.id,
    required this.categoryKey,
    required this.name,
    required this.address,
    required this.rating,
    required this.type,
    required this.rawJson,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedPlacesProvider>(
      builder: (context, saved, _) {
        final isSaved = saved.isSaved(id);
        final btn = OutlinedButton.icon(
          onPressed: () {
            saved.toggleSave(SavedPlace(
              id: id,
              categoryKey: categoryKey,
              name: name,
              address: address,
              rating: rating,
              type: type,
              rawJson: rawJson,
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSaved
                    ? 'Saqlanganlardan olib tashlandi'.tr
                    : 'Saqlanganlarga qo\'shildi'.tr),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(
            isSaved ? Icons.favorite : Icons.favorite_border,
            color: isSaved ? const Color(0xFFEF4444) : const Color(0xFF102A43),
            size: 20,
          ),
          label: Text(isSaved ? 'Saqlangan'.tr : 'Saqlab qo\'yish'.tr),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isSaved ? const Color(0xFFEF4444) : const Color(0xFF102A43),
            side: BorderSide(
              color: isSaved
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFCBD5E1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        if (fullWidth) {
          return SizedBox(width: double.infinity, child: btn);
        }
        return btn;
      },
    );
  }
}

/// Ixcham dumaloq saqlash ikonkasi (kartalar burchagida ishlatish uchun).
class SaveProviderIcon extends StatelessWidget {
  final SavedPlace Function() itemBuilder;

  const SaveProviderIcon({super.key, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedPlacesProvider>(
      builder: (context, saved, _) {
        final item = itemBuilder();
        final isSaved = saved.isSaved(item.id);
        return IconButton(
          tooltip: isSaved ? 'Saqlangan'.tr : 'Saqlab qo\'yish'.tr,
          icon: Icon(
            isSaved ? Icons.favorite : Icons.favorite_border,
            color: isSaved ? const Color(0xFFEF4444) : null,
          ),
          onPressed: () {
            saved.toggleSave(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSaved
                    ? 'Saqlanganlardan olib tashlandi'.tr
                    : 'Saqlanganlarga qo\'shildi'.tr),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
