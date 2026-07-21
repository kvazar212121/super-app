import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LessonMode {
  online,
  homeVisit,
  atCenter;

  static LessonMode? fromKey(String key) {
    for (final m in LessonMode.values) {
      if (m.key == key) return m;
    }
    return null;
  }
}

extension LessonModeX on LessonMode {
  String get key => switch (this) {
    LessonMode.online => 'online',
    LessonMode.homeVisit => 'home_visit',
    LessonMode.atCenter => 'at_center',
  };

  String get label => switch (this) {
    LessonMode.online => 'Onlayn (masofadan)',
    LessonMode.homeVisit => 'Uyga kelib',
    LessonMode.atCenter => 'Markazda',
  };

  IconData get icon => switch (this) {
    LessonMode.online => LucideIcons.video,
    LessonMode.homeVisit => LucideIcons.home,
    LessonMode.atCenter => LucideIcons.school,
  };
}

/// Yakka repetitor modeli
class TutorService {
  final String id;
  final int providerId;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String? serviceArea;
  final String address;
  final int experienceYears;
  final List<String> subjects;
  final List<LessonMode> lessonModes;
  final List<String> services;
  final Map<String, double> prices;
  final List<String> timeSlots;
  final Map<String, dynamic>? rawJson;
  final String? subCategory;
  final bool isTravelFeeIncluded;
  final double travelFee;
  final int ownerUserId;

  TutorService({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    this.serviceArea,
    this.address = '',
    this.experienceYears = 0,
    this.subjects = const [],
    this.lessonModes = const [],
    this.services = const [],
    this.prices = const {},
    this.timeSlots = const [],
    this.rawJson,
    this.subCategory,
    this.isTravelFeeIncluded = true,
    this.travelFee = 0.0,
    this.ownerUserId = 0,
  });

  bool get supportsOnline => lessonModes.contains(LessonMode.online);
  bool get supportsHomeVisit => lessonModes.contains(LessonMode.homeVisit);

  String get subjectsLabel => subjects.isEmpty ? 'Fanlar' : subjects.join(', ');

  String get lessonModesLabel => lessonModes.isEmpty
      ? 'Onlayn, uyga'
      : lessonModes.map((m) => m.label).join(', ');

  factory TutorService.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final modeKeys = (meta['lesson_modes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final modes = modeKeys
        .map(LessonMode.fromKey)
        .whereType<LessonMode>()
        .toList();

    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0),
    );

    return TutorService(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone']?.toString() ?? '',
      serviceArea: meta['service_area']?.toString(),
      address: json['address']?.toString() ?? '',
      experienceYears: (meta['experience_years'] as num?)?.toInt() ?? 0,
      subjects: (meta['subjects'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      lessonModes: modes,
      services: services,
      prices: prices,
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rawJson: json,
      subCategory: meta['sub_category']?.toString(),
      isTravelFeeIncluded: meta['is_travel_fee_included'] as bool? ?? true,
      travelFee: (meta['travel_fee'] as num?)?.toDouble() ?? 0.0,
      ownerUserId: (json['owner_user_id'] as num?)?.toInt() ?? 0,
    );
  }
}
