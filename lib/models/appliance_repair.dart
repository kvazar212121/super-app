import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Uy texnikasi turi
enum ApplianceType {
  washingMachine, // Kir yuvish mashinasi
  refrigerator, // Muzlatgich
  television, // Televizor
  oven, // Pech / Duxovka
  conditioner, // Konditsioner
  microwave, // Mikroto'lqinli pech
}

extension ApplianceTypeX on ApplianceType {
  String get label => switch (this) {
    ApplianceType.washingMachine => 'Kir yuvish mashinasi',
    ApplianceType.refrigerator => 'Muzlatgich',
    ApplianceType.television => 'Televizor',
    ApplianceType.oven => 'Pech / Duxovka',
    ApplianceType.conditioner => 'Konditsioner',
    ApplianceType.microwave => 'Mikroto\'lqinli pech',
  };

  IconData get icon => switch (this) {
    ApplianceType.washingMachine => LucideIcons.wrench,
    ApplianceType.refrigerator => LucideIcons.snowflake,
    ApplianceType.television => LucideIcons.tv,
    ApplianceType.oven => LucideIcons.flame,
    ApplianceType.conditioner => LucideIcons.wind,
    ApplianceType.microwave => LucideIcons.radar,
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
  final Map<String, dynamic>? rawJson;

  final String? subCategory;

  final bool isTravelFeeIncluded;
  final double travelFee;

  ApplianceRepair({
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
    this.rawJson,
    this.subCategory,
    this.isTravelFeeIncluded = true,
    this.travelFee = 0.0,
  });

  factory ApplianceRepair.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};

    return ApplianceRepair(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      applianceTypes: const [
        ApplianceType.washingMachine,
        ApplianceType.refrigerator,
        ApplianceType.conditioner,
      ],
      prices: const {'Diagnostika': 50000, 'Ta\'mirlash': 150000},
      brands: const ['Samsung', 'LG', 'Artel'],
      rawJson: json,
      subCategory: meta['sub_category']?.toString(),
      isTravelFeeIncluded: meta['is_travel_fee_included'] as bool? ?? true,
      travelFee: (meta['travel_fee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
