import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dezinfeksiya xizmati turi
enum AreaType {
  apartment, // Kvartira
  office,    // Ofis
  vehicle,   // Mashina
  school,    // Maktab
}

extension AreaTypeX on AreaType {
  String get label => switch (this) {
        AreaType.apartment => 'Kvartira',
        AreaType.office    => 'Ofis',
        AreaType.vehicle   => 'Mashina',
        AreaType.school    => 'Maktab',
      };

  IconData get icon => switch (this) {
        AreaType.apartment => LucideIcons.home,
        AreaType.office    => LucideIcons.building2,
        AreaType.vehicle   => LucideIcons.car,
        AreaType.school    => LucideIcons.school,
      };
}

/// Dezinfeksiya vositasi
class ChemicalProduct {
  final String name;
  final IconData icon;
  final bool isEcoFriendly;

  const ChemicalProduct({
    required this.name,
    required this.icon,
    this.isEcoFriendly = false,
  });
}

/// Dezinfeksiya xizmati modeli
class DisinfectionService {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<AreaType> areaTypes;
  final Map<String, double> prices;
  final List<ChemicalProduct> chemicals;
  final bool isCertified;

  const DisinfectionService({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.areaTypes,
    required this.prices,
    required this.chemicals,
    this.isCertified = false,
  });

  factory DisinfectionService.fromProviderJson(Map<String, dynamic> json) {
    return DisinfectionService(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      areaTypes: const [AreaType.apartment, AreaType.office],
      prices: const {'Kvartira': 150000, 'Ofis': 200000},
      chemicals: const [],
      isCertified: true,
    );
  }

  static List<DisinfectionService> demoServices = [
    DisinfectionService(
      id: 'd1',
      name: "Uy Tozalash",
      latitude: 41.3115,
      longitude: 69.2495,
      rating: 4.8,
      reviewCount: 142,
      phoneNumber: '+998 90 111 22 33',
      areaTypes: [AreaType.apartment, AreaType.office],
      prices: {
        '1 xonali': 150000,
        '2 xonali': 250000,
        '3 xonali': 350000,
        'Ofis (50m²)': 200000,
        'Ofis (100m²)': 350000,
      },
      chemicals: [
        const ChemicalProduct(name: 'Xlor dezinfektor', icon: LucideIcons.flaskConical, isEcoFriendly: false),
        const ChemicalProduct(name: 'Eco Clean Pro', icon: LucideIcons.leaf, isEcoFriendly: true),
      ],
      isCertified: true,
    ),
    DisinfectionService(
      id: 'd2',
      name: 'Ofis Pro',
      latitude: 41.3055,
      longitude: 69.2625,
      rating: 4.6,
      reviewCount: 89,
      phoneNumber: '+998 93 444 55 66',
      areaTypes: [AreaType.office, AreaType.school],
      prices: {
        'Ofis (50m²)': 180000,
        'Ofis (100m²)': 320000,
        'Ofis (200m²)': 550000,
        'Maktab sinfi': 280000,
        'Maktab to\'liq': 800000,
      },
      chemicals: [
        const ChemicalProduct(name: 'BioShield Plus', icon: LucideIcons.shieldCheck, isEcoFriendly: true),
        const ChemicalProduct(name: 'ViruClean', icon: LucideIcons.flaskConical),
        const ChemicalProduct(name: 'SafeGuard Spray', icon: LucideIcons.sprayCan, isEcoFriendly: true),
      ],
      isCertified: true,
    ),
    DisinfectionService(
      id: 'd3',
      name: 'Avto Dez',
      latitude: 41.2985,
      longitude: 69.2355,
      rating: 4.5,
      reviewCount: 67,
      phoneNumber: '+998 94 777 88 99',
      areaTypes: [AreaType.vehicle],
      prices: {
        'Yengil avtomobil': 120000,
        'Mikroavtobus': 180000,
        'Yuk mashinasi': 250000,
      },
      chemicals: [
        const ChemicalProduct(name: 'AutoClean Sanitizer', icon: LucideIcons.car),
        const ChemicalProduct(name: 'FreshAir Neutralizer', icon: LucideIcons.wind, isEcoFriendly: true),
      ],
      isCertified: false,
    ),
    DisinfectionService(
      id: 'd4',
      name: "Saniter Xizmat",
      latitude: 41.3225,
      longitude: 69.2785,
      rating: 4.9,
      reviewCount: 203,
      phoneNumber: '+998 97 000 11 22',
      areaTypes: [AreaType.apartment, AreaType.office, AreaType.vehicle, AreaType.school],
      prices: {
        '1 xonali': 180000,
        '2 xonali': 280000,
        '3 xonali': 380000,
        'Ofis (50m²)': 220000,
        'Ofis (100m²)': 400000,
        'Yengil avtomobil': 150000,
        'Maktab sinfi': 300000,
        'Maktab to\'liq': 900000,
      },
      chemicals: [
        const ChemicalProduct(name: 'MedGrade Disinfectant', icon: LucideIcons.shieldCheck, isEcoFriendly: true),
        const ChemicalProduct(name: 'PureZone Fogger', icon: LucideIcons.sprayCan),
        const ChemicalProduct(name: 'GreenSanitex', icon: LucideIcons.leaf, isEcoFriendly: true),
        const ChemicalProduct(name: 'UltraViolet Gel', icon: LucideIcons.sun),
      ],
      isCertified: true,
    ),
  ];
}
