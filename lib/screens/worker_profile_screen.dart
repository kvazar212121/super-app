import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../services/call_service.dart';
import '../utils/call_helper.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/save_provider_button.dart';

/// Ishchi profili ekrani.
class WorkerProfileScreen extends StatelessWidget {
  final Worker worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return GlassScaffold(
      showBackButton: true,
      title: 'Ishchi profili',
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
                  backgroundColor: Colors.orange[50],
                  child: Icon(
                    LucideIcons.user,
                    color: Colors.orange[800],
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  worker.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                Text(
                  worker.type,
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${worker.rating}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ma\'lumotlar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          GlassSurface(
            padding: const EdgeInsets.all(16),
            borderRadius: GlassTokens.radiusMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (worker.age != null)
                  _infoRow(context, 'Yoshi', '${worker.age} yosh'),
                if (worker.experienceYears != null)
                  _infoRow(
                    context,
                    'Tajribasi',
                    '${worker.experienceYears} yil',
                  ),
                if (worker.price != null)
                  _infoRow(
                    context,
                    'Narxi (taxminiy)',
                    currency.format(worker.price),
                  ),
              ],
            ),
          ),
          if (worker.skills.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Qila oladigan ishlari',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: worker.skills
                  .map(
                    (s) => Chip(
                      label: Text(s),
                      backgroundColor: Colors.orange[50],
                      side: BorderSide(color: Colors.orange[200]!),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                CallHelper.makeDirectCall(
                  context,
                  worker.ownerUserId,
                  worker.name,
                  asOrder: true,
                );
              },
              icon: const Icon(LucideIcons.phoneCall),
              label: const Text(
                'Bog\'lanish (Qo\'ng\'iroq)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SaveProviderButton(
            id: worker.id,
            categoryKey: ServiceHubKind.ishchi.name,
            name: worker.name,
            address: '',
            rating: worker.rating,
            type: 'master',
            rawJson: const <String, dynamic>{},
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: GlassTokens.secondaryText(context)),
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
    );
  }
}
