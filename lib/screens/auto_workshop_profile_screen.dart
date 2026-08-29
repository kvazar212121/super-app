import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/auto_workshop.dart';
import '../models/service_hub_kind.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';
import '../theme/glass_tokens.dart';
import '../utils/call_helper.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/save_provider_button.dart';
import 'auto_workshop_dispatch_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class AutoWorkshopProfileScreen extends StatelessWidget {
  final AutoWorkshop workshop;

  const AutoWorkshopProfileScreen({super.key, required this.workshop});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB8921F); // Slate
    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return GlassScaffold(
      showBackButton: true,
      title: 'Avto-ustaxona / Servis',
      actions: [
        Consumer<SavedPlacesProvider>(
          builder: (context, savedPlaces, _) {
            final isSaved = savedPlaces.isSaved(workshop.id);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : GlassTokens.primaryText(context),
              ),
              onPressed: () {
                final savedItem = SavedPlace(
                  id: workshop.id,
                  categoryKey: ServiceHubKind.avtoYordam.name,
                  name: workshop.name,
                  address: workshop.address,
                  rating: workshop.rating,
                  type: 'autoWorkshop',
                  rawJson: workshop.rawJson ?? {},
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
                  backgroundColor: accent.withValues(alpha: 0.1),
                  child: const Icon(LucideIcons.home, color: accent, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  workshop.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 16, color: accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        workshop.address,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${workshop.rating} (${workshop.reviewCount} sharh)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (workshop.specializations.isNotEmpty) ...[
            Text(
              'Ixtisosliklar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: workshop.specializations
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: accent.withValues(alpha: 0.1),
                      side: BorderSide(color: accent.withValues(alpha: 0.3)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Xizmatlar (Taxminiy narxlar)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          ...workshop.prices.entries.map((e) {
            return GlassSurface(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: GlassTokens.radiusMd,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    currency.format(e.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    CallHelper.startCallWithPurposeCheck(
                      context,
                      workshop.providerId,
                      workshop.name,
                    );
                  },
                  icon: const Icon(LucideIcons.phoneCall),
                  label: Text('Qo\'ng\'iroq'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: const BorderSide(color: accent, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AutoWorkshopDispatchScreen(workshop: workshop),
                      ),
                    );
                  },
                  icon: Icon(LucideIcons.wrench),
                  label: Text('Qabulga yozilish'.tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SaveProviderButton(
            id: workshop.id,
            categoryKey: ServiceHubKind.avtoYordam.name,
            name: workshop.name,
            address: workshop.address,
            rating: workshop.rating,
            type: 'autoWorkshop',
            rawJson: workshop.rawJson ?? {},
          ),
        ],
      ),
    );
  }
}
