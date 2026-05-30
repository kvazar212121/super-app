import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  static List<CourierService> demoCouriers = [
    CourierService(
      id: 'c1',
      name: 'Tezkor Kuryer',
      latitude: 41.3115,
      longitude: 69.2495,
      rating: 4.7,
      reviewCount: 231,
      phoneNumber: '+998 90 333 44 55',
      deliveryTypes: [DeliveryType.document, DeliveryType.package, DeliveryType.food],
      prices: {
        'Shahar ichi (3km)': 15000,
        'Shahar ichi (5km)': 25000,
        'Shahar ichi (10km)': 40000,
        'Shahar tashqari': 80000,
        'Express (+50%)': 20000,
      },
      maxWeight: 15,
      isExpress: true,
    ),
    CourierService(
      id: 'c2',
      name: 'Yetkazamiz',
      latitude: 41.2985,
      longitude: 69.2355,
      rating: 4.5,
      reviewCount: 167,
      phoneNumber: '+998 93 666 77 88',
      deliveryTypes: [DeliveryType.package, DeliveryType.cargo, DeliveryType.electronics],
      prices: {
        'Shahar ichi (3km)': 20000,
        'Shahar ichi (5km)': 35000,
        'Shahar ichi (10km)': 55000,
        'Shahar tashqari': 100000,
        'Yuk ko\'tarish (har qavat)': 5000,
      },
      maxWeight: 50,
      isExpress: false,
    ),
    CourierService(
      id: 'c3',
      name: 'Express Post',
      latitude: 41.3225,
      longitude: 69.2685,
      rating: 4.8,
      reviewCount: 198,
      phoneNumber: '+998 94 999 00 11',
      deliveryTypes: [DeliveryType.document, DeliveryType.flowers, DeliveryType.food, DeliveryType.electronics],
      prices: {
        'Shahar ichi (3km)': 18000,
        'Shahar ichi (5km)': 30000,
        'Shahar ichi (10km)': 45000,
        'Shahar tashqari': 90000,
        'Express (+50%)': 25000,
        'Nozik buyum qo\'shimcha': 10000,
      },
      maxWeight: 20,
      isExpress: true,
    ),
    CourierService(
      id: 'c4',
      name: 'Kuryer Plus',
      latitude: 41.3055,
      longitude: 69.2805,
      rating: 4.6,
      reviewCount: 145,
      phoneNumber: '+998 97 222 33 44',
      deliveryTypes: [DeliveryType.document, DeliveryType.package, DeliveryType.food, DeliveryType.cargo, DeliveryType.flowers, DeliveryType.electronics],
      prices: {
        'Shahar ichi (3km)': 12000,
        'Shahar ichi (5km)': 22000,
        'Shahar ichi (10km)': 38000,
        'Shahar tashqari': 75000,
        'Express (+50%)': 18000,
        'Yuk ko\'tarish (har qavat)': 4000,
        'Nozik buyum qo\'shimcha': 8000,
      },
      maxWeight: 30,
      isExpress: true,
    ),
  ];
}
