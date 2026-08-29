import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:super_app/l10n/locale_controller.dart';

import '../config/map_config.dart';
import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../screens/provider_profile_screen.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';

/// Aksiya e'lon qilgan provayder modeli
class PromoProvider {
  final String id;
  final String name;
  final String specialty;
  final String address;
  final double rating;
  final int reviewCount;
  final String discountBadge;
  final double latitude;
  final double longitude;
  final ServiceHubKind kind;
  final String priceLabel;
  final Map<String, double> prices;
  final List<String> services;

  const PromoProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.discountBadge,
    required this.latitude,
    required this.longitude,
    required this.kind,
    required this.priceLabel,
    required this.prices,
    required this.services,
  });

  Master toMaster() {
    return Master(
      id: id,
      name: name,
      specialty: specialty,
      rating: rating,
      reviewCount: reviewCount,
      address: address,
      latitude: latitude,
      longitude: longitude,
      phoneNumber: '+998901234567',
      prices: prices,
      services: services,
    );
  }
}

class PromotionMapScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> colors;

  const PromotionMapScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
  });

  @override
  State<PromotionMapScreen> createState() => _PromotionMapScreenState();
}

class _PromotionMapScreenState extends State<PromotionMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _tashkentCenter = const LatLng(41.2995, 69.2401);

  // Aksiya e'lon qilgan provayderlar ro'yxati (Toshkent koordinatalari bilan)
  late final List<PromoProvider> _promoProviders = [
    PromoProvider(
      id: 'promo_1',
      name: 'Aziz — mobil sartarosh',
      specialty: 'Chilonzor, Yunusobod, Sergeli',
      address: 'Chilonzor 2-mavze, Toshkent',
      rating: 4.9,
      reviewCount: 67,
      discountBadge: widget.badge.isNotEmpty ? widget.badge : '-25%',
      latitude: 41.3111,
      longitude: 69.2797,
      kind: ServiceHubKind.sartarosh,
      priceLabel: '20k+',
      prices: {'Erkaklar kesimi': 20000, 'Soqol olish': 15000, 'Styling': 25000},
      services: ['Erkaklar kesimi', 'Soqol olish', 'Styling', 'Bolalar kesimi'],
    ),
    PromoProvider(
      id: 'promo_2',
      name: 'Grand Beauty Salon',
      specialty: 'Mirobod, Oybek ko\'chasi 14',
      address: 'Mirobod tumani, Toshkent',
      rating: 4.8,
      reviewCount: 112,
      discountBadge: '-30%',
      latitude: 41.2856,
      longitude: 69.2012,
      kind: ServiceHubKind.salon,
      priceLabel: '45k+',
      prices: {'Fen': 45000, 'Manikyur': 60000, 'Makiyaj': 80000},
      services: ['Fen', 'Manikyur', 'Makiyaj', 'Pedikyur'],
    ),
    PromoProvider(
      id: 'promo_3',
      name: 'Elite Massaj & Hijoma Center',
      specialty: 'Yashnobod, Kadisheva bozori atrofi',
      address: 'Kadisheva, Toshkent',
      rating: 4.9,
      reviewCount: 84,
      discountBadge: '-20%',
      latitude: 41.3289,
      longitude: 69.2450,
      kind: ServiceHubKind.massajHijoma,
      priceLabel: '50k+',
      prices: {'Klassik massaj': 120000, 'Hijoma': 100000},
      services: ['Klassik massaj', 'Hijoma', 'Tosh massaji'],
    ),
    PromoProvider(
      id: 'promo_4',
      name: 'CleanPro — Uy Tozalash',
      specialty: 'Yunusaliev, Bodomzor tumani',
      address: 'Bodomzor, Toshkent',
      rating: 4.7,
      reviewCount: 53,
      discountBadge: 'AKSIYA',
      latitude: 41.2750,
      longitude: 69.2600,
      kind: ServiceHubKind.ishchi,
      priceLabel: '35k+',
      prices: {'Xonadon tozalash': 150000, 'Oyna yuvish': 50000},
      services: ['Xonadon tozalash', 'Oyna yuvish', 'General tozalash'],
    ),
    PromoProvider(
      id: 'promo_5',
      name: 'Smile 3D Stomatologiya',
      specialty: 'Shayxontohur, Navoiy ko\'chasi',
      address: 'Navoiy shoh ko\'chasi, Toshkent',
      rating: 5.0,
      reviewCount: 140,
      discountBadge: '-25%',
      latitude: 41.3000,
      longitude: 69.2200,
      kind: ServiceHubKind.stomatologiya,
      priceLabel: '80k+',
      prices: {'Tish tozalash': 80000, 'Kavitet plomba': 150000},
      services: ['Tish tozalash', 'Kavitet plomba', 'Konsultatsiya'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Aksiya Xaritasi',
      safeAreaBottom: false,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBanner(context),
          _buildBottomCatalogButton(context),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _tashkentCenter,
        initialZoom: 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        MapConfig.tileLayer(),
        MarkerLayer(
          markers: _promoProviders.map((provider) {
            return Marker(
              point: LatLng(provider.latitude, provider.longitude),
              width: 54,
              height: 54,
              child: GestureDetector(
                onTap: () => _showPromoDetails(provider),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LuxTokens.goldGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFFFEE), width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        provider.kind.icon,
                        color: const Color(0xFF140D02),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        MapConfig.attribution(bottomInset: 80),
      ],
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.glassBlur,
            sigmaY: GlassTokens.glassBlur,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LuxTokens.goldGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Color(0xFF140D02),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF332205),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140D02),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.badge,
                    style: const TextStyle(
                      color: Color(0xFFE0B454),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pastki Katalogni Ochish paneli
  Widget _buildBottomCatalogButton(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openCatalogSheet(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.layoutList,
                        color: Color(0xFF140D02),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aksiya Katalogi (${_promoProviders.length})'.tr,
                        style: const TextStyle(
                          color: Color(0xFF140D02),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aksiya e'lon qilgan barcha provayderlar ro'yxati (Katalog Bottom Sheet)
  void _openCatalogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Aksiya E\'lon Qilganlar'.tr,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: GlassTokens.primaryText(sheetCtx),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: LuxTokens.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LuxTokens.goldSoft),
                      ),
                      child: Text(
                        '${_promoProviders.length} ta provayder'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A5D0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _promoProviders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final provider = _promoProviders[index];
                    return GlassSurface(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LuxTokens.goldGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              provider.kind.icon,
                              color: const Color(0xFF140D02),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: GlassTokens.primaryText(sheetCtx),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.specialty,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GlassTokens.secondaryText(sheetCtx),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${provider.rating} (${provider.reviewCount})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: GlassTokens.primaryText(sheetCtx),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LuxTokens.goldGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        provider.discountBadge,
                                        style: const TextStyle(
                                          color: Color(0xFF140D02),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _navigateToProviderProfile(provider);
                            },
                            icon: const Icon(
                              LucideIcons.chevronRight,
                              color: Color(0xFF8A5D0B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Marker bosilganda ko'rinadigan provayder kartasi va profiliga o'tish
  void _showPromoDetails(PromoProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(bCtx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.kind.icon,
                    color: const Color(0xFF140D02),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GlassTokens.primaryText(bCtx),
                        ),
                      ),
                      Text(
                        provider.specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: GlassTokens.secondaryText(bCtx),
                        ),
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
                    gradient: LuxTokens.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    provider.discountBadge,
                    style: const TextStyle(
                      color: Color(0xFF140D02),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${provider.rating} (${provider.reviewCount} ${'sharh'.tr})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    provider.priceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8A5D0B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LuxTokens.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(bCtx);
                        _navigateToProviderProfile(provider);
                      },
                      icon: const Icon(LucideIcons.userCheck, color: Color(0xFF140D02)),
                      label: Text(
                        'Buyurtma berish / Profil'.tr,
                        style: const TextStyle(
                          color: Color(0xFF140D02),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToProviderProfile(PromoProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderProfileScreen(
          master: provider.toMaster(),
          category: provider.kind,
        ),
      ),
    );
  }
}
