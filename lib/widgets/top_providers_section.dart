import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/app_config.dart';
import '../l10n/locale_controller.dart';
import '../models/service_hub_kind.dart';
import '../screens/service_hub_screen.dart';
import '../services/top_providers_service.dart';
import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';

/// Bosh sahifaning ENG PASTIDA — "Top reytingli" provayderlar ro'yxati.
///
/// Xulq-atvori:
///  • Bir marta 10 tadan yuklanadi, eng pastdagi "Yana" tugmasi bosilganda
///    keyingi 10 tasi ro'yxat OXIRIGA qo'shiladi (sahifa almashmaydi).
///  • Yuqorida soha bo'yicha filtr chiplar ("Barchasi", "Sartarosh", ...).
///  • Har qatorda reyting aniq ko'rsatiladi.
///  • Provayder bosilsa — o'sha sohaning xizmat ro'yxati ochiladi.
class TopProvidersSection extends StatefulWidget {
  const TopProvidersSection({super.key});

  @override
  State<TopProvidersSection> createState() => _TopProvidersSectionState();
}

class _TopProvidersSectionState extends State<TopProvidersSection> {
  final _service = TopProvidersService();

  /// Filtr uchun sohalar. null = "Barchasi".
  static const _filterKinds = <ServiceHubKind?>[
    null,
    ServiceHubKind.sartarosh,
    ServiceHubKind.salon,
    ServiceHubKind.usta,
    ServiceHubKind.elektrik,
    ServiceHubKind.santexnik,
    ServiceHubKind.tozalash,
    ServiceHubKind.texnikaUstasi,
    ServiceHubKind.telefonUsta,
    ServiceHubKind.kompyuterUsta,
    ServiceHubKind.itXizmat,
    ServiceHubKind.massajHijoma,
    ServiceHubKind.stomatologiya,
    ServiceHubKind.enaga,
    ServiceHubKind.repetitor,
    ServiceHubKind.kuryerlik,
    ServiceHubKind.avtoYordam,
    ServiceHubKind.futbol,
    ServiceHubKind.oshxona,
  ];

  ServiceHubKind? _selected;
  final _items = <TopProvider>[];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Birinchi sahifani yuklaydi (filtr almashganda ham).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _items.clear();
    });
    final res = await _service.fetch(kind: _selected, page: 1);
    if (!mounted) return;
    setState(() {
      _items.addAll(res.items);
      _hasMore = res.hasMore;
      _loading = false;
    });
  }

  /// "Yana" — keyingi sahifani ro'yxat OXIRIGA qo'shadi.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final res = await _service.fetch(kind: _selected, page: next);
    if (!mounted) return;
    setState(() {
      _page = next;
      _items.addAll(res.items);
      _hasMore = res.hasMore;
      _loadingMore = false;
    });
  }

  void _openProvider(TopProvider p) {
    final kind = p.kind;
    if (kind == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ServiceHubScreen(kind: kind, accentColor: kind.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        const SizedBox(height: 12),
        _filterChips(context),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_items.isEmpty)
          _empty(context)
        else ...[
          // Ro'yxat — bosh sahifa o'zi scroll bo'lgani uchun shrinkWrap.
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _items.length,
            separatorBuilder: (context, _) => Divider(
              height: 1,
              thickness: 1,
              color: GlassTokens.glassBorder(context),
            ),
            itemBuilder: (_, i) => _TopProviderTile(
              provider: _items[i],
              // O'rin raqami: 1, 2, 3...
              position: i + 1,
              onTap: () => _openProvider(_items[i]),
            ),
          ),
          if (_hasMore) ...[
            const SizedBox(height: 12),
            _moreButton(context),
          ],
        ],
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.trophy, size: 20, color: GlassTokens.primaryText(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Top reytingli'.tr,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: GlassTokens.primaryText(context),
            ),
          ),
        ),
        if (!_loading && _items.isNotEmpty)
          Text(
            '${_items.length} ta',
            style: TextStyle(
              fontSize: 13,
              color: GlassTokens.secondaryText(context),
            ),
          ),
      ],
    );
  }

  /// Soha bo'yicha filtr chiplari.
  Widget _filterChips(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _filterKinds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final kind = _filterKinds[i];
          final selected = kind == _selected;
          final label = kind == null ? 'Barchasi'.tr : kind.title.tr;
          return _FilterChip(
            label: label,
            icon: kind?.icon,
            selected: selected,
            onTap: () {
              if (selected) return;
              setState(() => _selected = kind);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _moreButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        child: InkWell(
          onTap: _loadingMore ? null : _loadMore,
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
              border: Border.all(color: GlassTokens.glassBorder(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loadingMore) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Yuklanmoqda...'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Yana'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.chevronDown,
                      size: 17, color: GlassTokens.primaryText(context)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final secondary = GlassTokens.secondaryText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.starOff, size: 34, color: secondary),
            const SizedBox(height: 10),
            Text(
              _selected == null
                  ? 'Hozircha reytingli provayder yo\'q'.tr
                  : 'Bu sohada reytingli provayder yo\'q'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ro'yxatdagi bitta provayder qatori — o'rin, banner, nom, soha, reyting.
class _TopProviderTile extends StatelessWidget {
  final TopProvider provider;
  final int position;
  final VoidCallback onTap;

  const _TopProviderTile({
    required this.provider,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = GlassTokens.primaryText(context);
    final secondary = GlassTokens.secondaryText(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _PositionBadge(position: position),
              const SizedBox(width: 10),
              _Avatar(provider: provider),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.categoryLabel.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: secondary,
                            ),
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(fontSize: 11.5, color: secondary),
                        ),
                        Flexible(
                          child: Text(
                            provider.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 11.5, color: secondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RatingBadge(
                rating: provider.rating,
                reviewCount: provider.reviewCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O'rin raqami. Birinchi 3 ta — medal ranglari.
class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final isTop1 = position == 1;
    final isTop2Or3 = position == 2 || position == 3;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop1
            ? const Color(0xFF102A43)
            : (isTop2Or3
                ? GlassTokens.glassBorder(context).withValues(alpha: 0.8)
                : GlassTokens.glassBorder(context).withValues(alpha: 0.4)),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$position',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isTop1
              ? Colors.white
              : (isTop2Or3
                  ? GlassTokens.primaryText(context)
                  : GlassTokens.secondaryText(context)),
        ),
      ),
    );
  }
}

/// Provayder rasmi yoki soha ikonkasi.
class _Avatar extends StatelessWidget {
  final TopProvider provider;

  const _Avatar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final url = provider.coverUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      child: SizedBox(
        width: 46,
        height: 46,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: AppConfig.formatImageUrl(url),
                fit: BoxFit.cover,
                memCacheWidth: 128,
                memCacheHeight: 128,
                maxWidthDiskCache: 256,
                fadeInDuration: const Duration(milliseconds: 120),
                errorWidget: (_, _, _) => _fallback(context),
                placeholder: (_, _) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => ColoredBox(
        color: GlassTokens.glassFill(context),
        child: Center(
          child: Icon(
            provider.icon,
            size: 22,
            color: GlassTokens.secondaryText(context),
          ),
        ),
      );
}

/// Reyting — ro'yxatning asosiy ma'lumoti, shuning uchun ajratib ko'rsatiladi.
class _RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingBadge({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: GlassTokens.glassFill(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GlassTokens.glassBorder(context), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ),
        if (reviewCount > 0) ...[
          const SizedBox(height: 2),
          Text(
            '$reviewCount ${'sharh'.tr}',
            style: TextStyle(
              fontSize: 10.5,
              color: GlassTokens.secondaryText(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// Soha filtri chipi.
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: const Color(0xFF102A43),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF102A43).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: GlassTokens.glassFill(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GlassTokens.glassBorder(context)),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : GlassTokens.secondaryText(context),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
