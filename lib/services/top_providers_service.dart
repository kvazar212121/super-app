import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/service_hub_kind.dart';
import 'api_service.dart';

/// Bosh sahifadagi "Top reytingli" ro'yxati uchun bitta provayder.
///
/// Backenddagi xom JSON'ni ekranda kerak bo'ladigan sodda ko'rinishga
/// keltiradi — har soha uchun alohida model yasash shart emas.
class TopProvider {
  final int id;
  final String name;
  final String subtitle;
  final double rating;
  final int reviewCount;
  final String? coverUrl;
  final double? latitude;
  final double? longitude;

  /// Qaysi sohaga tegishli (filtr va ikonka uchun). Noma'lum kalit kelsa null.
  final ServiceHubKind? kind;

  /// Soha nomi — `kind` topilmasa backenddan kelgan kalit ishlatiladi.
  final String categoryLabel;

  /// Provayder sahifasini ochish uchun xom JSON (mavjud ekranlarga uzatiladi).
  final Map<String, dynamic> rawJson;

  const TopProvider({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.reviewCount,
    required this.categoryLabel,
    required this.rawJson,
    this.coverUrl,
    this.latitude,
    this.longitude,
    this.kind,
  });

  IconData get icon => kind?.icon ?? LucideIcons.badgeCheck;

  factory TopProvider.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'];
    final metaMap = meta is Map ? meta : const {};

    final rawKey = json['category_key']?.toString();
    // Eskirgan kategoriya kalitlari yangisiga moslanadi, aks holda bunday
    // provayderlar "noma'lum" bo'lib chiqadi (nomi kichik harfda, zaxira
    // ikonka bilan) va bosilganda hech narsa ochilmaydi.
    const legacyKeys = <String, String>{
      // Konditsioner endi "Texnika ustasi" ichida.
      'konditsioner': 'texnikaUstasi',
      // Eski kompyuter ustasi -> yangi kalit.
      'kompyuter_usta': 'kompyuterUsta',
      // "Yana xizmatlar" -> "Boshqa xizmatlar".
      'yana': 'boshqa_xizmatlar',
    };
    final key = rawKey == null || rawKey.isEmpty
        ? null
        : (legacyKeys[rawKey] ?? rawKey);

    ServiceHubKind? kind;
    if (key != null) {
      for (final k in ServiceHubKind.values) {
        if (k.key == key || k.name == key) {
          kind = k;
          break;
        }
      }
    }

    // Izoh: manzil bo'lsa manzil, bo'lmasa xizmat hududi yoki soha nomi.
    final address = (json['address']?.toString() ?? '').trim();
    final area = (metaMap['service_area']?.toString() ?? '').trim();
    final label = kind?.title ?? (key ?? 'Xizmat');

    return TopProvider(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      subtitle: address.isNotEmpty
          ? address
          : (area.isNotEmpty ? area : label),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      coverUrl: json['cover_image']?.toString(),
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble(),
      kind: kind,
      categoryLabel: label,
      rawJson: json,
    );
  }
}

/// Bosh sahifadagi "Top reytingli" ro'yxatini yuklaydi.
///
/// Sahifalab yuklaydi ("Yana" tugmasi) va soha bo'yicha filtrlaydi.
/// Backenddan `sort=rating` bilan so'raladi — saralash serverda bajariladi,
/// shuning uchun "Yana" bosilganda tartib buzilmaydi.
class TopProvidersService {
  static final TopProvidersService _instance = TopProvidersService._();
  factory TopProvidersService() => _instance;
  TopProvidersService._();

  final _api = ApiService();

  /// Bir sahifada nechta provayder ko'rsatiladi.
  static const pageSize = 10;

  /// TESTLAR uchun: haqiqiy tarmoq so'rovini almashtirish nuqtasi.
  /// null bo'lsa odatdagidek backendga so'rov yuboriladi.
  Future<({List<TopProvider> items, bool hasMore})> Function({
    ServiceHubKind? kind,
    int page,
  })? debugFetchOverride;

  /// Bir sohaning BARCHA provayderlari (saralangan holda) keshi.
  final _sortedAll = <String, List<TopProvider>>{};

  /// [kind] null bo'lsa — barcha sohalar.
  ///
  /// Global tartib TO'G'RI bo'lishi uchun provayderlar bir marta to'liq
  /// yuklanadi va reyting bo'yicha saralanadi, so'ng 10 tadan beriladi.
  /// (Server `sort=rating` ni qo'llab-quvvatlasa ham natija bir xil, lekin
  /// qo'llab-quvvatlamasa ham "Yana" bosilganda tartib buzilmaydi.)
  Future<({List<TopProvider> items, bool hasMore})> fetch({
    ServiceHubKind? kind,
    int page = 1,
  }) async {
    final override = debugFetchOverride;
    if (override != null) return override(kind: kind, page: page);

    final cacheKey = kind?.key ?? 'all';
    var all = _sortedAll[cacheKey];
    all ??= _sortedAll[cacheKey] = await _loadAllSorted(kind);

    final from = (page - 1) * pageSize;
    if (from >= all.length) {
      return (items: const <TopProvider>[], hasMore: false);
    }
    final to = (from + pageSize).clamp(0, all.length);
    return (items: all.sublist(from, to), hasMore: to < all.length);
  }

  /// Barcha sahifalarni yuklab, reyting bo'yicha saralaydi.
  Future<List<TopProvider>> _loadAllSorted(ServiceHubKind? kind) async {
    final all = <TopProvider>[];
    // Xavfsizlik chegarasi: juda ko'p provayder bo'lsa ham cheksiz
    // so'rov yubormaymiz (10 sahifa × 50 = 500 ta yetarli).
    const maxPages = 10;
    const perPage = 50;

    for (var p = 1; p <= maxPages; p++) {
      final batch = await _fetchPage(kind: kind, page: p, perPage: perPage);
      all.addAll(batch.items);
      if (!batch.hasMore) break;
    }

    all.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      return b.reviewCount.compareTo(a.reviewCount);
    });
    return all;
  }

  /// Bitta sahifani backenddan oladi.
  Future<({List<TopProvider> items, bool hasMore})> _fetchPage({
    ServiceHubKind? kind,
    required int page,
    required int perPage,
  }) async {
    try {
      final res = await _api.getProviders(
        categoryKey: kind?.key,
        page: page,
        perPage: perPage,
        sort: 'rating',
      );

      final rawItems = (res['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final items = rawItems
          .map(TopProvider.fromJson)
          // Reytingsiz (yangi) provayderlar "top" ro'yxatiga tushmaydi.
          .where((p) => p.rating > 0 && p.name.isNotEmpty)
          .toList();

      // Yana sahifa bormi: server jami sonini bersa shundan, aks holda
      // to'liq sahifa kelgani bo'yicha taxmin qilamiz.
      final total = (res['total'] as num?)?.toInt();
      final pages = (res['pages'] as num?)?.toInt();
      final hasMore = pages != null
          ? page < pages
          : (total != null
                ? page * perPage < total
                : rawItems.length >= perPage);

      return (items: items, hasMore: hasMore);
    } catch (e) {
      debugPrint('TopProvidersService fetch error: $e');
      return (items: const <TopProvider>[], hasMore: false);
    }
  }

  /// Keshni tozalaydi (masalan "tortib yangilash" da).
  void clearCache() => _sortedAll.clear();
}
