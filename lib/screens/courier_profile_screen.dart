import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/courier_service.dart';
import '../models/service_hub_kind.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';
import '../theme/glass_tokens.dart';
import '../utils/call_helper.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/save_provider_button.dart';
import 'courier_dispatch_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class CourierProfileScreen extends StatelessWidget {
  final CourierService service;

  const CourierProfileScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB8921F); // Indigo
    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return GlassScaffold(
      showBackButton: true,
      title: 'Kuryer xizmati',
      actions: [
        Consumer<SavedPlacesProvider>(
          builder: (context, savedPlaces, _) {
            final isSaved = savedPlaces.isSaved(service.id);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : GlassTokens.primaryText(context),
              ),
              onPressed: () {
                final savedItem = SavedPlace(
                  id: service.id,
                  categoryKey: ServiceHubKind.kuryerlik.name,
                  name: service.name,
                  address: service.serviceArea ?? 'Hudud ko\'rsatilmagan',
                  rating: service.rating,
                  type: 'courier',
                  rawJson: service.rawJson ?? {},
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
                  child: Icon(LucideIcons.package, color: accent, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  service.name,
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
                    const Icon(LucideIcons.bike, size: 16, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      service.vehicleType.label,
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (service.serviceArea != null) ...[
                      const SizedBox(width: 12),
                      const Icon(LucideIcons.mapPin, size: 16, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        service.serviceArea!,
                        style: const TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${service.rating} (${service.reviewCount} sharh)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keltirib bera oladigan narsalari',
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
            children: service.deliveryTypes
                .map(
                  (t) => Chip(
                    avatar: Icon(t.icon, size: 16, color: accent),
                    label: Text(t.label.tr),
                    backgroundColor: accent.withValues(alpha: 0.1),
                    side: BorderSide(color: accent.withValues(alpha: 0.3)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Narxlar (Malumot uchun)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          ...service.prices.entries.map((e) {
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
          const SizedBox(height: 8),
          const Text(
            '* Yakuniy narx manzillar orasidagi masofaga va yuk og\'irligiga qarab kuryer bilan kelishiladi.',
            style: TextStyle(fontSize: 13, color: LuxTokens.textMuted),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    CallHelper.startCallWithPurposeCheck(
                      context,
                      int.tryParse(service.id) ?? 0,
                      service.name,
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
                        builder: (_) => CourierDispatchScreen(service: service),
                      ),
                    );
                  },
                  icon: Icon(LucideIcons.send),
                  label: Text('Kuryer chaqirish'.tr),
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
            id: service.id,
            categoryKey: ServiceHubKind.kuryerlik.name,
            name: service.name,
            address: service.serviceArea ?? 'Hudud ko\'rsatilmagan',
            rating: service.rating,
            type: 'courier',
            rawJson: service.rawJson ?? {},
          ),
        ],
      ),
    );
  }
}
