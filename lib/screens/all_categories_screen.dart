import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/service_hub_kind.dart';
import '../services/feature_service.dart';
import '../l10n/locale_controller.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
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
  /// Orqага qaytish tugmasi ko'rsatilsinmi. Bottom-tab sifatida ochilganда
  /// (main_screen) false, boshqa ekrandan push qilinganда true.
  final bool showBackButton;

  const AllCategoriesScreen({super.key, this.showBackButton = false});

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
      // Konditsioner endi "Texnika ustasi" ichidagi xizmat turi.
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
    _CategoryGroup('Texnika va IT', [
      ServiceHubKind.telefonUsta,
      ServiceHubKind.kompyuterUsta,
      ServiceHubKind.itXizmat,
    ]),
    _CategoryGroup('Boshqa xizmatlar', [ServiceHubKind.boshqa]),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassScaffold(
      showBackButton: widget.showBackButton,
      body: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
                        itemCount: _groups.length,
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            // Premium rejimda ajratgich NOZIK bo'ladi: qora
                            // fonda oq qalin chiziq ko'zni charchatadi.
                            color: isDark
                                ? LuxTokens.border
                                : GlassTokens.primaryText(context),
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bo'lim sarlavhasi: premium rejimda katta
                              // harfli, keng oraliqli (Syne) — bosh
                              // sahifadagi "KUNDALIK" bilan bir xil uslub.
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      gradient: LuxTokens.goldGradient,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      group.title.tr.toUpperCase(),
                                      style: LuxTokens.sectionTitle.copyWith(
                                        color: LuxTokens.gold,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: group.items.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      // 3 ustun (oldin 2 edi) — bir ekranda
                                      // ko'proq xizmat ko'rinadi va bosh
                                      // sahifadagi kartalar bilan bir xil
                                      // tartibda bo'ladi.
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      // 0.92 — kvadratdan bir oz baland,
                                      // pastdagi yozuv tasmasi uchun joy.
                                      childAspectRatio: 0.92,
                                    ),
                                itemBuilder: (ctx, i) {
                                  final k = group.items[i];
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
                                      // Rasm butun kartani to'ldiradi, yozuv
                                      // pastda gradient ustida (poster uslubi).
                                      child: Container(
                                        // DIQQAT: `clipBehavior` ishlatilganda
                                        // `decoration` NULL bo'lmasligi kerak
                                        // (Flutter assert). Shuning uchun light
                                        // rejimda ham decoration beriladi,
                                        // faqat chegarasiz.
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            GlassTokens.radiusMd,
                                          ),
                                          // Premium rejimda karta nozik chegara
                                          // oladi: rasmlarning oq foni qora
                                          // sahifa bilan "qo'shilib" ketmasin.
                                          border: isDark
                                              ? Border.all(
                                                  color: LuxTokens.border,
                                                )
                                              : null,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            k.asset3d != null
                                                ? Image.asset(
                                                    k.asset3d!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, _, _) =>
                                                            _fallbackFill(k),
                                                  )
                                                : _fallbackFill(k),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  7,
                                                  16,
                                                  7,
                                                  7,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withValues(
                                                        alpha: 0.78,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                child: Text(
                                                  k.title.tr,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    // 3 ustunda joy tor —
                                                    // 14 dan 11.5 ga tushirildi.
                                                    fontSize: 11.5,
                                                    height: 1.12,
                                                    letterSpacing: -0.2,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black54,
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
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

  /// Rasm topilmasa — accent rang butun kartani to'ldiradi + icon markazda.
  Widget _fallbackFill(ServiceHubKind k) {
    return Container(
      color: k.accent,
      child: Center(
        child: Icon(k.icon, color: Colors.white, size: 34),
      ),
    );
  }
}
