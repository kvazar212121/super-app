import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

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
        Text(
          'Aksiyalar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: GlassTokens.primaryText(context),
          ),
        ),
        const SizedBox(height: 12),
        CarouselSlider(
          options: CarouselOptions(
            height: 118,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
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
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
        const SizedBox(height: 24),
        const _PartnerJoinCard(),
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

class _PartnerJoinCard extends StatelessWidget {
  const _PartnerJoinCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: () => _onTap(context),
      padding: const EdgeInsets.all(18),
      borderRadius: GlassTokens.radiusLg,
      opacity: 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Siz qaysi soha egasisiz?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Biz sizni ushbu platformaga qo‘shamiz — mijozlar sizni topadi, buyurtmalar keladi.',
            style: TextStyle(
              height: 1.35,
              color: GlassTokens.secondaryText(context),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _onTap(context),
              child: const Text('Usta / xizmat sifatida qo‘shilish'),
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: GlassTokens.glassFill(ctx, opacity: 0.85),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platformaga ariza',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(ctx),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tez orada: soha tanlash, hujjatlar va tekshiruv.',
                  style: TextStyle(color: GlassTokens.secondaryText(ctx)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rahmat! Ariza qabul qilindi.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Yuborish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
