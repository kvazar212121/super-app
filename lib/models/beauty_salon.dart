import 'dart:math' as math;

import '../utils/geo_utils.dart';
import 'package:super_app/l10n/locale_controller.dart';

class SalonStaff {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String imageUrl;
  final int providerId;

  SalonStaff({
    required this.id,
    required this.name,
    this.specialty = 'Mutaxassis',
    required this.rating,
    this.imageUrl = '',
    this.providerId = 0,
  });
}

class BeautySalon {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> services;
  final Map<String, double> prices;
  final List<SalonStaff> staff;
  final Map<String, dynamic>? rawJson;
  final String? subCategory;
  final int ownerUserId;

  BeautySalon({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.prices,
    required this.staff,
    this.rawJson,
    this.subCategory,
    this.ownerUserId = 0,
  });

  int get providerId => int.tryParse(id) ?? 0;

  factory BeautySalon.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    if (meta['salon_role'] == 'mobile') {
      throw ArgumentError('Mobile stylist — use Master.fromProviderJson');
    }

    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final defaultServices = services.isNotEmpty
        ? services
        : ['Fen', 'Manikyur', 'Makiyaj'];

    final pricesRaw = meta['prices'] as Map<String, dynamic>?;
    final prices = <String, double>{};
    if (pricesRaw != null) {
      for (final entry in pricesRaw.entries) {
        prices[entry.key] = (entry.value as num).toDouble();
      }
    }
    for (final s in defaultServices) {
      prices.putIfAbsent(s, () => defaultPriceForService(s));
    }

    final staffRaw = meta['staff'] as List<dynamic>? ?? [];
    final staff = staffRaw.map((b) {
      final m = b as Map<String, dynamic>;
      return SalonStaff(
        id: m['name']?.toString() ?? '',
        name: m['name'] ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 4.5,
        providerId: (m['provider_id'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return BeautySalon(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      services: defaultServices,
      prices: prices,
      staff: staff,
      rawJson: json,
      subCategory: meta['sub_category']?.toString(),
      ownerUserId: (json['owner_user_id'] as num?)?.toInt() ?? 0,
    );
  }

  static double defaultPriceForService(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('manik')) return 60000;
    if (lower.contains('pedik')) return 70000;
    if (lower.contains('maki')) return 80000;
    if (lower.contains('fen')) return 45000;
    return 50000;
  }

  double get minPrice {
    if (prices.isEmpty) return defaultPriceForService('Fen');
    return prices.values.reduce(math.min);
  }

  double get maxPrice {
    if (prices.isEmpty) return minPrice;
    return prices.values.reduce(math.max);
  }

  String priceRangeLabel({String suffix = 'so\'m'}) {
    final min = minPrice.round();
    if ((maxPrice - minPrice).abs() < 1) return '$min $suffix';
    return '$min — ${maxPrice.round()} $suffix';
  }

  double distanceKmFrom(double userLat, double userLng) =>
      distanceKm(userLat, userLng, latitude, longitude);

  bool isOpenNow([DateTime? now]) {
    final t = now ?? DateTime.now();
    return t.hour >= 10 && t.hour < 20;
  }
}
