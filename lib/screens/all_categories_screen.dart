import 'package:flutter/material.dart';
import '../models/service_hub_kind.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import 'service_hub_screen.dart';

class _CategoryGroup {
  final String title;
  final List<ServiceHubKind> items;
  const _CategoryGroup(this.title, this.items);
}

/// Barcha xizmat kategoriyalarini ro'yxat ko'rinishida ko'rsatadi.
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  static const _groups = <_CategoryGroup>[
    _CategoryGroup('Go\'zallik va Parvarish', [
      ServiceHubKind.sartarosh,
      ServiceHubKind.salon,
      ServiceHubKind.massajHijoma,
    ]),
    _CategoryGroup('Tibbiyot va Salomatlik', [
      ServiceHubKind.hamshira,
      ServiceHubKind.stomatologiya,
    ]),
    _CategoryGroup('Uy va Ta\'mirlash', [
      ServiceHubKind.usta,
      ServiceHubKind.ishchi,
      ServiceHubKind.elektrik,
      ServiceHubKind.santexnik,
      ServiceHubKind.konditsioner,
      ServiceHubKind.texnikaUstasi,
    ]),
    _CategoryGroup('Tozalik va Sanitariya', [
      ServiceHubKind.tozalash,
      ServiceHubKind.dezinfeksiya,
    ]),
    _CategoryGroup('Avto va Yetkazib berish', [
      ServiceHubKind.avtoYordam,
      ServiceHubKind.kuryerlik,
    ]),
    _CategoryGroup('Ta\'lim va Bola parvarishi', [
      ServiceHubKind.enaga,
      ServiceHubKind.repetitor,
    ]),
    _CategoryGroup('Oziq-ovqat va Xaridlar', [
      ServiceHubKind.oshxona,
      ServiceHubKind.bozorchi,
    ]),
    _CategoryGroup('Dam olish va Tadbirlar', [
      ServiceHubKind.futbol,
      ServiceHubKind.sportMaydon,
      ServiceHubKind.gameZona,
      ServiceHubKind.tadbirlar,
    ]),
    _CategoryGroup('IT va Kompyuter Xizmatlari', [
      ServiceHubKind.kompUsta,
    ]),
    _CategoryGroup('Boshqa Xizmatlar', [
      ServiceHubKind.boshqa,
      ServiceHubKind.yana,
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Barcha xizmatlar',
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _groups.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Divider(color: GlassTokens.primaryText(context).withValues(alpha: 0.1), thickness: 1),
        ),
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GlassTokens.primaryText(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: group.items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 68,
                ),
                itemBuilder: (ctx, i) {
                  final k = group.items[i];
                  return GlassSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    borderRadius: GlassTokens.radiusMd,
                    tint: k.accent.withValues(alpha: 0.08),
                    showShadow: false,
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
                            color: k.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: k.accent.withValues(alpha: 0.22)),
                          ),
                          child: Icon(k.icon, color: k.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            k.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: GlassTokens.primaryText(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
