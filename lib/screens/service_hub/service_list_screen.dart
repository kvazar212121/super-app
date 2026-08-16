import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../models/service_hub_kind.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/hub/hub_filter_chips.dart';
import '../../widgets/hub/provider_list_row.dart';
import 'saved_places_screen.dart';
import 'service_catalog_screen.dart';
import 'service_map_screen.dart';

/// EKRAN 1 — xizmat provayderlari ro'yxati (yangi dizayn).
///
/// Tuzilishi (dizayn maketiga muvofiq):
///   • Tepada: qidiruv maydoni + "xaritadan" tugmasi
///   • O'rtada: to'liq enli vertikal qatorlar (banner chapda, gradientda
///     fonga singiydi; o'ngda barcha ma'lumot va teglar)
///   • Pastda: "saqlanganlar" va "filtrlar" tugmalari
///
/// Funksionallik o'zgarmaydi — bron oqimi, filtr mantiqi va ma'lumot manbai
/// ([CatalogEntry]) avvalgidek qoladi.
class ServiceListScreen extends StatefulWidget {
  final ServiceHubKind kind;
  final Color accent;
  final List<CatalogEntry> entries;

  /// Subkategoriyalar — endi faqat "filtrlar" modalida ko'rinadi.
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  /// true bo'lsa — o'z GlassScaffold'ini yaratmaydi (ServiceHubScreen ichida
  /// allaqachon scaffold/appbar bor, ikki marta sarlavha chiqmasligi uchun).
  final bool embedded;

  const ServiceListScreen({
    super.key,
    required this.kind,
    required this.accent,
    required this.entries,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
    this.embedded = false,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _searchController = TextEditingController();

  HubListFilter _sort = HubListFilter.all;
  String _query = '';

  double _userLat = kDefaultUserLat;
  double _userLng = kDefaultUserLng;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(const Duration(seconds: 9));
      if (!mounted) return;
      setState(() {
        _userLat = p.latitude;
        _userLng = p.longitude;
      });
    } catch (_) {}
  }

  double _distanceOf(CatalogEntry e) =>
      distanceKm(_userLat, _userLng, e.latitude, e.longitude);

  /// Qidiruv + saralash + subkategoriya filtri qo'llangan ro'yxat.
  List<CatalogEntry> get _visible {
    var list = [...widget.entries];

    // Qidiruv — nom, manzil va teglar bo'yicha.
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.subtitle.toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    switch (_sort) {
      case HubListFilter.nearest:
        list.sort((a, b) => _distanceOf(a).compareTo(_distanceOf(b)));
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        list = list.where((e) => e.isOpen).toList();
      case HubListFilter.all:
        // Standart holatda ham eng yaqindan ko'rsatamiz (foydali tartib).
        list.sort((a, b) => _distanceOf(a).compareTo(_distanceOf(b)));
    }
    return list;
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ServiceMapScreen(
          title: 'Xarita'.tr,
          accent: widget.accent,
          markerIcon: widget.kind.icon,
          entries: _visible,
          categories: widget.categories,
          selectedCategory: widget.selectedCategory,
          onCategorySelected: (v) {
            widget.onCategorySelected?.call(v);
            if (mounted) setState(() {});
          },
          sortFilter: _sort,
          onSortChanged: (f) {
            if (mounted) setState(() => _sort = f);
          },
        ),
      ),
    );
  }

  void _openFilters() {
    showHubFilterSheet(
      context,
      accent: widget.accent,
      categories: widget.categories,
      selectedCategory: widget.selectedCategory,
      onCategorySelected: (v) {
        widget.onCategorySelected?.call(v);
        if (mounted) setState(() {});
      },
      selected: _sort,
      onChanged: (f) => setState(() => _sort = f),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    final content = Column(
        children: [
          // ── Tepa: qidiruv + "xaritadan" ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 10),
                _MapButton(accent: widget.accent, onTap: _openMap),
              ],
            ),
          ),

          // ── O'rta: provayder qatorlari ──
          Expanded(
            child: items.isEmpty
                ? _EmptyState(query: _query)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: items.length,
                    separatorBuilder: (context, _) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: GlassTokens.glassBorder(context),
                    ),
                    itemBuilder: (_, i) {
                      final e = items[i];
                      return ProviderListRow(
                        entry: e,
                        accent: widget.accent,
                        distanceKmValue: _distanceOf(e),
                      );
                    },
                  ),
          ),

          // ── Past: saqlanganlar + filtrlar ──
          _BottomBar(
            accent: widget.accent,
            filtersActive:
                _sort != HubListFilter.all || widget.selectedCategory != null,
            onSaved: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SavedPlacesScreen(category: widget.kind),
              ),
            ),
            onFilters: _openFilters,
          ),
        ],
    );

    if (widget.embedded) return content;
    return GlassScaffold(
      showBackButton: true,
      title: widget.kind.title.tr,
      body: content,
    );
  }
}

/// Qidiruv maydoni — sodda, chegarali (maketdagidek).
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: GlassTokens.primaryText(context)),
      decoration: InputDecoration(
        hintText: 'Qidiruv maydoni'.tr,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: Icon(
          LucideIcons.search,
          size: 18,
          color: GlassTokens.secondaryText(context),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(LucideIcons.x,
                    size: 16, color: GlassTokens.secondaryText(context)),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: GlassTokens.glassFill(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: BorderSide(color: GlassTokens.glassBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: BorderSide(color: GlassTokens.glassBorder(context)),
        ),
      ),
    );
  }
}

/// "xaritadan" tugmasi — to'liq ekranli xaritaga o'tadi.
class _MapButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _MapButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GlassTokens.glassFill(context),
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
            border: Border.all(color: GlassTokens.glassBorder(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.map, size: 18, color: accent),
              const SizedBox(width: 7),
              Text(
                'Xaritadan'.tr,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastki doimiy panel — "saqlanganlar" va "filtrlar".
class _BottomBar extends StatelessWidget {
  final Color accent;
  final bool filtersActive;
  final VoidCallback onSaved;
  final VoidCallback onFilters;

  const _BottomBar({
    required this.accent,
    required this.filtersActive,
    required this.onSaved,
    required this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        border: Border(
          top: BorderSide(color: GlassTokens.glassBorder(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: _BarButton(
                  icon: LucideIcons.bookmark,
                  label: 'Saqlanganlar'.tr,
                  accent: accent,
                  filled: false,
                  onTap: onSaved,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BarButton(
                  icon: LucideIcons.slidersHorizontal,
                  label: 'Filtrlar'.tr,
                  accent: accent,
                  filled: true,
                  showDot: filtersActive,
                  onTap: onFilters,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool filled;
  final bool showDot;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.filled,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : accent;
    return Material(
      color: filled ? accent : accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (showDot) ...[
                const SizedBox(width: 7),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bo'sh holat — natija topilmadi.
class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final secondary = GlassTokens.secondaryText(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 44, color: secondary),
            const SizedBox(height: 14),
            Text(
              query.isEmpty
                  ? 'Hozircha provayder yo\'q'.tr
                  : 'Hech narsa topilmadi'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              query.isEmpty
                  ? 'Tez orada bu bo\'limda xizmatlar paydo bo\'ladi'.tr
                  : 'Boshqa so\'z bilan qidiring yoki filtrni tozalang'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}
