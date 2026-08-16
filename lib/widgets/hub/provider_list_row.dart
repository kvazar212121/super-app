import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../screens/service_hub/service_catalog_screen.dart';
import 'provider_banner.dart';
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

  /// Qator eng kam balandligi. QAT'IY emas: foydalanuvchi tizimda shrift
  /// o'lchamini kattalashtirsa qator MATN hisobiga o'sadi, kontent kesilmaydi.
  ///
  /// MUHIM: qator balandligini faqat MATN belgilaydi, banner rasm EMAS.
  /// Shu sabab banner `Positioned` bilan joylashtirilgan — aks holda tik
  /// (vertikal) rasm yuklagan provayder butun qatorni cho'zib yuborardi.
  static const double minHeight = 108;

  /// Banner kengligi. Balandlik bilan nisbati [bannerAspectRatio] ga teng.
  static const double _bannerWidth = 132;

  /// Banner uchun TAVSIYA ETILADIGAN nisbat — eni 1.2, bo'yi 1 (ya'ni 1.2:1).
  /// Provayder boshqa nisbatda rasm yuklasa ham qator ko'rinishi buzilmaydi:
  /// rasm markazidan qirqib olinadi ([BoxFit.cover] + markazga tekislash).
  static const double bannerAspectRatio = 1.2;

  @override
  Widget build(BuildContext context) {
    final surface = GlassTokens.glassFill(context);
    final cover = entry.resolvedCoverUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => entry.onOpen(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: minHeight),
          decoration: BoxDecoration(
            color:
                selected ? accent.withValues(alpha: 0.07) : Colors.transparent,
          ),
          // Stack o'lchamini faqat pastdagi (positioned bo'lmagan) matn
          // belgilaydi; banner esa qolgan balandlikka cho'ziladi.
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _bannerWidth,
                child: ProviderBanner(
                  coverUrl: cover,
                  icon: entry.icon,
                  accent: accent,
                  surface: surface,
                ),
              ),
              Padding(
                // Chapda banner kengligi + kichik bo'shliq: gradient matn
                // ostiga ozgina kirib turadi.
                padding: const EdgeInsets.fromLTRB(_bannerWidth + 4, 10, 14, 10),
                child: _Info(
                  entry: entry,
                  accent: accent,
                  distanceKmValue: distanceKmValue,
                ),
              ),
            ],
          ),
        ),
      ),
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
      mainAxisSize: MainAxisSize.min,
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
        // Reyting · masofa · narx.
        // BITTA qatorda: uzun masofa ("11185.6 km") yoki uzun narx
        // ("15000 — 25000 so'm") bo'lsa ham chetga chiqmasligi uchun
        // matnli qismlar siqiluvchan (Flexible + ellipsis).
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
              Flexible(
                child: Text(
                  ' (${entry.reviewCount})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: secondary),
                ),
              ),
            if (distanceKmValue != null) ...[
              _dot(secondary),
              Icon(LucideIcons.mapPin, size: 12, color: secondary),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  formatDistanceKm(distanceKmValue!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: secondary),
                ),
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
