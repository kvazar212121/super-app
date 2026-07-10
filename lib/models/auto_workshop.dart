import 'package:super_app/l10n/locale_controller.dart';

class AutoWorkshop {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<String> specializations;
  final List<String> services;
  final Map<String, double> prices;
  final bool isOpen;
  final String? autoRole;
  final int providerId;

  final String? subCategory;

  AutoWorkshop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.specializations,
    required this.services,
    required this.prices,
    this.isOpen = true,
    this.autoRole,
    this.providerId = 0,
    this.rawJson,
    this.subCategory,
  });

  bool get isWorkshop => autoRole == 'workshop';

  final Map<String, dynamic>? rawJson;

  factory AutoWorkshop.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final specs = (meta['specializations'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final serviceList = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final pricesRaw = meta['prices'] as Map<String, dynamic>?;
    final prices = <String, double>{};
    if (pricesRaw != null) {
      for (final entry in pricesRaw.entries) {
        prices[entry.key] = (entry.value as num).toDouble();
      }
    }
    for (final s in serviceList) {
      prices.putIfAbsent(s, () => _defaultPrice(s));
    }

    final rawId = json['id'];
    final pid = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return AutoWorkshop(
      id: rawId?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      specializations: specs.isNotEmpty ? specs : ['Motor', 'Diagnostika'],
      services: serviceList.isNotEmpty
          ? serviceList
          : const ['Diagnostika', 'Xodovoy remont'],
      prices: prices,
      autoRole: meta['auto_role']?.toString(),
      providerId: pid,
      rawJson: json,
      subCategory: meta['sub_category']?.toString(),
    );
  }

  static double _defaultPrice(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('diagnost')) return 80000;
    if (lower.contains('dvigatel')) return 350000;
    if (lower.contains('elektron')) return 150000;
    if (lower.contains('shino')) return 120000;
    if (lower.contains('xodovoy')) return 200000;
    return 100000;
  }
}
