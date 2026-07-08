import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';
import '../screens/promotion_map_screen.dart';

class HomePromoSection extends StatefulWidget {
  const HomePromoSection({super.key});

  @override
  State<HomePromoSection> createState() => _HomePromoSectionState();
}

class _HomePromoSectionState extends State<HomePromoSection> {
  final ApiService _api = ApiService();
  List<_PromoItem> _promos = [];
  bool _isLoading = true;

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
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    try {
      final data = await _api.getPromos();
      final List<_PromoItem> loaded = [];
      for (final item in data) {
        final title = item['title'] ?? '';
        final subtitle = item['subtitle'] ?? '';
        final badge = item['badge'] ?? '';
        final colorsStr = item['colors'] ?? '#6366F1,#A855F7';
        
        final List<Color> parsedColors = [];
        for (final c in colorsStr.split(',')) {
          final cleanHex = c.trim().replaceAll('#', '');
          if (cleanHex.length == 6) {
            parsedColors.add(Color(int.parse('FF$cleanHex', radix: 16)));
          }
        }
        if (parsedColors.length < 2) {
          parsedColors.addAll([const Color(0xFF6366F1), const Color(0xFFA855F7)]);
        }

        final rawImageUrl = (item['image_url'] as String?)?.trim();
        loaded.add(_PromoItem(
          title: title,
          subtitle: subtitle,
          badge: badge,
          colors: parsedColors,
          imageUrl: (rawImageUrl != null && rawImageUrl.isNotEmpty)
              ? AppConfig.formatImageUrl(rawImageUrl)
              : null,
        ));
      }
      if (mounted) {
        setState(() {
          _promos = loaded.isNotEmpty ? loaded : _fallbackPromos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _promos = _fallbackPromos;
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
        child: Center(
          child: CircularProgressIndicator(),
        ),
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
                        title: p.title,
                        subtitle: p.subtitle,
                        badge: p.badge,
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
                          colors: [
                            p.colors[0],
                            p.colors[1],
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: p.colors[0],
                            blurRadius: 16,
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
                              errorWidget: (_, __, ___) => const SizedBox.shrink(),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.title,
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
                                  p.subtitle,
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
                              p.badge,
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
