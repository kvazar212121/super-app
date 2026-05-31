import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Yetkazib berish turi
enum DeliveryType {
  document,   // Hujjat
  package,    // Paket / Quti
  food,       // Ovqat
  cargo,      // Katta yuk
  flowers,    // Gullar
  electronics,// Elektronika
}

extension DeliveryTypeX on DeliveryType {
  String get label => switch (this) {
        DeliveryType.document    => 'Hujjat',
        DeliveryType.package     => 'Paket / Quti',
        DeliveryType.food        => 'Ovqat',
        DeliveryType.cargo       => 'Katta yuk',
        DeliveryType.flowers     => 'Gullar',
        DeliveryType.electronics => 'Elektronika',
      };

  IconData get icon => switch (this) {
        DeliveryType.document    => LucideIcons.fileText,
        DeliveryType.package     => LucideIcons.package,
        DeliveryType.food        => LucideIcons.utensilsCrossed,
        DeliveryType.cargo       => LucideIcons.truck,
        DeliveryType.flowers     => LucideIcons.flower2,
        DeliveryType.electronics => LucideIcons.cpu,
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
  final int maxWeight; // kg
  final bool isExpress;

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
  });

  factory CourierService.fromProviderJson(Map<String, dynamic> json) {
    return CourierService(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      deliveryTypes: const [DeliveryType.document, DeliveryType.package, DeliveryType.food],
      prices: const {'Shahar ichi (5km)': 25000, 'Shahar tashqari': 80000},
      maxWeight: 15,
      isExpress: true,
    );
  }

}
