import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../models/service_hub_kind.dart';
import '../screens/barber_map_screen.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

class SearchResultsWidget extends StatefulWidget {
  final String query;
  const SearchResultsWidget({super.key, required this.query});

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  final _api = ApiService();
  List<BarberShop> _providers = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.query.isEmpty) {
        final res = await _api.getProviders(categoryKey: 'sartarosh', perPage: 20);
        final items = (res['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _providers = items.map(BarberShop.fromProviderJson).toList();
        _categories = [];
      } else {
        final cats = await _api.getCategories();
        _categories = cats.cast<Map<String, dynamic>>().where((c) {
          final title = (c['title_uz'] as String? ?? '').toLowerCase();
          return title.contains(widget.query.toLowerCase());
        }).toList();

        final res = await _api.getProviders(search: widget.query, perPage: 30);
        final items = (res['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _providers = items.map(BarberShop.fromProviderJson).toList();
      }
    } catch (e) {
      _error = 'Ma\'lumotlarni yuklab bo\'lmadi';
      _providers = [];
      _categories = [];
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: GlassTokens.secondaryText(context))),
      );
    }

    if (widget.query.isEmpty) {
      if (_providers.isEmpty) {
        return Center(
          child: Text(
            'Provayderlar topilmadi',
            style: TextStyle(color: GlassTokens.secondaryText(context)),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yaqin atrofdagi xizmatlar',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _providers.length,
              itemBuilder: (ctx, i) => _ShopListItem(shop: _providers[i]),
            ),
          ),
        ],
      );
    }

    final categoryTiles = _categories.map((c) {
      final key = c['key'] as String? ?? '';
      final kind = ServiceHubKind.values.where((e) => e.name == key).firstOrNull;
      return _CategoryTile(
        title: c['title_uz'] as String? ?? key,
        icon: kind?.icon ?? LucideIcons.layoutGrid,
        color: _parseColor(c['accent_color'] as String?),
      );
    }).toList();

    if (categoryTiles.isEmpty && _providers.isEmpty) {
      return Center(
        child: Text(
          'Natija topilmadi',
          style: TextStyle(color: GlassTokens.secondaryText(context)),
        ),
      );
    }

    return ListView(
      children: [
        ...categoryTiles,
        ..._providers.map((p) => _ShopListItem(shop: p)),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      borderRadius: GlassTokens.radiusMd,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: GlassTokens.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopListItem extends StatelessWidget {
  final BarberShop shop;
  const _ShopListItem({required this.shop});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: GlassTokens.radiusLg,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BarberMapScreen(shops: [shop])),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: const Icon(LucideIcons.scissors, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shop.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: GlassTokens.secondaryText(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  Text(
                    ' ${shop.rating}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                ],
              ),
              Text(
                '${shop.reviewCount} sharh',
                style: TextStyle(
                  fontSize: 11,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
