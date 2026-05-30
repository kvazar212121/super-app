import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  static List<EventPlanning> demoPlanners = [
    EventPlanning(
      id: 'ep1',
      name: "To'y Rejissyor",
      latitude: 41.3165,
      longitude: 69.2565,
      rating: 4.9,
      reviewCount: 312,
      phoneNumber: '+998 90 666 77 88',
      eventTypes: [EventType.wedding, EventType.engagement, EventType.anniversary],
      prices: {
        'To\'y (to\'liq tashkilot)': 5000000,
        'Unashuv': 1500000,
        'Yubiley': 2000000,
        'Dekoratsiya': 1000000,
        'Fotosurat + Video': 1500000,
        'Musiqa / DJ': 800000,
        'Konsultatsiya': 100000,
      },
      maxGuests: 500,
      venues: ['Grand Mir Hotel', 'Toshkent Palace', 'Samarqand Darvoza', 'Navruz Restaurant'],
    ),
    EventPlanning(
      id: 'ep2',
      name: 'Event Pro',
      latitude: 41.3015,
      longitude: 69.2445,
      rating: 4.7,
      reviewCount: 198,
      phoneNumber: '+998 93 999 00 11',
      eventTypes: [EventType.corporate, EventType.birthday, EventType.graduation],
      prices: {
        'Korporativ tadbir': 3000000,
        'Tug\'ilgan kun': 800000,
        'Bitiruv kechasi': 1200000,
        'Dekoratsiya': 500000,
        'Fotosurat': 600000,
        'Musiqa': 400000,
        'Konsultatsiya': 80000,
      },
      maxGuests: 300,
      venues: ['Hyatt Regency', 'Central Hall', 'Art Zone', 'Sky Lounge'],
    ),
    EventPlanning(
      id: 'ep3',
      name: 'Bayram Tashkilot',
      latitude: 41.3285,
      longitude: 69.2765,
      rating: 4.6,
      reviewCount: 145,
      phoneNumber: '+998 94 222 33 44',
      eventTypes: [EventType.birthday, EventType.babyShower, EventType.graduation, EventType.corporate],
      prices: {
        'Tug\'ilgan kun': 600000,
        'Baby shower': 500000,
        'Bitiruv kechasi': 900000,
        'Korporativ tadbir': 2500000,
        'Dekoratsiya': 400000,
        'Fotosurat': 500000,
        'Konsultatsiya': 50000,
      },
      maxGuests: 200,
      venues: ['Garden Park', 'Family Hall', 'Kids Zone', 'Coffee House'],
    ),
    EventPlanning(
      id: 'ep4',
      name: 'Dam Olish Pro',
      latitude: 41.3105,
      longitude: 69.2885,
      rating: 4.8,
      reviewCount: 267,
      phoneNumber: '+998 97 555 66 77',
      eventTypes: [EventType.wedding, EventType.birthday, EventType.corporate, EventType.anniversary, EventType.engagement, EventType.babyShower, EventType.graduation, EventType.memorial],
      prices: {
        'To\'y (to\'liq tashkilot)': 4500000,
        'Tug\'ilgan kun': 700000,
        'Korporativ tadbir': 2800000,
        'Yubiley': 1800000,
        'Unashuv': 1200000,
        'Baby shower': 550000,
        'Bitiruv kechasi': 1000000,
        'Marosim': 800000,
        'Dekoratsiya': 600000,
        'Fotosurat + Video': 1200000,
        'Musiqa / DJ': 600000,
        'Konsultatsiya': 80000,
      },
      maxGuests: 400,
      venues: ['Grand Mir Hotel', 'Hyatt Regency', 'Samarqand Darvoza', 'Central Hall', 'Garden Park', 'Art Zone'],
    ),
  ];
}
