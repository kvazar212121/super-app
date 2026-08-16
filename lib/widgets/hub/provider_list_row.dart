import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';
import '../../screens/service_hub/service_catalog_screen.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';

/// Xizmat ro'yxatidagi BITTA qator (yangi dizayn).
///
/// Tuzilishi (rasmga muvofiq):
///   ┌──────────────┬──────────────────────────────┐
///   │  BANNER      │  nom                         │
///   │  (chapda,    │  ★ reyting · masofa · narx   │
///   │   o'ngga     │  [teg] [teg] [teg]           │
///   │   gradientda │  Ochiq / Yopiq               │
///   │   singiydi)  │                              │
///   └──────────────┴──────────────────────────────┘
///
/// Banner rasm chap tarafda joylashadi va o'ng tomonga qarab fon rangiga
/// OZGINA singib ketadi — matn bilan orasida qattiq chegara qolmaydi.
class ProviderListRow extends StatelessWidget {
  final CatalogEntry entry;
  final Color accent;

  /// Foydalanuvchidan masofa (km). null bo'lsa masofa ko'rsatilmaydi.
  final double? distanceKmValue;

  /// Qator bosilganda. Berilmasa — [entry.onOpen] chaqiriladi.
  final VoidCallback? onTap;

  /// Tanlangan holat (xaritadan qaytganda ajratib ko'rsatish uchun).
  final bool selected;

  const ProviderListRow({
    super.key,
    required this.entry,
    required this.accent,
    this.distanceKmValue,
    this.onTap,
    this.selected = false,
  });

  /// Qator balandligi — barcha xizmatlar uchun bir xil.
  static const double height = 108;

  /// Banner kengligi (gradient singish zonasi shu ichida).
  static const double _bannerWidth = 132;

  @override
  Widget build(BuildContext context) {
    final surface = GlassTokens.glassFill(context);
    final cover = entry.resolvedCoverUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => entry.onOpen(context),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.07) : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Banner(
                coverUrl: cover,
                icon: entry.icon,
                accent: accent,
                surface: surface,
              ),
              Expanded(
                child: Padding(
                  // Chapda kichik padding — banner gradienti matn ostiga
                  // ozgina kirib turadi, shuning uchun 4 yetarli.
                  padding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
                  child: _Info(
                    entry: entry,
                    accent: accent,
                    distanceKmValue: distanceKmValue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chapdagi banner — rasm + o'ngga qarab fon rangiga singiydigan gradient.
class _Banner extends StatelessWidget {
  final String? coverUrl;
  final IconData icon;
  final Color accent;
  final Color surface;

  const _Banner({
    required this.coverUrl,
    required this.icon,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProviderListRow._bannerWidth,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: AppConfig.formatImageUrl(coverUrl!),
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _fallback(),
              placeholder: (_, _) => _fallback(),
            )
          else
            _fallback(),
          // Rasm o'ng chekkasida fon rangiga SINGIYDI (ozgina, ~40%).
          // Shu tufayli rasm bilan matn orasida qattiq chegara ko'rinmaydi.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  surface.withValues(alpha: 0),
                  surface.withValues(alpha: 0),
                  surface.withValues(alpha: 0.75),
                  surface,
                ],
                stops: const [0, 0.55, 0.85, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: accent.withValues(alpha: 0.16),
      child: Center(child: Icon(icon, color: accent, size: 30)),
    );
  }
}

/// O'ng tarafdagi ma'lumotlar — nom, reyting/masofa/narx, teglar, holat.
class _Info extends StatelessWidget {
  final CatalogEntry entry;
  final Color accent;
  final double? distanceKmValue;

  const _Info({
    required this.entry,
    required this.accent,
    required this.distanceKmValue,
  });

  @override
  Widget build(BuildContext context) {
    final primary = GlassTokens.primaryText(context);
    final secondary = GlassTokens.secondaryText(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Nom + ochiq/yopiq nuqtasi
        Row(
          children: [
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StatusDot(isOpen: entry.isOpen),
          ],
        ),
        const SizedBox(height: 3),
        // Manzil / qisqa izoh
        Text(
          entry.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: secondary),
        ),
        const SizedBox(height: 6),
        // Reyting · masofa · narx
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 2),
            Text(
              entry.rating > 0 ? entry.rating.toStringAsFixed(1) : '—',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            if (entry.reviewCount > 0)
              Text(
                ' (${entry.reviewCount})',
                style: TextStyle(fontSize: 11, color: secondary),
              ),
            if (distanceKmValue != null) ...[
              _dot(secondary),
              Icon(LucideIcons.mapPin, size: 12, color: secondary),
              const SizedBox(width: 3),
              Text(
                formatDistanceKm(distanceKmValue!),
                style: TextStyle(fontSize: 11.5, color: secondary),
              ),
            ],
            if (entry.priceLabel.isNotEmpty) ...[
              _dot(secondary),
              Flexible(
                child: Text(
                  entry.priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Teglar — xizmat turlari (maksimum 3 ta sig'gani)
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 20,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: entry.tags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (_, i) => _Tag(label: entry.tags[i], accent: accent),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dot(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Text('·', style: TextStyle(fontSize: 12, color: color)),
  );
}

/// Xizmat turi tegi — ixcham chip.
class _Tag extends StatelessWidget {
  final String label;
  final Color accent;

  const _Tag({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

/// Ochiq/yopiq holat — kichik rangli nuqta + yozuv.
class _StatusDot extends StatelessWidget {
  final bool isOpen;

  const _StatusDot({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF16A34A) : const Color(0xFF94A3B8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          isOpen ? 'Ochiq' : 'Yopiq',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
