import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/barber_shop.dart';
import '../models/beauty_salon.dart';
import '../models/football_field.dart';
import '../models/master_worker.dart';
import '../models/courier_service.dart';
import '../models/nanny_service.dart';
import '../models/auto_mobile_service.dart';
import '../models/auto_workshop.dart';
import '../models/service_hub_kind.dart';
import '../screens/barber_booking_screen.dart';
import '../screens/salon_booking_screen.dart';
import '../screens/football_field_booking_screen.dart';
import '../screens/provider_profile_screen.dart';
import '../screens/courier_booking_screen.dart';
import '../screens/auto_help_booking_screen.dart';
import '../screens/auto_workshop_booking_screen.dart';
import '../screens/nanny_profile_screen.dart';
import '../models/tutor_service.dart';
import '../screens/tutor_profile_screen.dart';
import '../theme/glass_tokens.dart';
import '../utils/geo_utils.dart';
import 'glass/glass_surface.dart';

/// Hub ekranlari uchun filtr turi — boshqa sohalarga ham qo'llash mumkin.
enum HubListFilter { all, nearest, topRated, openNow }

/// Gorizontal filtr chiplari (sartarosh, salon, futbol…).
class HubFilterChips extends StatelessWidget {
  final HubListFilter selected;
  final ValueChanged<HubListFilter> onChanged;
  final Color accent;

  const HubFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.accent,
  });

  static const _labels = {
    HubListFilter.all: 'Barchasi',
    HubListFilter.nearest: 'Eng yaqin',
    HubListFilter.topRated: 'Reyting',
    HubListFilter.openNow: 'Ochiq',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HubListFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = HubListFilter.values[i];
          final isSelected = f == selected;
          return FilterChip(
            label: Text(_labels[f]!),
            selected: isSelected,
            onSelected: (_) => onChanged(f),
            selectedColor: accent.withValues(alpha: 0.15),
            checkmarkColor: accent,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? accent : GlassTokens.primaryText(context),
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? accent : GlassTokens.glassBorder(context),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}

/// Jismoniy joylar kartasi — sartarosh, salon, futbol maydoni va h.k.
class VenueHubCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String distanceLabel;
  final String priceLabel;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const VenueHubCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.distanceLabel,
    required this.priceLabel,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  factory VenueHubCard.fromBarberShop(
    BarberShop shop, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    return VenueHubCard(
      name: shop.name,
      subtitle: shop.address,
      distanceLabel: formatDistanceKm(shop.distanceKmFrom(userLat, userLng)),
      priceLabel: shop.priceRangeLabel(),
      rating: shop.rating,
      reviewCount: shop.reviewCount,
      isOpen: shop.isOpenNow(),
      icon: LucideIcons.scissors,
      accent: accent,
      onTap: onTap,
    );
  }

  factory VenueHubCard.fromBeautySalon(
    BeautySalon salon, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    return VenueHubCard(
      name: salon.name,
      subtitle: salon.address,
      distanceLabel: formatDistanceKm(salon.distanceKmFrom(userLat, userLng)),
      priceLabel: salon.priceRangeLabel(),
      rating: salon.rating,
      reviewCount: salon.reviewCount,
      isOpen: salon.isOpenNow(),
      icon: LucideIcons.sparkles,
      accent: accent,
      onTap: onTap,
    );
  }

  factory VenueHubCard.fromFootballField(
    FootballField field, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    return VenueHubCard(
      name: field.name,
      subtitle: '${field.sizeSurfaceLabel} · ${field.address}',
      distanceLabel: formatDistanceKm(field.distanceKmFrom(userLat, userLng)),
      priceLabel: field.priceLabel,
      rating: field.rating,
      reviewCount: field.reviewCount,
      isOpen: field.isOpenNow(),
      icon: LucideIcons.trophy,
      accent: accent,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 88,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.18),
                          accent.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                    child: Icon(icon, color: accent, size: 32),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOpen ? 'Ochiq' : 'Yopiq',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const Spacer(),
                        Icon(LucideIcons.mapPin, size: 11, color: accent),
                        const SizedBox(width: 2),
                        Text(
                          distanceLabel,
                          style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
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

/// Joy haqida qisqa preview — bron qilishdan oldin.
Future<void> showVenuePreviewSheet(
  BuildContext context, {
  required BarberShop shop,
  required Color accent,
}) {
  final currency = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);
  final dist = formatDistanceKm(shop.distanceKmFrom(kDefaultUserLat, kDefaultUserLng));

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LucideIcons.scissors, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.address,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(
                icon: Icons.star_rounded,
                label: '${shop.rating} (${shop.reviewCount})',
                color: const Color(0xFFF59E0B),
              ),
              _PreviewChip(icon: LucideIcons.mapPin, label: dist, color: accent),
              _PreviewChip(
                icon: LucideIcons.clock,
                label: shop.isOpenNow() ? 'Hozir ochiq' : 'Yopiq',
                color: shop.isOpenNow() ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Xizmatlar va narxlar',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          ...shop.services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(s, style: const TextStyle(color: Color(0xFF334155)))),
                  Text(
                    currency.format(shop.prices[s] ?? BarberShop.defaultPriceForService(s)),
                    style: TextStyle(fontWeight: FontWeight.w700, color: accent),
                  ),
                ],
              ),
            ),
          ),
          if (shop.barbers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Ustalar: ${shop.barbers.map((b) => b.name).join(', ')}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BarberBookingScreen(shop: shop)),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Bron qilish', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PreviewChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Sartarosh hub — filtr + kartalar (2-bosqich).
class BarberHubSection extends StatefulWidget {
  final List<BarberShop> shops;
  final Color accentColor;

  const BarberHubSection({
    super.key,
    required this.shops,
    required this.accentColor,
  });

  @override
  State<BarberHubSection> createState() => _BarberHubSectionState();
}

class _BarberHubSectionState extends State<BarberHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<BarberShop> get _filtered {
    var list = List<BarberShop>.from(widget.shops);
    switch (_filter) {
      case HubListFilter.nearest:
        list.sort(
          (a, b) => a.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)
              .compareTo(b.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)),
        );
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        list = list.where((s) => s.isOpenNow()).toList();
      case HubListFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin sartaroshxonalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${items.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        HubFilterChips(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
          accent: widget.accentColor,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GlassSurface(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Bu filtr bo\'yicha sartaroshxona topilmadi',
                  style: TextStyle(color: GlassTokens.secondaryText(context)),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 198,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final shop = items[i];
                return VenueHubCard.fromBarberShop(
                  shop,
                  accent: widget.accentColor,
                  onTap: () => showVenuePreviewSheet(
                    context,
                    shop: shop,
                    accent: widget.accentColor,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Yaqin go'zallik salonlari — filtrlar bilan.
class SalonHubSection extends StatefulWidget {
  final List<BeautySalon> salons;
  final Color accentColor;

  const SalonHubSection({
    super.key,
    required this.salons,
    required this.accentColor,
  });

  @override
  State<SalonHubSection> createState() => _SalonHubSectionState();
}

class _SalonHubSectionState extends State<SalonHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<BeautySalon> get _filtered {
    var list = List<BeautySalon>.from(widget.salons);
    switch (_filter) {
      case HubListFilter.nearest:
        list.sort(
          (a, b) => a.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)
              .compareTo(b.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)),
        );
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        list = list.where((s) => s.isOpenNow()).toList();
      case HubListFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin salonlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text('${items.length} ta', style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context))),
            ],
          ),
        ),
        HubFilterChips(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
          accent: widget.accentColor,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GlassSurface(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Bu filtr bo\'yicha salon topilmadi',
                  style: TextStyle(color: GlassTokens.secondaryText(context)),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 198,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final salon = items[i];
                return VenueHubCard.fromBeautySalon(
                  salon,
                  accent: widget.accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SalonBookingScreen(salon: salon)),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Uyga boradigan mobil kosmetologlar.
class MobileSalonHubSection extends StatelessWidget {
  final List<Master> stylists;
  final Color accentColor;

  const MobileSalonHubSection({
    super.key,
    required this.stylists,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (stylists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Uyga boradigan kosmetologlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text('${stylists.length} ta', style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context))),
            ],
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stylists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = stylists[i];
              final minPrice = s.prices.values.isEmpty ? 50000 : s.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 150,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: s,
                        category: ServiceHubKind.salon,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(LucideIcons.sparkles, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: GlassTokens.primaryText(context))),
                        Text(s.specialty, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${(minPrice / 1000).round()}k+', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Uyga boradigan mobil sartaroshlar.
class MobileBarberHubSection extends StatelessWidget {
  final List<Master> barbers;
  final Color accentColor;

  const MobileBarberHubSection({
    super.key,
    required this.barbers,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (barbers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Uyga boradigan sartaroshlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${barbers.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: barbers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final b = barbers[i];
              return _MobileBarberCard(
                master: b,
                accent: accentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: b,
                      category: ServiceHubKind.sartarosh,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MobileBarberCard extends StatelessWidget {
  final Master master;
  final Color accent;
  final VoidCallback onTap;

  const _MobileBarberCard({
    required this.master,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = master.prices.values.isEmpty
        ? 35000
        : master.prices.values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassSurface(
          padding: const EdgeInsets.all(14),
          borderRadius: GlassTokens.radiusLg,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(LucideIcons.scissors, color: accent, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Uyga',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              master.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: GlassTokens.primaryText(context),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text('${master.rating}', style: const TextStyle(fontSize: 11)),
              ],
            ),
            const Spacer(),
            Text(
              'dan ${NumberFormat('#,###').format(minPrice)} so\'m',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Futbol maydoni preview — bron oldidan.
Future<void> showFieldPreviewSheet(
  BuildContext context, {
  required FootballField field,
  required Color accent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GlassSurface(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      borderRadius: GlassTokens.radiusXl,
      opacity: 0.95,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: GlassTokens.primaryText(ctx),
            ),
          ),
          const SizedBox(height: 6),
          Text(field.address, style: TextStyle(color: GlassTokens.secondaryText(ctx))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(icon: field.surface.icon, label: field.surface.label, color: field.surface.color),
              _PreviewChip(icon: LucideIcons.users, label: field.size.shortLabel, color: accent),
              _PreviewChip(icon: LucideIcons.banknote, label: field.priceLabel, color: accent),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FootballFieldBookingScreen(field: field),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Bron qilish', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Futbol hub — filtr + kartalar.
class FootballHubSection extends StatefulWidget {
  final List<FootballField> fields;
  final Color accentColor;

  const FootballHubSection({
    super.key,
    required this.fields,
    required this.accentColor,
  });

  @override
  State<FootballHubSection> createState() => _FootballHubSectionState();
}

class _FootballHubSectionState extends State<FootballHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<FootballField> get _filtered {
    var list = List<FootballField>.from(widget.fields);
    switch (_filter) {
      case HubListFilter.nearest:
        list.sort(
          (a, b) => a.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)
              .compareTo(b.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)),
        );
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        list = list.where((f) => f.isOpenNow()).toList();
      case HubListFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin futbol maydonlari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text('${items.length} ta', style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context))),
            ],
          ),
        ),
        HubFilterChips(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
          accent: widget.accentColor,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(child: Text('Maydon topilmadi', style: TextStyle(color: GlassTokens.secondaryText(context)))),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final f = items[i];
                return SizedBox(
                  width: 280,
                  child: VenueHubCard.fromFootballField(
                    f,
                    accent: widget.accentColor,
                    onTap: () => showFieldPreviewSheet(context, field: f, accent: widget.accentColor),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Tozalash — yakka tozalovchi va jamoalar.
class CleaningHubSection extends StatelessWidget {
  final List<Master> cleaners;
  final Color accentColor;

  const CleaningHubSection({
    super.key,
    required this.cleaners,
    required this.accentColor,
  });

  List<Master> get _solo => cleaners.where((m) => m.isCleaningSolo).toList();
  List<Master> get _teams => cleaners.where((m) => m.isCleaningTeam).toList();

  @override
  Widget build(BuildContext context) {
    if (cleaners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_solo.isNotEmpty) _section(context, 'Yakka tozalovchilar', _solo, LucideIcons.user),
        if (_teams.isNotEmpty) _section(context, 'Tozalash jamoalari', _teams, LucideIcons.users),
        if (_solo.isEmpty && _teams.isEmpty)
          _section(context, 'Tozalash xizmatlari', cleaners, LucideIcons.sprayCan),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Master> items, IconData badgeIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${items.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _CleaningCard(
              master: items[i],
              accent: accentColor,
              badgeIcon: badgeIcon,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderProfileScreen(
                    master: items[i],
                    category: ServiceHubKind.tozalash,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CleaningCard extends StatelessWidget {
  final Master master;
  final Color accent;
  final IconData badgeIcon;
  final VoidCallback onTap;

  const _CleaningCard({
    required this.master,
    required this.accent,
    required this.badgeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = master.prices.values.isEmpty
        ? 200000
        : master.prices.values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 158,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassSurface(
          padding: const EdgeInsets.all(14),
          borderRadius: GlassTokens.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(LucideIcons.sprayCan, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(badgeIcon, size: 12, color: accent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                master.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              Text(
                master.isCleaningTeam && master.teamSize != null
                    ? 'Jamoa · ${master.teamSize} kishi'
                    : master.isMasterBrigade && master.teamSize != null
                        ? 'Brigada · ${master.teamSize} kishi'
                        : master.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text('${master.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${(minPrice / 1000).round()}k+',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Usta chaqirish — yakka usta va brigadalar.
class MasterDispatchHubSection extends StatelessWidget {
  final List<Master> masters;
  final Color accentColor;

  const MasterDispatchHubSection({
    super.key,
    required this.masters,
    required this.accentColor,
  });

  List<Master> get _solo => masters.where((m) => m.isMasterSolo).toList();
  List<Master> get _brigades => masters.where((m) => m.isMasterBrigade).toList();

  @override
  Widget build(BuildContext context) {
    if (masters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_solo.isNotEmpty) _section(context, 'Yakka ustalar', _solo, LucideIcons.user),
        if (_brigades.isNotEmpty) _section(context, 'Ustalar brigadasi', _brigades, LucideIcons.users),
        if (_solo.isEmpty && _brigades.isEmpty)
          _section(context, 'Ustalar', masters, LucideIcons.hammer),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Master> items, IconData badgeIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${items.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _MasterDispatchCard(
              master: items[i],
              accent: accentColor,
              badgeIcon: badgeIcon,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderProfileScreen(
                    master: items[i],
                    category: ServiceHubKind.usta,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MasterDispatchCard extends StatelessWidget {
  final Master master;
  final Color accent;
  final IconData badgeIcon;
  final VoidCallback onTap;

  const _MasterDispatchCard({
    required this.master,
    required this.accent,
    required this.badgeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = master.prices.values.isEmpty
        ? 100000
        : master.prices.values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 158,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassSurface(
          padding: const EdgeInsets.all(14),
          borderRadius: GlassTokens.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(LucideIcons.hammer, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(badgeIcon, size: 12, color: accent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                master.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              Text(
                master.isMasterBrigade && master.teamSize != null
                    ? 'Brigada · ${master.teamSize} kishi'
                    : master.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text('${master.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${(minPrice / 1000).round()}k+',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Elektrik — yakka ustalar, uyga chaqiruv.
class ElectricianHubSection extends StatelessWidget {
  final List<Master> electricians;
  final Color accentColor;

  const ElectricianHubSection({
    super.key,
    required this.electricians,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (electricians.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin elektriklar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${electricians.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: electricians.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final e = electricians[i];
              final minPrice = e.prices.values.isEmpty
                  ? 100000
                  : e.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: e,
                        category: ServiceHubKind.elektrik,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(LucideIcons.zap, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          e.serviceArea ?? 'Uyga xizmat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${e.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class PlumberHubSection extends StatelessWidget {
  final List<Master> plumbers;
  final Color accentColor;

  const PlumberHubSection({
    super.key,
    required this.plumbers,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (plumbers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin santexniklar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${plumbers.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: plumbers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final p = plumbers[i];
              final minPrice = p.prices.values.isEmpty
                  ? 100000
                  : p.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: p,
                        category: ServiceHubKind.santexnik,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(LucideIcons.droplet, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          p.serviceArea ?? 'Uyga xizmat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${p.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class CourierHubSection extends StatelessWidget {
  final List<CourierService> couriers;
  final Color accentColor;

  const CourierHubSection({
    super.key,
    required this.couriers,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (couriers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin kuryerlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${couriers.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: couriers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = couriers[i];
              final minPrice = c.prices.values.isEmpty
                  ? 25000
                  : c.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourierBookingScreen(service: c),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(LucideIcons.bike, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          c.serviceArea ?? c.vehicleType.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${c.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AutoHelpHubSection extends StatelessWidget {
  final List<AutoMobileService> units;
  final Color accentColor;

  const AutoHelpHubSection({
    super.key,
    required this.units,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mobil avto-yordam',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${units.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final u = units[i];
              final minPrice = u.prices.values.isEmpty
                  ? 80000
                  : u.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AutoHelpBookingScreen(service: u),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(u.vehicleType.icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          u.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          u.serviceArea ?? u.vehicleType.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${u.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AutoWorkshopHubSection extends StatelessWidget {
  final List<AutoWorkshop> workshops;
  final Color accentColor;

  const AutoWorkshopHubSection({
    super.key,
    required this.workshops,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (workshops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin ustaxonalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${workshops.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: workshops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final w = workshops[i];
              final minPrice = w.prices.values.isEmpty
                  ? 80000
                  : w.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AutoWorkshopBookingScreen(workshop: w),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF334155).withValues(alpha: 0.15),
                          child: Icon(LucideIcons.home, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          w.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          w.specializations.take(2).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${w.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AcHubSection extends StatelessWidget {
  final List<Master> technicians;
  final Color accentColor;

  const AcHubSection({
    super.key,
    required this.technicians,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin konditsioner ustalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${technicians.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: technicians.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final t = technicians[i];
              final minPrice = t.prices.values.isEmpty
                  ? 180000
                  : t.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: t,
                        category: ServiceHubKind.konditsioner,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Icon(LucideIcons.wind, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          t.serviceArea ?? 'Uyga xizmat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${t.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class NannyHubSection extends StatelessWidget {
  final List<NannyService> nannies;
  final Color accentColor;

  const NannyHubSection({
    super.key,
    required this.nannies,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (nannies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tasdiqlangan enagalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${nannies.length} ta',
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: nannies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final n = nannies[i];
              final minPrice = n.prices.values.isEmpty
                  ? 80000
                  : n.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 168,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NannyProfileScreen(nanny: n),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(14),
                    borderRadius: GlassTokens.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: accentColor.withValues(alpha: 0.15),
                              child: Icon(LucideIcons.baby, color: accentColor, size: 20),
                            ),
                            if (n.isVerified) ...[
                              const Spacer(),
                              Icon(LucideIcons.badgeCheck, size: 16, color: accentColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          n.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          '${n.experienceYears} yil • ${n.ageGroupsLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text('${n.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Repetitorlar — onlayn, uyga, markazda.
class TutorHubSection extends StatelessWidget {
  const TutorHubSection({
    super.key,
    required this.tutors,
    required this.accentColor,
  });

  final List<TutorService> tutors;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (tutors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Repetitorlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GlassTokens.primaryText(context),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tutors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final t = tutors[i];
              final minPrice = t.prices.values.isEmpty
                  ? 100000
                  : t.prices.values.reduce((a, b) => a < b ? a : b);
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TutorProfileScreen(tutor: t),
                  ),
                ),
                child: GlassSurface(
                  borderRadius: GlassTokens.radiusLg,
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: accentColor.withValues(alpha: 0.15),
                              child: Icon(LucideIcons.bookOpen, color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: GlassTokens.primaryText(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.subjectsLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: GlassTokens.secondaryText(context),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(LucideIcons.star, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              t.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: GlassTokens.primaryText(context),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.lessonModesLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: GlassTokens.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
