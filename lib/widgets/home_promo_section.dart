import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';
import '../screens/promotion_map_screen.dart';
import '../l10n/locale_controller.dart';

class HomePromoSection extends StatefulWidget {
  const HomePromoSection({super.key});

  @override
  State<HomePromoSection> createState() => _HomePromoSectionState();
}

class _HomePromoSectionState extends State<HomePromoSection>
    with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  List<_PromoItem> _promos = [];
  bool _isLoading = true;

  // Lokal kesh kaliti — admin panelda yuklangan bannerlar shu yerda
  // (JSON matn sifatida) saqlanadi. Internet yo'q yoki server javob bermasa,
  // yangi banner kelguncha oxirgi ko'rilgan haqiqiy bannerlar ko'rsatiladi.
  static const String _cacheKey = 'cached_promos_v1';

  static final List<_PromoItem> _fallbackPromos = [
    _PromoItem(
      title: 'Sartarosh — 25% chegirma',
      subtitle: 'Dushanba–chorshanba, barcha xizmatlar',
      badge: '-25%',
      colors: const [Color(0xFFE0B454), Color(0xFF8A5D0B)],
    ),
    _PromoItem(
      title: 'Tozalash — birinchi buyurtma',
      subtitle: '30% gacha chegirma, kod: TOZA30',
      badge: 'AKSIYA',
      colors: const [Color(0xFFD4AF37), Color(0xFF996515)],
    ),
    _PromoItem(
      title: 'Avto-yordam tungi tarif',
      subtitle: 'Evakuator 20% arzonroq 22:00 dan keyin',
      badge: '-20%',
      colors: const [Color(0xFFC99427), Color(0xFF6B4500)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFromCacheThenNetwork();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ilova old fonga qaytganda aksiyalarni serverdan qayta yuklaymiz
    // (admin panelda o'zgartirilgan bo'lsa — darhol yangilanadi).
    if (state == AppLifecycleState.resumed) {
      _loadPromos();
    }
  }

  /// Avval keshdan (tez, offline ham) ko'rsatamiz, so'ng tarmoqdan yangilaymiz.
  Future<void> _loadFromCacheThenNetwork() async {
    final cached = await _readCache();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _promos = cached;
        _isLoading = false;
      });
    }
    await _loadPromos();
  }

  /// Kesh (SharedPreferences) dagi bannerlarni o'qiydi.
  Future<List<_PromoItem>> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      return _parsePromos(data);
    } catch (_) {
      return [];
    }
  }

  /// Serverdan kelgan xom ro'yxatni keshga (JSON) yozadi.
  Future<void> _writeCache(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  /// Xom JSON ro'yxatni _PromoItem ro'yxatiga aylantiradi.
  List<_PromoItem> _parsePromos(List<dynamic> data) {
    final List<_PromoItem> loaded = [];
    for (final item in data) {
      final title = item['title'] ?? '';
      final subtitle = item['subtitle'] ?? '';
      final badge = item['badge'] ?? '';
      final colorsStr = item['colors'] ?? '#6366F1,#A855F7';

      final List<Color> parsedColors = [];
      for (final c in colorsStr.split(',')) {
        final cleanHex = c.trim().replaceAll('#', '');
        // int.tryParse — YAROQSIZ hex (masalan "eeews5") null qaytaradi, XATO TASHLAMAYDI.
        // Aks holda bitta buzuq rang butun promo yuklashni yiqitib, statik fallback chiqarardi.
        if (cleanHex.length == 6) {
          final v = int.tryParse('FF$cleanHex', radix: 16);
          if (v != null) parsedColors.add(Color(v));
        }
      }
      if (parsedColors.length < 2) {
        parsedColors.addAll([
          const Color(0xFF6366F1),
          const Color(0xFFA855F7),
        ]);
      }

      final rawImageUrl = (item['image_url'] as String?)?.trim();
      loaded.add(
        _PromoItem(
          title: title,
          subtitle: subtitle,
          badge: badge,
          colors: parsedColors,
          imageUrl: (rawImageUrl != null && rawImageUrl.isNotEmpty)
              ? AppConfig.formatImageUrl(rawImageUrl)
              : null,
        ),
      );
    }
    return loaded;
  }

  Future<void> _loadPromos() async {
    try {
      final data = await _api.getPromos();
      final loaded = _parsePromos(data);
      // Serverdan muvaffaqiyatli keldi — keshni yangilaymiz (offline uchun).
      await _writeCache(data);
      if (mounted) {
        setState(() {
          // Serverdan kelgan HAQIQIY ro'yxat (bo'sh bo'lsa — bo'lim yashiriladi).
          _promos = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        // TARMOQ XATOSI: avval kesh, kesh ham bo'sh bo'lsagina statik fallback.
        final cached = await _readCache();
        setState(() {
          if (_promos.isEmpty) {
            _promos = cached.isNotEmpty ? cached : _fallbackPromos;
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return SizedBox(
        height: isDark ? 190 : 130,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_promos.isEmpty) return const SizedBox.shrink();

    // PREMIUM (dark): bitta katta "hero" karta — ekran eniga to'liq,
    // ichida kategoriya chipi, chegirma nishoni va KO'RISH tugmasi.
    if (isDark) {
      return _LuxPromoCarousel(promos: _promos);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 130,
            viewportFraction: 0.85,
            padEnds: false,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
          ),
          items: _promos.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PromotionMapScreen(
                        title: p.title.tr,
                        subtitle: p.subtitle.tr,
                        badge: p.badge.tr,
                        colors: p.colors,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: GlassTokens.glassBlur,
                      sigmaY: GlassTokens.glassBlur,
                    ),
                    child: MediaQuery.withNoTextScaling(
                      child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [p.colors[0], p.colors[1]],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Rasm-fon (admin panel orqali yuklangan bo'lsa)
                          if (p.imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: p.imageUrl!,
                              fit: BoxFit.cover,
                              // Karusel banner — ekran kengligiga sig'adi.
                              memCacheWidth: 720,
                              maxWidthDiskCache: 960,
                              fadeInDuration:
                                  const Duration(milliseconds: 120),
                              errorWidget: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          // Chap tarafdan ko'kimtir (Deep Navy) gradient parda
                          if (p.imageUrl != null)
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF102A43),
                                    Color(0xDC102A43),
                                    Color(0x66102A43),
                                    Color(0x00102A43),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  stops: [0.0, 0.45, 0.75, 1.0],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.badge.trim().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF102A43),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white30, width: 1),
                                    ),
                                    child: Text(
                                      p.badge.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  p.title.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  p.subtitle.tr,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'KO\'RISH'.tr,
                                    style: const TextStyle(
                                      color: Color(0xFF102A43),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// PREMIUM (qora+oltin) aksiya karuseli.
///
/// Farqi eski karuseldan: karta EKRAN ENIGA to'liq (viewportFraction 1.0),
/// balandroq (180) va pastida nuqtali indikator turadi. Bu "hero" bloki —
/// bosh sahifadagi eng katta vizual urg'u, shuning uchun yagona va katta
/// bo'lishi kerak, yonma-yon qirqilgan kartalar emas.
class _LuxPromoCarousel extends StatefulWidget {
  final List<_PromoItem> promos;
  const _LuxPromoCarousel({required this.promos});

  @override
  State<_LuxPromoCarousel> createState() => _LuxPromoCarouselState();
}

class _LuxPromoCarouselState extends State<_LuxPromoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: widget.promos.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          items: widget.promos
              .map((p) => _LuxPromoCard(promo: p))
              .toList(),
        ),
        if (widget.promos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.promos.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF102A43) : LuxTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _LuxPromoCard extends StatelessWidget {
  final _PromoItem promo;
  const _LuxPromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PromotionMapScreen(
            title: promo.title.tr,
            subtitle: promo.subtitle.tr,
            badge: promo.badge.tr,
            colors: promo.colors,
          ),
        ),
      ),
      child: MediaQuery.withNoTextScaling(
        child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: LuxTokens.surface,
          borderRadius: BorderRadius.circular(LuxTokens.radiusLg),
          border: Border.all(color: LuxTokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (promo.imageUrl != null)
              CachedNetworkImage(
                imageUrl: promo.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                maxWidthDiskCache: 1200,
                fadeInDuration: const Duration(milliseconds: 150),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [promo.colors[0], promo.colors[1]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            // Chap tarafdan ko'kimtir (Deep Navy) gradient parda — matn silliq va aniq o'qiladi
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF102A43), // Deep Navy (#102A43)
                    Color(0xDC102A43),
                    Color(0x66102A43),
                    Color(0x00102A43),
                  ],
                  stops: [0.0, 0.45, 0.75, 1.0],
                ),
              ),
            ),
            // Pastdan yuqoriga qo'shimcha yumshoq soya
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xAA0A0A0B),
                    Color(0x000A0A0B),
                  ],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Yuqori chapda chegirma nishoni
                  if (promo.badge.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102A43),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white30,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        promo.badge.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Chap tomonda tartiblangan yozuvlar va KO'RISH tugmasi
                  Text(
                    promo.title.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: LuxTokens.display,
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promo.subtitle.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'KO\'RISH'.tr,
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _PromoItem {
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> colors;
  final String? imageUrl;

  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
    this.imageUrl,
  });
}
