import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';
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
      colors: const [Color(0xFF6366F1), Color(0xFFA855F7)],
    ),
    _PromoItem(
      title: 'Tozalash — birinchi buyurtma',
      subtitle: '30% gacha chegirma, kod: TOZA30',
      badge: 'AKSIYA',
      colors: const [Color(0xFF0D9488), Color(0xFF06B6D4)],
    ),
    _PromoItem(
      title: 'Avto-yordam tungi tarif',
      subtitle: 'Evakuator 20% arzonroq 22:00 dan keyin',
      badge: '-20%',
      colors: const [Color(0xFFEA580C), Color(0xFFF59E0B)],
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
    if (_isLoading) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_promos.isEmpty) return const SizedBox.shrink();

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
                          // Matn o'qilishi uchun qoraytiruvchi qatlam
                          if (p.imageUrl != null)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.55),
                                    Colors.black.withValues(alpha: 0.15),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        p.title.tr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.subtitle.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p.badge.tr,
                                    style: TextStyle(
                                      color: p.colors[0],
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
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
            );
          }).toList(),
        ),
      ],
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
