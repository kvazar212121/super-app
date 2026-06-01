import 'dart:math' as math;

import '../utils/geo_utils.dart';

class Barber {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final List<String> specializations;

  Barber({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.specializations,
  });
}

class BarberShop {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> services;
  final Map<String, double> prices;
  final List<Barber> barbers;

  BarberShop({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.services,
    required this.prices,
    required this.barbers,
  });

  /// Backend provider ID (buyurtma yuborish uchun).
  int get providerId => int.tryParse(id) ?? 0;

  factory BarberShop.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final barbersRaw = meta['barbers'] as List<dynamic>? ?? [];
    final defaultServices = services.isNotEmpty
        ? services
        : ['Erkaklar kesimi', 'Soqol olish'];

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

    return BarberShop(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      images: const [],
      services: defaultServices,
      prices: prices,
      barbers: barbersRaw.map((b) {
        final m = b as Map<String, dynamic>;
        return Barber(
          id: m['name']?.toString() ?? '',
          name: m['name'] ?? '',
          imageUrl: '',
          rating: (m['rating'] as num?)?.toDouble() ?? 4.5,
          specializations: defaultServices,
        );
      }).toList(),
    );
  }

  /// Admin yoki provider belgilamaguncha demo narxlar (past).
  static double defaultPriceForService(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('soqol')) return 15000;
    if (lower.contains('bola')) return 20000;
    if (lower.contains('styling') || lower.contains('uslub')) return 35000;
    return 25000;
  }

  double get minPrice {
    if (prices.isEmpty) return defaultPriceForService('kesim');
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

  /// metadata.open_hours bo'lmasa 09:00–21:00 deb hisoblanadi.
  bool isOpenNow([DateTime? now]) {
    final t = now ?? DateTime.now();
    return t.hour >= 9 && t.hour < 21;
  }
}
