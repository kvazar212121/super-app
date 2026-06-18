import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../screens/master_dispatch_screen.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';

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
    final currency = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return GlassScaffold(
      showBackButton: true,
      title: 'Profil',
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
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(category.icon, color: accent, size: 40),
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
                    Text('${master.rating} (${master.reviewCount} sharh)'),
                  ],
                ),
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
              _infoTile(context, LucideIcons.mapPin, 'Xizmat hududi', master.serviceArea!),
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
                  Expanded(child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(currency.format(price), style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MasterDispatchScreen(
                      master: master,
                      category: category,
                    ),
                  ),
                );
              },
              icon: Icon(master.isHomeVisit ? LucideIcons.calendarCheck : LucideIcons.phoneCall),
              label: Text(
                master.isCleaner || master.isDispatchMaster || master.isElectrician || master.isPlumber || master.isAcTechnician
                    ? 'Buyurtma berish'
                    : (master.isHomeVisit ? 'Vaqt bron qilish' : 'Ustani chaqirish'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) {
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
                Text(label, style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context))),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: GlassTokens.primaryText(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
