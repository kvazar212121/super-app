import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';
import '../theme/glass_tokens.dart';
import '../utils/call_helper.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/save_provider_button.dart';
import 'package:super_app/l10n/locale_controller.dart';

class OshxonaProfileScreen extends StatelessWidget {
  final Master oshxona;

  const OshxonaProfileScreen({super.key, required this.oshxona});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF44336); // Red

    return GlassScaffold(
      showBackButton: true,
      title: 'Restoran / Oshxona',
      actions: [
        Consumer<SavedPlacesProvider>(
          builder: (context, savedPlaces, _) {
            final isSaved = savedPlaces.isSaved(oshxona.id);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : GlassTokens.primaryText(context),
              ),
              onPressed: () {
                final savedItem = SavedPlace(
                  id: oshxona.id,
                  categoryKey: ServiceHubKind.oshxona.name,
                  name: oshxona.name,
                  address: oshxona.serviceArea ?? 'Manzil ko\'rsatilmagan',
                  rating: oshxona.rating,
                  type: 'oshxona',
                  rawJson: oshxona.rawJson ?? {},
                );
                savedPlaces.toggleSave(savedItem);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSaved
                          ? 'Sevimli ro\'yxatidan o\'chirildi'
                          : 'Sevimli ro\'yxatiga qo\'shildi',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassSurface(
            padding: const EdgeInsets.all(20),
            borderRadius: GlassTokens.radiusLg,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: accent.withOpacity(0.1),
                  child: Icon(LucideIcons.utensils, color: accent, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  oshxona.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                if (oshxona.serviceArea != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.mapPin, size: 16, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        oshxona.serviceArea!,
                        style: const TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${oshxona.rating} (${oshxona.reviewCount} sharh)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (oshxona.about != null && oshxona.about!.isNotEmpty) ...[
            Text(
              'Oshxona haqida',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(oshxona.about!, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 24),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.phoneCall, color: accent, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Joy band qilish yoki menyu bo\'yicha ma\'lumot olish uchun ma\'muriyat bilan to\'g\'ridan-to\'g\'ri bog\'laning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {
                      CallHelper.startCallWithPurposeCheck(
                        context,
                        int.tryParse(oshxona.id) ?? 0,
                        oshxona.name,
                        categoryKey: ServiceHubKind.oshxona.name,
                      );
                    },
                    icon: const Icon(LucideIcons.phone),
                    label: const Text(
                      'Qo\'ng\'iroq qilish',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SaveProviderButton(
                  id: oshxona.id,
                  categoryKey: ServiceHubKind.oshxona.name,
                  name: oshxona.name,
                  address: oshxona.serviceArea ?? 'Manzil ko\'rsatilmagan',
                  rating: oshxona.rating,
                  type: 'oshxona',
                  rawJson: oshxona.rawJson ?? {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
