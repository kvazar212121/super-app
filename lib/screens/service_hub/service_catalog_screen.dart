import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/hub/venue_hub_card.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Katalog uchun universal element. Har xizmat bo'limi o'z provayderlarini
/// shu modelга o'giradi (name, subtitle, icon, rating, masofa, onTap...).
class CatalogEntry {
  final String name;
  final String subtitle;
  final double rating;
  final int reviewCount;
  final String priceLabel;
  final IconData icon;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? rawJson;
  final void Function(BuildContext context) onOpen;

  const CatalogEntry({
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.reviewCount,
    required this.priceLabel,
    required this.icon,
    required this.latitude,
    required this.longitude,
    required this.onOpen,
    this.rawJson,
  });
}

/// Umumiy katalog ekrani — grid ko'rinishда BARCHA provayderlar.
/// Radius (km) filtri + eng yaqindan saralash.
class ServiceCatalogScreen extends StatefulWidget {
  final String title;
  final Color accentColor;
  final List<CatalogEntry> entries;

  const ServiceCatalogScreen({
    super.key,
    required this.title,
    required this.accentColor,
    required this.entries,
  });

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  // null = butun shahar (radius cheklovsiz). Aks holda km.
  double? _radiusKm;
  double _userLat = kDefaultUserLat;
  double _userLng = kDefaultUserLng;
  bool _locating = true;

  static const _radiusOptions = <double?>[5, 10, 20, 50, null];

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  /// Joriy joylashuvni aniqlaydi. Ruxsat yo'q yoki xato bo'lsa — Toshkent
  /// markazi (kDefaultUserLat/Lng) fallback bo'lib qoladi.
  Future<void> _resolveLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _locating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Masofani hisoblab, eng yaqindan saralaymiz.
    final withDistance = widget.entries
        .map((e) => (
              entry: e,
              distance: distanceKm(_userLat, _userLng, e.latitude, e.longitude),
            ))
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    // Radius filtri (tanlangan bo'lsa).
    final filtered = _radiusKm == null
        ? withDistance
        : withDistance.where((e) => e.distance <= _radiusKm!).toList();

    return GlassScaffold(
      showBackButton: true,
      title: widget.title,
      body: Column(
        children: [
          _buildRadiusBar(context, filtered.length),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState(context)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      // VenueHubCard balandligi ~198 => 168 keng bo'lgani uchun
                      // nisbat taxminan 168/198 ≈ 0.85.
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final e = item.entry;
                      return VenueHubCard.generic(
                        name: e.name,
                        subtitle: e.subtitle,
                        rating: e.rating,
                        reviewCount: e.reviewCount,
                        priceLabel: e.priceLabel,
                        icon: e.icon,
                        accent: widget.accentColor,
                        rawJson: e.rawJson,
                        distanceKmValue: item.distance,
                        width: null,
                        onTap: () => e.onOpen(context),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusBar(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: widget.accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locating
                      ? 'Joylashuv aniqlanmoqda...'.tr
                      : '$count ${'ta topildi'.tr}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final r in _radiusOptions) ...[
                  _radiusChip(context, r),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusChip(BuildContext context, double? r) {
    final selected = _radiusKm == r;
    final label = r == null ? 'Butun shahar'.tr : '${r.round()} km';
    return GestureDetector(
      onTap: () => setState(() => _radiusKm = r),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? widget.accentColor
              : widget.accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : widget.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.mapPinOff,
            size: 48,
            color: GlassTokens.secondaryText(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu radiusда provayder topilmadi'.tr,
            style: TextStyle(
              fontSize: 14,
              color: GlassTokens.secondaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Radiusni kattalashtiring'.tr,
            style: TextStyle(
              fontSize: 12,
              color: GlassTokens.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}
