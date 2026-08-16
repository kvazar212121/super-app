import 'package:flutter/material.dart';
import '../utils/working_hours.dart';

import '../utils/geo_utils.dart';

/// Futbol maydoni qoplama turi
enum FieldSurface {
  natural, // tabiiy maysa
  artificial, // sun'iy qoplama
  parquet, // parket (zal)
}

extension FieldSurfaceX on FieldSurface {
  String get label => switch (this) {
    FieldSurface.natural => 'Tabiiy maysa',
    FieldSurface.artificial => 'Sunʼiy qoplama',
    FieldSurface.parquet => 'Parket (zal)',
  };

  IconData get icon => switch (this) {
    FieldSurface.natural => Icons.grass,
    FieldSurface.artificial => Icons.sports_soccer,
    FieldSurface.parquet => Icons.sports_basketball,
  };

  Color get color => switch (this) {
    FieldSurface.natural => const Color(0xFF4CAF50),
    FieldSurface.artificial => const Color(0xFF2196F3),
    FieldSurface.parquet => const Color(0xFFFF9800),
  };
}

/// Maydon o'lchami turi
enum FieldSize {
  small, // 5v5, 6v6
  medium, // 7v7, 8v8
  large, // 11v11
}

extension FieldSizeX on FieldSize {
  String get label => switch (this) {
    FieldSize.small => 'Kichik (5×5 / 6×6)',
    FieldSize.medium => "O'rta (7×7 / 8×8)",
    FieldSize.large => 'Katta (11×11)',
  };

  String get shortLabel => switch (this) {
    FieldSize.small => '5×5',
    FieldSize.medium => '7×7',
    FieldSize.large => '11×11',
  };

  int get minPlayers => switch (this) {
    FieldSize.small => 10,
    FieldSize.medium => 14,
    FieldSize.large => 22,
  };

  int get maxPlayers => switch (this) {
    FieldSize.small => 12,
    FieldSize.medium => 16,
    FieldSize.large => 22,
  };
}

/// Vaqt sloti
class TimeSlot {
  final String id;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isAvailable;
  final double price; // so'm

  const TimeSlot({
    required this.id,
    required this.start,
    required this.end,
    this.isAvailable = true,
    required this.price,
  });

  String get formatted =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} — '
      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

  Duration get duration => Duration(
    hours: end.hour - start.hour + (end.minute - start.minute) ~/ 60,
  );

  TimeSlot copyWith({
    String? id,
    TimeOfDay? start,
    TimeOfDay? end,
    bool? isAvailable,
    double? price,
  }) => TimeSlot(
    id: id ?? this.id,
    start: start ?? this.start,
    end: end ?? this.end,
    isAvailable: isAvailable ?? this.isAvailable,
    price: price ?? this.price,
  );
}

/// Qo'shimcha xizmatlar
class FieldAmenity {
  final String name;
  final IconData icon;
  final double? price; // null bo'lsa bepul

  const FieldAmenity({required this.name, required this.icon, this.price});
}

/// Futbol maydoni modeli
class FootballField {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final FieldSize size;
  final FieldSurface surface;
  final double rating; // 1.0 — 5.0
  final int reviewCount;
  final double basePricePerHour; // 1 soat uchun narx (so'm)
  final String? imageUrl;
  final List<FieldAmenity> amenities;
  final List<String> photos; // rasm URL'lari
  final String phoneNumber;
  final bool hasLighting; // yoritish
  final bool hasParking; // avtoturargoh
  final bool hasShowers; // dush
  final bool hasCafe; // kafe

  /// Har bir kun uchun vaqt slotlari (hafta kunlari bo'yicha)
  /// Kalit — DateTime.weekday (1=dushanba...7=yakshanba)
  final Map<int, List<TimeSlot>> weeklySlots;
  final Map<String, dynamic>? rawJson;

  final String? subCategory;

  FootballField({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.size,
    required this.surface,
    required this.rating,
    required this.reviewCount,
    required this.basePricePerHour,
    this.imageUrl,
    this.amenities = const [],
    this.photos = const [],
    this.phoneNumber = '',
    this.hasLighting = false,
    this.hasParking = false,
    this.hasShowers = false,
    this.hasCafe = false,
    this.weeklySlots = const {},
    this.rawJson,
    this.subCategory,
  });

  /// Backend provider ID.
  int get providerId => int.tryParse(id) ?? 0;

  factory FootballField.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    FieldSize parseSize(String? s) => switch (s) {
      'small' => FieldSize.small,
      'medium' => FieldSize.medium,
      'large' => FieldSize.large,
      _ => FieldSize.medium,
    };
    FieldSurface parseSurface(String? s) => switch (s) {
      'natural' => FieldSurface.natural,
      'artificial' => FieldSurface.artificial,
      'parquet' => FieldSurface.parquet,
      _ => FieldSurface.artificial,
    };
    final basePrice =
        (meta['base_price_per_hour'] as num?)?.toDouble() ?? 200000;
    final slotHours = (meta['time_slots'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    return FootballField(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      size: parseSize(meta['size'] as String?),
      surface: parseSurface(meta['surface'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      basePricePerHour: basePrice,
      phoneNumber: json['phone'] ?? '',
      hasLighting: meta['has_lighting'] != false,
      hasParking: meta['has_parking'] != false,
      hasShowers: meta['has_showers'] != false,
      hasCafe: meta['has_cafe'] == true,
      weeklySlots: slotHours != null && slotHours.isNotEmpty
          ? {
              for (var d = 1; d <= 7; d++)
                d: _slotsFromHours(
                  slotHours,
                  basePrice,
                  json['id']?.toString() ?? '',
                ),
            }
          : const {},
      rawJson: json,
      subCategory: meta['sub_category']?.toString(),
    );
  }

  static List<TimeSlot> _slotsFromHours(
    List<String> hours,
    double basePrice,
    String fieldId, {
    Set<String> booked = const {},
  }) {
    final slots = <TimeSlot>[];
    for (var i = 0; i < hours.length; i++) {
      final parts = hours[i].split(':');
      final h = int.tryParse(parts[0]) ?? 9;
      final key = '${h.toString().padLeft(2, '0')}:00';
      final endH = i + 1 < hours.length
          ? int.tryParse(hours[i + 1].split(':').first) ?? (h + 1)
          : h + 1;
      slots.add(
        TimeSlot(
          id: '${fieldId}_$key',
          start: TimeOfDay(hour: h, minute: 0),
          end: TimeOfDay(hour: endH, minute: 0),
          isAvailable: !booked.contains(key) && !booked.contains(hours[i]),
          price: basePrice,
        ),
      );
    }
    return slots;
  }

  double distanceKmFrom(double userLat, double userLng) =>
      distanceKm(userLat, userLng, latitude, longitude);

  /// Hozir ochiqmi. Maydon ish vaqtini kiritgan bo'lsa SHU ishlatiladi,
  /// aks holda maydonlar uchun odatiy 8:00–23:00.
  bool isOpenNow([DateTime? now]) => isOpenAt(
        hours: workingHoursFrom(rawJson),
        defaultOpen: 8,
        defaultClose: 23,
        now: now,
      );

  String get priceLabel => '${basePricePerHour.round()} so\'m/soat';

  String get sizeSurfaceLabel => '${size.shortLabel} · ${surface.label}';

  /// Berilgan sana uchun slotlarni qaytaradi
  List<TimeSlot> getSlotsForDate(
    DateTime date, {
    Set<String> booked = const {},
  }) {
    final weekday = date.weekday; // 1=dushanba..7=yakshanba
    final isWeekend = weekday == 6 || weekday == 7;

    // Agar weeklySlots bo'sh bo'lsa, default slotlarni generatsiya qilamiz
    if (weeklySlots.isEmpty) {
      return _defaultSlots(isWeekend, booked: booked);
    }

    final base =
        weeklySlots[weekday] ?? _defaultSlots(isWeekend, booked: booked);
    if (booked.isEmpty) return base;
    return base
        .map(
          (s) => s.copyWith(
            isAvailable: s.isAvailable && !booked.contains(_slotKey(s.start)),
          ),
        )
        .toList();
  }

  String _slotKey(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<TimeSlot> _defaultSlots(
    bool isWeekend, {
    Set<String> booked = const {},
  }) {
    final slots = <TimeSlot>[];
    final startHours = [
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
    ];
    final multiplier = isWeekend ? 1.3 : 1.0; // dam olish kunlari narx yuqori

    for (var i = 0; i < startHours.length - 1; i++) {
      final h = startHours[i];
      final nextH = startHours[i + 1];
      final key = '${h.toString().padLeft(2, '0')}:00';
      final isAvailable = !booked.contains(key);
      slots.add(
        TimeSlot(
          id: '${id}_${h}00',
          start: TimeOfDay(hour: h, minute: 0),
          end: TimeOfDay(hour: nextH, minute: 0),
          isAvailable: isAvailable,
          price: (basePricePerHour * multiplier).roundToDouble(),
        ),
      );
    }
    return slots;
  }
}
