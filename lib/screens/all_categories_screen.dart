import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/service_hub_kind.dart';
import '../services/feature_service.dart';
import '../l10n/locale_controller.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import 'service_hub_screen.dart';

import '../widgets/search_input_widget.dart';
import '../widgets/search_results_widget.dart';

class _CategoryGroup {
  final String title;
  final List<ServiceHubKind> items;
  const _CategoryGroup(this.title, this.items);
}

/// Barcha xizmat kategoriyalarini ro'yxat ko'rinishida ko'rsatadi.
class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final _searchController = TextEditingController();

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
    _CategoryGroup('IT va Kompyuter Xizmatlari', [ServiceHubKind.kompUsta]),
    _CategoryGroup('Boshqa Xizmatlar', [
      ServiceHubKind.boshqa,
      ServiceHubKind.yana,
    ]),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Barcha xizmatlar'.tr,
      body: Container(
        decoration: BoxDecoration(color: Colors.transparent),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchInputWidget(
                  controller: _searchController,
                  onChanged: () => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: _searchController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SearchResultsWidget(
                          query: _searchController.text,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: _groups.length,
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Divider(
                            color: GlassTokens.primaryText(context),
                            thickness: 1,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.title.tr,
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
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: 68,
                                    ),
                                itemBuilder: (ctx, i) {
                                  final k = group.items[i];
                                  final isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  final enabled = FeatureService()
                                      .isCategoryEnabled(k.key);
                                  return Opacity(
                                    opacity: enabled ? 1.0 : 0.45,
                                    child: InkWell(
                                      onTap: () {
                                        if (!enabled) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text('Tez orada 🚧'.tr),
                                              content: Text(
                                                FeatureService()
                                                    .categoryMessage(k.key),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text('Tushunarli'.tr),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => ServiceHubScreen(
                                              kind: k,
                                              accentColor: k.accent,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(
                                        GlassTokens.radiusMd,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            GlassTokens.radiusMd,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            k.asset3d != null
                                                ? SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child: Image.asset(
                                                      k.asset3d!,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (_, __, ___) =>
                                                          _fallbackIcon(k),
                                                    ),
                                                  )
                                                : _fallbackIcon(k),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                k.title.tr,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color:
                                                      GlassTokens.primaryText(
                                                        context,
                                                      ),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3D icon topilmasa — rangli Lucide icon (eski ko'rinish).
  Widget _fallbackIcon(ServiceHubKind k) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: k.accent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: k.accent),
      ),
      child: Icon(k.icon, color: Colors.white, size: 22),
    );
  }
}
