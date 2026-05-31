import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

}
