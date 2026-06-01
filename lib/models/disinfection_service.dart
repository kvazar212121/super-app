import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dezinfeksiya xizmati turi
enum AreaType {
  apartment,
  office,
  vehicle,
  school;

  static AreaType? fromKey(String key) {
    for (final t in AreaType.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

extension AreaTypeX on AreaType {
  String get key => switch (this) {
        AreaType.apartment => 'apartment',
        AreaType.office => 'office',
        AreaType.vehicle => 'vehicle',
        AreaType.school => 'school',
      };

  String get label => switch (this) {
        AreaType.apartment => 'Kvartira',
        AreaType.office => 'Ofis',
        AreaType.vehicle => 'Mashina',
        AreaType.school => 'Maktab',
      };

  IconData get icon => switch (this) {
        AreaType.apartment => LucideIcons.home,
        AreaType.office => LucideIcons.building2,
        AreaType.vehicle => LucideIcons.car,
        AreaType.school => LucideIcons.school,
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
  final int providerId;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String? serviceArea;
  final List<AreaType> areaTypes;
  final Map<String, double> prices;
  final List<ChemicalProduct> chemicals;
  final List<String> timeSlots;
  final bool isCertified;

  const DisinfectionService({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    this.serviceArea,
    required this.areaTypes,
    required this.prices,
    required this.chemicals,
    this.timeSlots = const [],
    this.isCertified = false,
  });

  static const _defaultChemicals = [
    ChemicalProduct(name: 'Viritsid', icon: LucideIcons.droplet),
    ChemicalProduct(name: 'Eko-dezinfektant', icon: LucideIcons.leaf, isEcoFriendly: true),
    ChemicalProduct(name: 'Chlorheksidin', icon: LucideIcons.flaskConical),
  ];

  factory DisinfectionService.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final areaKeys = (meta['area_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final areaTypes = areaKeys.isEmpty
        ? [AreaType.apartment, AreaType.office, AreaType.vehicle]
        : areaKeys.map(AreaType.fromKey).whereType<AreaType>().toList();

    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.isEmpty
        ? {
            'Kvartira dezinfeksiyasi': 150000.0,
            'Ofis dezinfeksiyasi': 250000.0,
            'Mashina dezinfeksiyasi': 100000.0,
          }
        : pricesRaw.map(
            (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0),
          );

    final chemRaw = meta['chemicals'] as List<dynamic>? ?? [];
    final chemicals = chemRaw.isEmpty
        ? _defaultChemicals
        : chemRaw.map((c) {
            final m = c as Map<String, dynamic>? ?? {};
            final name = m['name']?.toString() ?? 'Vosita';
            final eco = m['eco'] == true;
            return ChemicalProduct(
              name: name,
              icon: eco ? LucideIcons.leaf : LucideIcons.droplet,
              isEcoFriendly: eco,
            );
          }).toList();

    return DisinfectionService(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone']?.toString() ?? '',
      serviceArea: meta['service_area']?.toString(),
      areaTypes: areaTypes,
      prices: prices,
      chemicals: chemicals,
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isCertified: meta['is_certified'] == true,
    );
  }
}
