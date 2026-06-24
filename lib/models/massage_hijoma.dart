import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Qabul usuli — uyga chiqish yoki salonda
enum MassageVisitMode {
  homeVisit,
  atCenter;

  static MassageVisitMode? fromKey(String key) {
    for (final m in MassageVisitMode.values) {
      if (m.key == key) return m;
    }
    return null;
  }
}

extension MassageVisitModeX on MassageVisitMode {
  String get key => switch (this) {
        MassageVisitMode.homeVisit => 'home_visit',
        MassageVisitMode.atCenter => 'at_center',
      };

  String get label => switch (this) {
        MassageVisitMode.homeVisit => 'Uyga chiqish',
        MassageVisitMode.atCenter => 'Salonga borish',
      };

  String get shortLabel => switch (this) {
        MassageVisitMode.homeVisit => 'Chaqirish',
        MassageVisitMode.atCenter => 'Borish',
      };

  IconData get icon => switch (this) {
        MassageVisitMode.homeVisit => LucideIcons.home,
        MassageVisitMode.atCenter => LucideIcons.building2,
      };
}

/// Xizmat turi (Massaj / Hijoma)
enum ServiceType {
  classicMassage,
  hijoma,
  thaiMassage,
  stoneMassage,
  sportMassage,
  aromatherapy,
  cupping,
  footMassage;

  static ServiceType? fromKey(String key) {
    for (final t in ServiceType.values) {
      if (t.name == key) return t;
    }
    final normalized = key.replaceAll('-', '_');
    for (final t in ServiceType.values) {
      if (t.name == normalized) return t;
    }
    return null;
  }
}

extension ServiceTypeX on ServiceType {
  String get label => switch (this) {
        ServiceType.classicMassage => 'Klassik massaj',
        ServiceType.hijoma => 'Hijoma',
        ServiceType.thaiMassage => 'Tailand massaji',
        ServiceType.stoneMassage => 'Tosh massaji',
        ServiceType.sportMassage => 'Sport massaji',
        ServiceType.aromatherapy => 'Aromaterapiya',
        ServiceType.cupping => 'Vanna massaji',
        ServiceType.footMassage => 'Oyoq massaji',
      };

  IconData get icon => switch (this) {
        ServiceType.classicMassage => LucideIcons.hand,
        ServiceType.hijoma => LucideIcons.droplets,
        ServiceType.thaiMassage => LucideIcons.flower,
        ServiceType.stoneMassage => LucideIcons.circleDot,
        ServiceType.sportMassage => LucideIcons.dumbbell,
        ServiceType.aromatherapy => LucideIcons.flame,
        ServiceType.cupping => LucideIcons.circleDashed,
        ServiceType.footMassage => LucideIcons.footprints,
      };
}

/// Jinsiyat bo'yicha xizmat
enum GenderType {
  male,
  female,
  both;

  static GenderType fromKey(String? key) => switch (key) {
        'male' => GenderType.male,
        'female' => GenderType.female,
        _ => GenderType.both,
      };
}

extension GenderTypeX on GenderType {
  String get label => switch (this) {
        GenderType.male => 'Erkaklar',
        GenderType.female => 'Ayollar',
        GenderType.both => 'Ikkalasi',
      };

  IconData get icon => switch (this) {
        GenderType.male => LucideIcons.user,
        GenderType.female => LucideIcons.userCircle,
        GenderType.both => LucideIcons.users,
      };
}

/// Massaj va Hijoma modeli
class MassageHijoma {
  final String id;
  final int providerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String? serviceArea;
  final String massageRole;
  final List<ServiceType> serviceTypes;
  final Map<String, double> prices;
  final GenderType gender;
  final List<MassageVisitMode> visitModes;
  final double homeVisitFee;
  final List<String> timeSlots;
  final String? subCategory;
  final Map<String, dynamic>? rawJson;
  final bool isTravelFeeIncluded;
  final double travelFee;
  final int ownerUserId;

  MassageHijoma({
    required this.id,
    this.providerId = 0,
    required this.name,
    this.address = '',
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    this.serviceArea,
    this.massageRole = 'solo',
    required this.serviceTypes,
    required this.prices,
    required this.gender,
    this.visitModes = const [],
    this.homeVisitFee = 50000,
    this.timeSlots = const [],
    this.subCategory,
    this.rawJson,
    this.isTravelFeeIncluded = true,
    this.travelFee = 0.0,
    this.ownerUserId = 0,
  });

  bool get supportsHomeVisit => visitModes.contains(MassageVisitMode.homeVisit);

  bool get supportsAtCenter => visitModes.contains(MassageVisitMode.atCenter);

  bool get isSalon => massageRole == 'salon';

  String get visitModesLabel => visitModes.isEmpty
      ? 'Uyga chiqish, salonda'
      : visitModes.map((m) => m.shortLabel).join(' • ');

  @Deprecated('Use visitModes')
  bool get homeVisit => supportsHomeVisit;

  factory MassageHijoma.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final modeKeys = (meta['visit_modes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    var modes = modeKeys.map(MassageVisitMode.fromKey).whereType<MassageVisitMode>().toList();
    if (modes.isEmpty) {
      modes = [MassageVisitMode.homeVisit, MassageVisitMode.atCenter];
    }

    final typeKeys = (meta['service_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    var types = typeKeys.map(ServiceType.fromKey).whereType<ServiceType>().toList();
    if (types.isEmpty) {
      types = [ServiceType.classicMassage, ServiceType.hijoma];
    }

    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.isEmpty
        ? {
            'Klassik massaj (60 min)': 150000.0,
            'Hijoma': 120000.0,
          }
        : pricesRaw.map<String, double>(
            (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0),
          );

    return MassageHijoma(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone']?.toString() ?? '',
      serviceArea: meta['service_area']?.toString(),
      massageRole: meta['massage_role']?.toString() ?? 'solo',
      serviceTypes: types,
      prices: prices,
      gender: GenderType.fromKey(meta['gender']?.toString()),
      visitModes: modes,
      homeVisitFee: (meta['home_visit_fee'] as num?)?.toDouble() ??
          (prices["Uyga chiqish qo'shimcha"] ?? 50000.0),
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      subCategory: meta['sub_category']?.toString(),
      rawJson: json,
      isTravelFeeIncluded: meta['is_travel_fee_included'] as bool? ?? true,
      travelFee: (meta['travel_fee'] as num?)?.toDouble() ?? 0.0,
      ownerUserId: (json['owner_user_id'] as num?)?.toInt() ?? 0,
    );
  }
}
