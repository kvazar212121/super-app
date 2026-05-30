import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  static List<MassageHijoma> demoCenters = [
    MassageHijoma(
      id: 'mh1',
      name: 'Shifo Massaj',
      latitude: 41.3155,
      longitude: 69.2545,
      rating: 4.8,
      reviewCount: 189,
      phoneNumber: '+998 90 444 55 66',
      serviceTypes: [
        ServiceType.classicMassage,
        ServiceType.hijoma,
        ServiceType.sportMassage,
        ServiceType.footMassage,
      ],
      prices: {
        'Klassik massaj (1 soat)': 120000,
        'Hijoma': 150000,
        'Sport massaj (1 soat)': 150000,
        'Oyoq massaji (30 min)': 80000,
        'Uyga chiqish (+50%)': 60000,
      },
      gender: GenderType.male,
      homeVisit: true,
    ),
    MassageHijoma(
      id: 'mh2',
      name: 'Hijoma Markazi',
      latitude: 41.2975,
      longitude: 69.2415,
      rating: 4.9,
      reviewCount: 267,
      phoneNumber: '+998 93 777 88 99',
      serviceTypes: [
        ServiceType.hijoma,
        ServiceType.cupping,
        ServiceType.classicMassage,
      ],
      prices: {
        'Hijoma (to\'liq)': 180000,
        'Hijoma (qisman)': 120000,
        'Vanna massaji': 100000,
        'Klassik massaj (1 soat)': 130000,
        'Konsultatsiya': 50000,
        'Uyga chiqish (+50%)': 70000,
      },
      gender: GenderType.both,
      homeVisit: true,
    ),
    MassageHijoma(
      id: 'mh3',
      name: 'Spa Salon',
      latitude: 41.3265,
      longitude: 69.2725,
      rating: 4.7,
      reviewCount: 156,
      phoneNumber: '+998 94 000 11 22',
      serviceTypes: [
        ServiceType.thaiMassage,
        ServiceType.stoneMassage,
        ServiceType.aromatherapy,
        ServiceType.classicMassage,
      ],
      prices: {
        'Tailand massaji (1.5 soat)': 200000,
        'Tosh massaji (1 soat)': 180000,
        'Aromaterapiya (1 soat)': 160000,
        'Klassik massaj (1 soat)': 140000,
        'SPA paket (3 soat)': 450000,
      },
      gender: GenderType.female,
      homeVisit: false,
    ),
    MassageHijoma(
      id: 'mh4',
      name: 'Nur Massaj',
      latitude: 41.3085,
      longitude: 69.2865,
      rating: 4.6,
      reviewCount: 134,
      phoneNumber: '+998 97 333 44 55',
      serviceTypes: [
        ServiceType.classicMassage,
        ServiceType.hijoma,
        ServiceType.thaiMassage,
        ServiceType.sportMassage,
        ServiceType.footMassage,
        ServiceType.aromatherapy,
      ],
      prices: {
        'Klassik massaj (1 soat)': 110000,
        'Hijoma (to\'liq)': 160000,
        'Tailand massaji (1 soat)': 170000,
        'Sport massaj (1 soat)': 140000,
        'Oyoq massaji (30 min)': 70000,
        'Aromaterapiya (1 soat)': 150000,
        'Uyga chiqish (+50%)': 55000,
      },
      gender: GenderType.both,
      homeVisit: true,
    ),
  ];
}
