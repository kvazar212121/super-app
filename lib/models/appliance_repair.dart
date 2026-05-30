import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Uy texnikasi turi
enum ApplianceType {
  washingMachine, // Kir yuvish mashinasi
  refrigerator,   // Muzlatgich
  television,     // Televizor
  oven,           // Pech / Duxovka
  conditioner,    // Konditsioner
  microwave,      // Mikroto'lqinli pech
}

extension ApplianceTypeX on ApplianceType {
  String get label => switch (this) {
        ApplianceType.washingMachine => 'Kir yuvish mashinasi',
        ApplianceType.refrigerator   => 'Muzlatgich',
        ApplianceType.television     => 'Televizor',
        ApplianceType.oven           => 'Pech / Duxovka',
        ApplianceType.conditioner    => 'Konditsioner',
        ApplianceType.microwave      => 'Mikroto\'lqinli pech',
      };

  IconData get icon => switch (this) {
        ApplianceType.washingMachine => LucideIcons.wrench,
        ApplianceType.refrigerator   => LucideIcons.snowflake,
        ApplianceType.television     => LucideIcons.tv,
        ApplianceType.oven           => LucideIcons.flame,
        ApplianceType.conditioner    => LucideIcons.wind,
        ApplianceType.microwave      => LucideIcons.radar,
      };
}

/// Ta'mirchilik xizmati modeli
class ApplianceRepair {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<ApplianceType> applianceTypes;
  final Map<String, double> prices;
  final List<String> brands;

  const ApplianceRepair({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.applianceTypes,
    required this.prices,
    required this.brands,
  });

  static List<ApplianceRepair> demoRepairs = [
    ApplianceRepair(
      id: 'ar1',
      name: 'Texnika Pro',
      latitude: 41.3145,
      longitude: 69.2515,
      rating: 4.7,
      reviewCount: 178,
      phoneNumber: '+998 90 222 33 44',
      applianceTypes: [
        ApplianceType.washingMachine,
        ApplianceType.refrigerator,
        ApplianceType.conditioner,
      ],
      prices: {
        'Kir yuvish diagnostikasi': 50000,
        'Kir yuvish ta\'miri': 150000,
        'Muzlatgich diagnostikasi': 60000,
        'Muzlatgich ta\'miri': 200000,
        'Konditsioner diagnostikasi': 70000,
        'Konditsioner to\'ldirish': 180000,
        'Uyga chiqish': 30000,
      },
      brands: ['Samsung', 'LG', 'Bosch', 'Haier', 'Whirlpool'],
    ),
    ApplianceRepair(
      id: 'ar2',
      name: 'Master Fix',
      latitude: 41.2955,
      longitude: 69.2405,
      rating: 4.9,
      reviewCount: 245,
      phoneNumber: '+998 93 555 66 77',
      applianceTypes: [
        ApplianceType.television,
        ApplianceType.oven,
        ApplianceType.microwave,
        ApplianceType.washingMachine,
      ],
      prices: {
        'TV diagnostikasi': 40000,
        'TV ekran almashtirish': 500000,
        'TV plat ta\'miri': 200000,
        'Pech diagnostikasi': 50000,
        'Pech ta\'miri': 180000,
        'Mikroto\'lqinli ta\'mir': 120000,
        'Kir yuvish ta\'miri': 160000,
        'Uyga chiqish': 25000,
      },
      brands: ['Samsung', 'LG', 'Sony', 'Panasonic', 'Philips', 'Beko'],
    ),
    ApplianceRepair(
      id: 'ar3',
      name: 'Uy Texnikasi',
      latitude: 41.3285,
      longitude: 69.2705,
      rating: 4.5,
      reviewCount: 96,
      phoneNumber: '+998 94 888 99 00',
      applianceTypes: [
        ApplianceType.refrigerator,
        ApplianceType.oven,
        ApplianceType.microwave,
      ],
      prices: {
        'Muzlatgich diagnostikasi': 45000,
        'Muzlatgich ta\'miri': 170000,
        'Pech diagnostikasi': 40000,
        'Pech ta\'miri': 150000,
        'Mikroto\'lqinli ta\'mir': 100000,
        'Uyga chiqish': 20000,
      },
      brands: ['Indesit', 'Ariston', 'Bosch', 'Electrolux', 'Gorenje'],
    ),
    ApplianceRepair(
      id: 'ar4',
      name: 'Elektro Servis',
      latitude: 41.3075,
      longitude: 69.2855,
      rating: 4.6,
      reviewCount: 134,
      phoneNumber: '+998 97 111 00 33',
      applianceTypes: [
        ApplianceType.washingMachine,
        ApplianceType.refrigerator,
        ApplianceType.television,
        ApplianceType.conditioner,
        ApplianceType.oven,
        ApplianceType.microwave,
      ],
      prices: {
        'Diagnostika': 40000,
        'Kir yuvish ta\'miri': 140000,
        'Muzlatgich ta\'miri': 190000,
        'TV ta\'miri': 180000,
        'Konditsioner to\'ldirish': 160000,
        'Pech ta\'miri': 170000,
        'Mikroto\'lqinli ta\'mir': 110000,
        'Uyga chiqish': 25000,
        'Tezkor xizmat (+50%)': 50000,
      },
      brands: ['Samsung', 'LG', 'Sony', 'Panasonic', 'Bosch', 'Haier', 'Beko', 'Whirlpool', 'Hitachi'],
    ),
  ];
}
