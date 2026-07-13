import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/master_worker.dart';
import '../models/daily_models.dart';
import '../models/service_hub_kind.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';
import '../theme/glass_tokens.dart';
import '../utils/call_helper.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/save_provider_button.dart';
import 'bozorchi_dispatch_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class BozorchiProfileScreen extends StatelessWidget {
  final Master bozorchi;
  final ShoppingListModel? initialList;

  const BozorchiProfileScreen({
    super.key,
    required this.bozorchi,
    this.initialList,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2563EB); // Amber
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      showBackButton: true,
      title: 'Xaridor (Bozorchi)',
      actions: [
        Consumer<SavedPlacesProvider>(
          builder: (context, savedPlaces, _) {
            final isSaved = savedPlaces.isSaved(bozorchi.id);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : GlassTokens.primaryText(context),
              ),
              onPressed: () {
                final savedItem = SavedPlace(
                  id: bozorchi.id,
                  categoryKey: ServiceHubKind.bozorchi.name,
                  name: bozorchi.name,
                  address: bozorchi.serviceArea ?? 'Manzil ko\'rsatilmagan',
                  rating: bozorchi.rating,
                  type: 'bozorchi',
                  rawJson: bozorchi.rawJson ?? {},
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: accent.withOpacity(0.1),
                      child: Icon(
                        LucideIcons.shoppingBag,
                        color: accent,
                        size: 40,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  bozorchi.name,
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
                    Text(
                      bozorchi.serviceArea ?? 'Shahar ichida',
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w500,
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
                    Text('${bozorchi.rating} (${bozorchi.reviewCount} sharh)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Security Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.green.shade900.withOpacity(0.5),
                        Colors.teal.shade900.withOpacity(0.5),
                      ]
                    : [Colors.green.shade50, Colors.teal.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: Colors.green.shade600, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasdiqlangan mutaxassis',
                        style: TextStyle(
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ushbu xaridor shaxsini tasdiqlovchi hujjatlar bilan to\'liq tekshiruvdan o\'tgan. Firibgarlikka qarshi tizim kafolati mavjud.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.green.shade100
                              : Colors.green.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (bozorchi.about != null && bozorchi.about!.isNotEmpty) ...[
            Text(
              'O\'zi haqida',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(bozorchi.about!, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    CallHelper.startCallWithPurposeCheck(
                      context,
                      int.tryParse(bozorchi.id) ?? 0,
                      bozorchi.name,
                      categoryKey: ServiceHubKind.bozorchi.name,
                    );
                  },
                  icon: const Icon(LucideIcons.phoneCall),
                  label: const Text('Qo\'ng\'iroq'),
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
                        builder: (_) => BozorchiDispatchScreen(
                          bozorchi: bozorchi,
                          shoppingList: initialList,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.shoppingCart),
                  label: Text(
                    initialList != null
                        ? 'Ro\'yxatni jo\'natish'
                        : 'Xizmatga yollash',
                  ),
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
            id: bozorchi.id,
            categoryKey: ServiceHubKind.bozorchi.name,
            name: bozorchi.name,
            address: bozorchi.serviceArea ?? 'Manzil ko\'rsatilmagan',
            rating: bozorchi.rating,
            type: 'bozorchi',
            rawJson: bozorchi.rawJson ?? {},
          ),
        ],
      ),
    );
  }
}
