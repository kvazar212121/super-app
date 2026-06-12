import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../theme/glass_tokens.dart';

class HomePromoSection extends StatelessWidget {
  const HomePromoSection({super.key});

  static final _promos = <_PromoItem>[
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
  Widget build(BuildContext context) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${p.title} — tez orada batafsil'),
                      behavior: SnackBarBehavior.floating,
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
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            p.colors[0].withValues(alpha: 0.82),
                            p.colors[1].withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: p.colors[0].withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
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
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              p.badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
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

  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
  });
}
