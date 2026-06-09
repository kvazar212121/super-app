import 'package:flutter/material.dart';
import '../models/service_hub_kind.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import 'service_hub_screen.dart';

/// Barcha xizmat kategoriyalarini ro'yxat ko'rinishida ko'rsatadi.
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  static const _all = <ServiceHubKind>[
    ServiceHubKind.sartarosh,
    ServiceHubKind.salon,
    ServiceHubKind.futbol,
    ServiceHubKind.ishchi,
    ServiceHubKind.usta,
    ServiceHubKind.elektrik,
    ServiceHubKind.santexnik,
    ServiceHubKind.tozalash,
    ServiceHubKind.avtoYordam,
    ServiceHubKind.konditsioner,
    ServiceHubKind.enaga,
    ServiceHubKind.repetitor,
    ServiceHubKind.dezinfeksiya,
    ServiceHubKind.texnikaUstasi,
    ServiceHubKind.kuryerlik,
    ServiceHubKind.massajHijoma,
    ServiceHubKind.hamshira,
    ServiceHubKind.stomatologiya,
    ServiceHubKind.tadbirlar,
    ServiceHubKind.bozorchi,
    ServiceHubKind.oshxona,
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Barcha xizmatlar',
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final k = _all[i];
          return GlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            borderRadius: GlassTokens.radiusLg,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ServiceHubScreen(kind: k, accentColor: k.accent),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: k.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: k.accent.withValues(alpha: 0.22)),
                  ),
                  child: Icon(k.icon, color: k.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        k.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      Text(
                        k.hubSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: GlassTokens.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: GlassTokens.secondaryText(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
