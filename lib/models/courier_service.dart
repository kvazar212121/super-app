import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Yetkazib berish turi
enum DeliveryType {
  document,
  package,
  food,
  cargo,
  flowers,
  electronics;

  static DeliveryType? fromKey(String key) {
    final k = key.toLowerCase();
    for (final t in DeliveryType.values) {
      if (t.key == k) return t;
    }
    return null;
  }
}

extension DeliveryTypeX on DeliveryType {
  String get key => switch (this) {
        DeliveryType.document => 'document',
        DeliveryType.package => 'package',
        DeliveryType.food => 'food',
        DeliveryType.cargo => 'cargo',
        DeliveryType.flowers => 'flowers',
        DeliveryType.electronics => 'electronics',
      };

  String get label => switch (this) {
        DeliveryType.document => 'Hujjat',
        DeliveryType.package => 'Paket / Quti',
        DeliveryType.food => 'Ovqat',
        DeliveryType.cargo => 'Katta yuk',
        DeliveryType.flowers => 'Gullar',
        DeliveryType.electronics => 'Elektronika',
      };

  IconData get icon => switch (this) {
        DeliveryType.document => LucideIcons.fileText,
        DeliveryType.package => LucideIcons.package,
        DeliveryType.food => LucideIcons.utensilsCrossed,
        DeliveryType.cargo => LucideIcons.truck,
        DeliveryType.flowers => LucideIcons.flower2,
        DeliveryType.electronics => LucideIcons.cpu,
      };
}

enum VehicleType {
  bike,
  car,
  van;

  static VehicleType fromKey(String? key) {
    switch (key?.toLowerCase()) {
      case 'car':
        return VehicleType.car;
      case 'van':
        return VehicleType.van;
      default:
        return VehicleType.bike;
    }
  }
}

extension VehicleTypeX on VehicleType {
  String get key => switch (this) {
        VehicleType.bike => 'bike',
        VehicleType.car => 'car',
        VehicleType.van => 'van',
      };

  String get label => switch (this) {
        VehicleType.bike => 'Velosiped',
        VehicleType.car => 'Mashina',
        VehicleType.van => 'Furgon',
      };
}

/// Kuryer xizmati modeli
class CourierService {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<DeliveryType> deliveryTypes;
  final Map<String, double> prices;
  final int maxWeight;
  final bool isExpress;
  final String? courierRole;
  final String? serviceArea;
  final VehicleType vehicleType;

  const CourierService({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.deliveryTypes,
    required this.prices,
    required this.maxWeight,
    this.isExpress = false,
    this.courierRole,
    this.serviceArea,
    this.vehicleType = VehicleType.bike,
  });

  bool get isCourierSolo => courierRole == 'solo';

  factory CourierService.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final typeKeys = (meta['delivery_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final deliveryTypes = typeKeys
        .map(DeliveryType.fromKey)
        .whereType<DeliveryType>()
        .toList();

    final pricesRaw = meta['prices'] as Map<String, dynamic>?;
    final prices = <String, double>{};
    if (pricesRaw != null) {
      for (final entry in pricesRaw.entries) {
        prices[entry.key] = (entry.value as num).toDouble();
      }
    }
    if (prices.isEmpty) {
      prices.addAll({
        'Shahar ichi (5km)': 25000,
        'Shahar tashqari': 80000,
        'Express (+50%)': 12500,
      });
    }

    final maxWeightRaw = meta['max_weight'];
    final maxWeight = maxWeightRaw is int
        ? maxWeightRaw
        : int.tryParse(maxWeightRaw?.toString() ?? '') ?? 15;

    return CourierService(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      deliveryTypes: deliveryTypes.isNotEmpty
          ? deliveryTypes
          : const [DeliveryType.document, DeliveryType.package, DeliveryType.food],
      prices: prices,
      maxWeight: maxWeight,
      isExpress: meta['is_express'] == true,
      courierRole: meta['courier_role']?.toString(),
      serviceArea: meta['service_area']?.toString(),
      vehicleType: VehicleType.fromKey(meta['vehicle_type']?.toString()),
    );
  }
}
