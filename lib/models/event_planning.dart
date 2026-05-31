import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tadbir turi
enum EventType {
  wedding,       // To'y
  birthday,      // Tug'ilgan kun
  corporate,     // Korporativ
  graduation,    // Bitiruv kechasi
  anniversary,   // Yubiley
  babyShower,    // Baby shower
  engagement,    // Unashuv
  memorial,      // Marosim
}

extension EventTypeX on EventType {
  String get label => switch (this) {
        EventType.wedding      => 'To\'y',
        EventType.birthday     => 'Tug\'ilgan kun',
        EventType.corporate    => 'Korporativ',
        EventType.graduation   => 'Bitiruv kechasi',
        EventType.anniversary  => 'Yubiley',
        EventType.babyShower   => 'Baby shower',
        EventType.engagement   => 'Unashuv',
        EventType.memorial     => 'Marosim',
      };

  IconData get icon => switch (this) {
        EventType.wedding      => LucideIcons.heart,
        EventType.birthday     => LucideIcons.gift,
        EventType.corporate    => LucideIcons.building,
        EventType.graduation   => LucideIcons.graduationCap,
        EventType.anniversary  => LucideIcons.flower2,
        EventType.babyShower   => LucideIcons.baby,
        EventType.engagement   => LucideIcons.diamond,
        EventType.memorial     => LucideIcons.flower,
      };
}

/// Tadbir rejalashtiruvchi modeli
class EventPlanning {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<EventType> eventTypes;
  final Map<String, double> prices;
  final int maxGuests;
  final List<String> venues;

  const EventPlanning({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.eventTypes,
    required this.prices,
    required this.maxGuests,
    required this.venues,
  });

  factory EventPlanning.fromProviderJson(Map<String, dynamic> json) {
    return EventPlanning(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      eventTypes: const [EventType.wedding, EventType.birthday, EventType.corporate],
      prices: const {'To\'y (to\'liq tashkilot)': 5000000, 'Tug\'ilgan kun': 800000},
      maxGuests: 500,
      venues: const ['Restoran', 'Bog\'', 'Dam olish maskani'],
    );
  }

}
