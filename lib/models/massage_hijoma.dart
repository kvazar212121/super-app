import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Xizmat turi (Massaj / Hijoma)
enum ServiceType {
  classicMassage,    // Klassik massaj
  hijoma,            // Hijoma
  thaiMassage,       // Tailand massaji
  stoneMassage,      // Tosh massaji
  sportMassage,      // Sport massaji
  aromatherapy,      // Aromaterapiya
  cupping,           // Vanna (chashka) massaji
  footMassage,       // Oyoq massaji
}

extension ServiceTypeX on ServiceType {
  String get label => switch (this) {
        ServiceType.classicMassage => 'Klassik massaj',
        ServiceType.hijoma         => 'Hijoma',
        ServiceType.thaiMassage    => 'Tailand massaji',
        ServiceType.stoneMassage   => 'Tosh massaji',
        ServiceType.sportMassage   => 'Sport massaji',
        ServiceType.aromatherapy   => 'Aromaterapiya',
        ServiceType.cupping        => 'Vanna massaji',
        ServiceType.footMassage    => 'Oyoq massaji',
      };

  IconData get icon => switch (this) {
        ServiceType.classicMassage => LucideIcons.hand,
        ServiceType.hijoma         => LucideIcons.droplets,
        ServiceType.thaiMassage    => LucideIcons.flower,
        ServiceType.stoneMassage   => LucideIcons.circleDot,
        ServiceType.sportMassage   => LucideIcons.dumbbell,
        ServiceType.aromatherapy   => LucideIcons.flame,
        ServiceType.cupping        => LucideIcons.circleDashed,
        ServiceType.footMassage    => LucideIcons.footprints,
      };
}

/// Jinsiyat bo'yicha xizmat
enum GenderType {
  male,   // Erkaklar
  female, // Ayollar
  both,   // Ikkalasi
}

extension GenderTypeX on GenderType {
  String get label => switch (this) {
        GenderType.male   => 'Erkaklar',
        GenderType.female => 'Ayollar',
        GenderType.both   => 'Ikkalasi',
      };

  IconData get icon => switch (this) {
        GenderType.male   => LucideIcons.user,
        GenderType.female => LucideIcons.userCircle,
        GenderType.both   => LucideIcons.users,
      };
}

/// Massaj va Hijoma markazi modeli
class MassageHijoma {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<ServiceType> serviceTypes;
  final Map<String, double> prices;
  final GenderType gender;
  final bool homeVisit;

  const MassageHijoma({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.serviceTypes,
    required this.prices,
    required this.gender,
    this.homeVisit = false,
  });

  factory MassageHijoma.fromProviderJson(Map<String, dynamic> json) {
    return MassageHijoma(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      serviceTypes: const [ServiceType.classicMassage, ServiceType.hijoma],
      prices: const {'Klassik massaj (60 min)': 120000, 'Hijoma': 80000},
      gender: GenderType.both,
      homeVisit: true,
    );
  }

}
