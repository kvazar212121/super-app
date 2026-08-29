import 'package:flutter/material.dart';
import 'package:super_app/l10n/locale_controller.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';
import '../screens/master_dispatch_screen.dart';
import '../screens/cleaning_dispatch_screen.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/save_provider_button.dart';
import '../utils/call_helper.dart';

/// Usta / mobil mutaxassis profili.
class ProviderProfileScreen extends StatelessWidget {
  final Master master;
  final ServiceHubKind category;

  const ProviderProfileScreen({
    super.key,
    required this.master,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final accent = category.accent;
    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return GlassScaffold(
      showBackButton: true,
      title: 'Profil',
      actions: [
        Consumer<SavedPlacesProvider>(
          builder: (context, savedPlaces, _) {
            final isSaved = savedPlaces.isSaved(master.id);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : GlassTokens.primaryText(context),
              ),
              onPressed: () {
                final savedItem = SavedPlace(
                  id: master.id,
                  categoryKey: category.name,
                  name: master.name,
                  address: master.locationLabel,
                  rating: master.rating,
                  type: 'master',
                  rawJson:
                      master.rawJson ??
                      {
                        'id': master.id,
                        'name': master.name,
                        'phone': master.phoneNumber,
                        'rating': master.rating,
                        'review_count': master.reviewCount,
                        'lat': master.latitude,
                        'lng': master.longitude,
                        'address': master.address,
                        'metadata': {
                          'specialty': master.specialty,
                          'services': master.services,
                          'prices': master.prices,
                          'service_area': master.serviceArea,
                          'is_mobile': master.isHomeVisit,
                          'cleaner_role': master.cleanerRole,
                          'master_role': master.masterRole,
                          'electrician_role': master.electricianRole,
                          'plumber_role': master.plumberRole,
                          'ac_role': master.acRole,
                          'team_size': master.teamSize,
                        },
                      },
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
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(category.icon, color: const Color(0xFF140D02), size: 38),
                ),
                const SizedBox(height: 16),
                Text(
                  master.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                Text(
                  master.specialty,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${master.rating} (${master.reviewCount} ${'sharh'.tr})'),
                  ],
                ),
                if (master.reviewCount > 0) ...[
                  const SizedBox(height: 6),
                  _satisfactionBar(context, master.rating),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (master.isHomeVisit) ...[
            _infoTile(
              context,
              LucideIcons.car,
              'Xizmat turi',
              master.isCleaningTeam
                  ? 'Jamoa uyga boradi${master.teamSize != null ? ' (${master.teamSize} kishi)' : ''}'
                  : master.isMasterBrigade
                  ? 'Brigada uyga boradi${master.teamSize != null ? ' (${master.teamSize} kishi)' : ''}'
                  : master.isCleaner
                  ? 'Uyga borib tozalash'
                  : master.isMasterSolo
                  ? 'Uyga borib ta\'mirlash'
                  : master.isElectrician
                  ? 'Uyga borib elektr xizmati'
                  : master.isPlumber
                  ? 'Uyga borib santexnik xizmati'
                  : master.isAcTechnician
                  ? 'Uyga borib konditsioner xizmati'
                  : 'Uyga borib xizmat ko\'rsatadi',
            ),
            if (master.serviceArea != null && master.serviceArea!.isNotEmpty)
              _infoTile(
                context,
                LucideIcons.mapPin,
                'Xizmat hududi',
                master.serviceArea!,
              ),
          ] else ...[
            _infoTile(
              context,
              LucideIcons.mapPin,
              'Joylashuv',
              master.locationLabel,
            ),
          ],

          const SizedBox(height: 16),
          Text(
            'Xizmatlar va narxlar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          ...master.services.map((s) {
            final price = master.prices[s] ?? 0;
            return GlassSurface(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: GlassTokens.radiusMd,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    currency.format(price),
                    style: TextStyle(
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
                      master.providerId,
                      master.name,
                    );
                  },
                  icon: const Icon(LucideIcons.phoneCall),
                  label: Text('Qo\'ng\'iroq'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent, width: 2),
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
                        builder: (_) => master.isCleaner
                            ? CleaningDispatchScreen(
                                master: master,
                                category: category,
                              )
                            : MasterDispatchScreen(
                                master: master,
                                category: category,
                              ),
                      ),
                    );
                  },
                  icon: Icon(
                    category.name == 'massajHijoma' ||
                            category.name == 'salon' ||
                            category.name == 'sartarosh'
                        ? LucideIcons.calendarCheck
                        : (master.isHomeVisit
                              ? LucideIcons.calendarCheck
                              : LucideIcons.wrench),
                  ),
                  label: Text(
                    category.name == 'massajHijoma' ||
                            category.name == 'salon' ||
                            category.name == 'sartarosh'
                        ? 'Qabulga yozilish'
                        : master.isCleaner ||
                              master.isDispatchMaster ||
                              master.isElectrician ||
                              master.isPlumber ||
                              master.isAcTechnician
                        ? 'Chaqirish'
                        : (master.isHomeVisit
                              ? 'Bron qilish'
                              : 'Ustani chaqirish'),
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
            id: master.id,
            categoryKey: category.name,
            name: master.name,
            address: master.locationLabel,
            rating: master.rating,
            type: 'master',
            rawJson:
                master.rawJson ??
                {
                  'id': master.id,
                  'name': master.name,
                  'phone': master.phoneNumber,
                  'rating': master.rating,
                  'review_count': master.reviewCount,
                  'lat': master.latitude,
                  'lng': master.longitude,
                  'address': master.address,
                  'metadata': {
                    'specialty': master.specialty,
                    'services': master.services,
                    'prices': master.prices,
                    'service_area': master.serviceArea,
                    'is_mobile': master.isHomeVisit,
                    'cleaner_role': master.cleanerRole,
                    'master_role': master.masterRole,
                    'electrician_role': master.electricianRole,
                    'plumber_role': master.plumberRole,
                    'ac_role': master.acRole,
                    'team_size': master.teamSize,
                  },
                },
          ),
        ],
      ),
    );
  }

  /// Umumiy reytingни 5 ballдан foizga aylantirib (mamnunlik %) progress bar
  /// bilan ko'rsatadi. Masalan 4.8/5 = 96% mamnunlik.
  Widget _satisfactionBar(BuildContext context, double rating) {
    final percent = (rating / 5 * 100).clamp(0, 100).round();
    const color = Color(0xFF8A5D0B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percent% ${'mamnunlik'.tr}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: LuxTokens.gold.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC99427)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: GlassTokens.secondaryText(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
