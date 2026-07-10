import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../screens/barber_map_screen.dart';
import '../services/api_service.dart';

class RecommendedSectionWidget extends StatefulWidget {
  const RecommendedSectionWidget({super.key});

  @override
  State<RecommendedSectionWidget> createState() =>
      _RecommendedSectionWidgetState();
}

class _RecommendedSectionWidgetState extends State<RecommendedSectionWidget> {
  final _api = ApiService();
  BarberShop? _top;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getProviders(
        categoryKey: 'sartarosh',
        perPage: 10,
      );
      final items = (res['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (items.isNotEmpty) {
        items.sort(
          (a, b) => ((b['rating'] as num?) ?? 0).compareTo(
            (a['rating'] as num?) ?? 0,
          ),
        );
        _top = BarberShop.fromProviderJson(items.first);
      }
    } catch (_) {
      _top = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_top == null) {
      return const SizedBox.shrink();
    }

    final shop = _top!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tavsiya etiladi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BarberMapScreen(shops: [shop])),
          ),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.scissors, color: Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.address,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${shop.rating} (${shop.reviewCount} sharh)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
