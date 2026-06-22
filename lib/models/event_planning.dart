import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tadbir turi
enum EventType {
  wedding,
  birthday,
  corporate,
  graduation,
  anniversary,
  babyShower,
  engagement,
  memorial,
}

extension EventTypeX on EventType {
  static EventType? fromKey(String key) {
    final k = key.replaceAll('-', '_');
    return switch (k) {
      'wedding' => EventType.wedding,
      'birthday' => EventType.birthday,
      'corporate' => EventType.corporate,
      'graduation' => EventType.graduation,
      'anniversary' => EventType.anniversary,
      'baby_shower' => EventType.babyShower,
      'engagement' => EventType.engagement,
      'memorial' => EventType.memorial,
      _ => null,
    };
  }

  String get key => switch (this) {
        EventType.wedding => 'wedding',
        EventType.birthday => 'birthday',
        EventType.corporate => 'corporate',
        EventType.graduation => 'graduation',
        EventType.anniversary => 'anniversary',
        EventType.babyShower => 'baby_shower',
        EventType.engagement => 'engagement',
        EventType.memorial => 'memorial',
      };

  String get label => switch (this) {
        EventType.wedding => 'To\'y',
        EventType.birthday => 'Tug\'ilgan kun',
        EventType.corporate => 'Korporativ',
        EventType.graduation => 'Bitiruv kechasi',
        EventType.anniversary => 'Yubiley',
        EventType.babyShower => 'Baby shower',
        EventType.engagement => 'Unashuv',
        EventType.memorial => 'Marosim',
      };

  IconData get icon => switch (this) {
        EventType.wedding => LucideIcons.heart,
        EventType.birthday => LucideIcons.gift,
        EventType.corporate => LucideIcons.building,
        EventType.graduation => LucideIcons.graduationCap,
        EventType.anniversary => LucideIcons.flower2,
        EventType.babyShower => LucideIcons.baby,
        EventType.engagement => LucideIcons.diamond,
        EventType.memorial => LucideIcons.flower,
      };
}

/// Guruh qanday xizmat ko'rsatadi
enum OrganizerServiceType {
  stageSetup,
  soundLight,
  decor,
  fullOrganization,
  villageEvents,
}

extension OrganizerServiceTypeX on OrganizerServiceType {
  static OrganizerServiceType? fromKey(String key) {
    final k = key.replaceAll('-', '_');
    return switch (k) {
      'stage_setup' => OrganizerServiceType.stageSetup,
      'sound_light' => OrganizerServiceType.soundLight,
      'decor' => OrganizerServiceType.decor,
      'full_organization' => OrganizerServiceType.fullOrganization,
      'village_events' => OrganizerServiceType.villageEvents,
      _ => null,
    };
  }

  String get key => switch (this) {
        OrganizerServiceType.stageSetup => 'stage_setup',
        OrganizerServiceType.soundLight => 'sound_light',
        OrganizerServiceType.decor => 'decor',
        OrganizerServiceType.fullOrganization => 'full_organization',
        OrganizerServiceType.villageEvents => 'village_events',
      };

  String get label => switch (this) {
        OrganizerServiceType.stageSetup => 'Sahna va podiyom',
        OrganizerServiceType.soundLight => 'Ovoz va yoritish',
        OrganizerServiceType.decor => 'Dekoratsiya',
        OrganizerServiceType.fullOrganization => 'To\'liq tashkilot',
        OrganizerServiceType.villageEvents => 'Qishloq / ochiq maydon',
      };

  IconData get icon => switch (this) {
        OrganizerServiceType.stageSetup => LucideIcons.tent,
        OrganizerServiceType.soundLight => LucideIcons.volume2,
        OrganizerServiceType.decor => LucideIcons.sparkles,
        OrganizerServiceType.fullOrganization => LucideIcons.partyPopper,
        OrganizerServiceType.villageEvents => LucideIcons.trees,
      };
}

/// Tadbir joyi turi
enum EventVenueType {
  villageYard,
  openField,
  restaurant,
  garden,
  hall,
  clientLocation,
}

extension EventVenueTypeX on EventVenueType {
  static EventVenueType? fromKey(String key) {
    final k = key.replaceAll('-', '_');
    return switch (k) {
      'village_yard' => EventVenueType.villageYard,
      'open_field' => EventVenueType.openField,
      'restaurant' => EventVenueType.restaurant,
      'garden' => EventVenueType.garden,
      'hall' => EventVenueType.hall,
      'client_location' => EventVenueType.clientLocation,
      _ => null,
    };
  }

  String get key => switch (this) {
        EventVenueType.villageYard => 'village_yard',
        EventVenueType.openField => 'open_field',
        EventVenueType.restaurant => 'restaurant',
        EventVenueType.garden => 'garden',
        EventVenueType.hall => 'hall',
        EventVenueType.clientLocation => 'client_location',
      };

  String get label => switch (this) {
        EventVenueType.villageYard => 'Qishloq hovli',
        EventVenueType.openField => 'Ochiq maydon',
        EventVenueType.restaurant => 'Restoran / to\'yxona',
        EventVenueType.garden => 'Bog\' / dam olish',
        EventVenueType.hall => 'Zal',
        EventVenueType.clientLocation => 'Mijoz ko\'rsatgan joy',
      };
}

/// Tadbir tashkil etuvchi guruh
class EventPlanning {
  final String id;
  final int providerId;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String? serviceArea;
  final int teamSize;
  final List<EventType> eventTypes;
  final List<OrganizerServiceType> organizerTypes;
  final List<String> venueLabels;
  final Map<String, double> prices;
  final int maxGuests;
  final List<String> timeSlots;
  final Map<String, dynamic>? rawJson;

  const EventPlanning({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    this.serviceArea,
    this.teamSize = 1,
    required this.eventTypes,
    required this.organizerTypes,
    required this.venueLabels,
    required this.prices,
    this.maxGuests = 500,
    this.timeSlots = const [],
    this.rawJson,
  });

  String get capabilitiesLabel {
    if (organizerTypes.isEmpty) return 'Tadbir tashkiloti';
    return organizerTypes.map((e) => e.label).take(2).join(' · ');
  }

  bool get supportsVillage =>
      organizerTypes.contains(OrganizerServiceType.villageEvents) ||
      organizerTypes.contains(OrganizerServiceType.stageSetup);

  factory EventPlanning.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};

    final eventKeys = (meta['event_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    var events = eventKeys.map(EventTypeX.fromKey).whereType<EventType>().toList();
    if (events.isEmpty) {
      events = [EventType.wedding, EventType.birthday, EventType.corporate];
    }

    final orgKeys = (meta['organizer_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    var orgs =
        orgKeys.map(OrganizerServiceTypeX.fromKey).whereType<OrganizerServiceType>().toList();
    if (orgs.isEmpty) {
      orgs = [
        OrganizerServiceType.stageSetup,
        OrganizerServiceType.fullOrganization,
      ];
    }

    final venueKeys = (meta['venue_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final venues = venueKeys.map(EventVenueTypeX.fromKey).whereType<EventVenueType>().toList();
    final venueLabels = venues.isEmpty
        ? ['Qishloq hovli', 'Ochiq maydon', 'Restoran', 'Bog\'']
        : venues.map((v) => v.label).toList();

    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.isEmpty
        ? {
            'Sahna va podiyom o\'rnatish (qishloq / maydon)': 2500000.0,
            'To\'y — to\'liq tashkilot': 15000000.0,
          }
        : pricesRaw.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0));

    return EventPlanning(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone']?.toString() ?? '',
      serviceArea: meta['service_area']?.toString(),
      teamSize: (meta['team_size'] as num?)?.toInt() ?? 1,
      eventTypes: events,
      organizerTypes: orgs,
      venueLabels: venueLabels,
      prices: prices,
      maxGuests: (meta['max_guests'] as num?)?.toInt() ?? 500,
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rawJson: json,
    );
  }
}
