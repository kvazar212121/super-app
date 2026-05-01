import 'package:flutter/material.dart';

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

  Duration get duration =>
      Duration(
        hours: end.hour - start.hour + (end.minute - start.minute) ~/ 60,
      );

  TimeSlot copyWith({
    String? id,
    TimeOfDay? start,
    TimeOfDay? end,
    bool? isAvailable,
    double? price,
  }) =>
      TimeSlot(
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

  const FieldAmenity({
    required this.name,
    required this.icon,
    this.price,
  });
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

  const FootballField({
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
  });

  /// Berilgan sana uchun slotlarni qaytaradi
  List<TimeSlot> getSlotsForDate(DateTime date) {
    final weekday = date.weekday; // 1=dushanba..7=yakshanba
    final isWeekend = weekday == 6 || weekday == 7;

    // Agar weeklySlots bo'sh bo'lsa, default slotlarni generatsiya qilamiz
    if (weeklySlots.isEmpty) {
      return _defaultSlots(isWeekend);
    }

    return weeklySlots[weekday] ?? _defaultSlots(isWeekend);
  }

  List<TimeSlot> _defaultSlots(bool isWeekend) {
    final slots = <TimeSlot>[];
    final startHours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];
    final multiplier = isWeekend ? 1.3 : 1.0; // dam olish kunlari narx yuqori

    for (var i = 0; i < startHours.length - 1; i++) {
      final h = startHours[i];
      final nextH = startHours[i + 1];
      // Tasodifiy bandlik (demo uchun)
      final isAvailable = (h + (int.tryParse(id) ?? 0)) % 3 != 0;
      slots.add(TimeSlot(
        id: '${id}_${h}00',
        start: TimeOfDay(hour: h, minute: 0),
        end: TimeOfDay(hour: nextH, minute: 0),
        isAvailable: isAvailable,
        price: (basePricePerHour * multiplier).roundToDouble(),
      ));
    }
    return slots;
  }

  // ============ Demo maydonlar ============

  static const List<FootballField> demoFields = [
    FootballField(
      id: '1',
      name: 'Lokomotiv Stadium',
      address: 'Toshkent, Mirzo Ulug‘bek tumani, Farg‘ona yo‘li',
      latitude: 41.3115,
      longitude: 69.2495,
      size: FieldSize.large,
      surface: FieldSurface.natural,
      rating: 4.8,
      reviewCount: 234,
      basePricePerHour: 450000,
      phoneNumber: '+998 71 200-10-10',
      hasLighting: true,
      hasParking: true,
      hasShowers: true,
      hasCafe: true,
      amenities: [
        FieldAmenity(name: 'Kiyim almashtirish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Toʻp ijarasi', icon: Icons.sports_soccer, price: 30000),
        FieldAmenity(name: 'Suv bepul', icon: Icons.water_drop),
      ],
    ),
    FootballField(
      id: '2',
      name: 'Bunyodkor Stadioni',
      address: 'Toshkent, Chilanzar tumani, Bunyodkor shoh koʻchasi',
      latitude: 41.302,
      longitude: 69.235,
      size: FieldSize.large,
      surface: FieldSurface.natural,
      rating: 4.9,
      reviewCount: 512,
      basePricePerHour: 550000,
      phoneNumber: '+998 71 230-20-20',
      hasLighting: true,
      hasParking: true,
      hasShowers: true,
      hasCafe: true,
      amenities: [
        FieldAmenity(name: 'VIP kiyinish xonasi', icon: Icons.star),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Hakam xizmati', icon: Icons.sports, price: 100000),
        FieldAmenity(name: 'Tablo', icon: Icons.scoreboard),
      ],
    ),
    FootballField(
      id: '3',
      name: 'Champion’s Field',
      address: 'Toshkent, Yakkasaroy tumani, Bobur koʻchasi',
      latitude: 41.318,
      longitude: 69.262,
      size: FieldSize.medium,
      surface: FieldSurface.artificial,
      rating: 4.6,
      reviewCount: 187,
      basePricePerHour: 280000,
      phoneNumber: '+998 90 300-30-30',
      hasLighting: true,
      hasParking: true,
      hasShowers: true,
      hasCafe: false,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Toʻp ijarasi', icon: Icons.sports_soccer, price: 20000),
      ],
    ),
    FootballField(
      id: '4',
      name: 'Mini Arena Tashkent',
      address: 'Toshkent, Sergeli tumani, Yangi Sergeli koʻchasi',
      latitude: 41.285,
      longitude: 69.220,
      size: FieldSize.small,
      surface: FieldSurface.artificial,
      rating: 4.4,
      reviewCount: 98,
      basePricePerHour: 180000,
      phoneNumber: '+998 93 400-40-40',
      hasLighting: true,
      hasParking: false,
      hasShowers: false,
      hasCafe: false,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Suv sotiladi', icon: Icons.local_drink),
      ],
    ),
    FootballField(
      id: '5',
      name: 'Green Park Stadium',
      address: 'Toshkent, Yunusobod tumani, Amir Temur koʻchasi',
      latitude: 41.340,
      longitude: 69.280,
      size: FieldSize.medium,
      surface: FieldSurface.natural,
      rating: 4.7,
      reviewCount: 321,
      basePricePerHour: 320000,
      phoneNumber: '+998 97 500-50-50',
      hasLighting: true,
      hasParking: true,
      hasShowers: true,
      hasCafe: true,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Sauna', icon: Icons.hot_tub, price: 80000),
        FieldAmenity(name: 'Fotosurat xizmati', icon: Icons.camera_alt, price: 50000),
      ],
    ),
    FootballField(
      id: '6',
      name: 'Real Madrid Academy',
      address: 'Toshkent, Olmazor tumani, Beruniy koʻchasi',
      latitude: 41.325,
      longitude: 69.230,
      size: FieldSize.small,
      surface: FieldSurface.parquet,
      rating: 4.5,
      reviewCount: 156,
      basePricePerHour: 150000,
      phoneNumber: '+998 88 600-60-60',
      hasLighting: true,
      hasParking: true,
      hasShowers: true,
      hasCafe: false,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Tribuna', icon: Icons.event_seat),
        FieldAmenity(name: 'Toʻp ijarasi', icon: Icons.sports_soccer, price: 15000),
      ],
    ),
    FootballField(
      id: '7',
      name: 'Spartak Arena',
      address: 'Toshkent, Uchtepa tumani, Lutfiy koʻchasi',
      latitude: 41.315,
      longitude: 69.195,
      size: FieldSize.medium,
      surface: FieldSurface.artificial,
      rating: 4.3,
      reviewCount: 89,
      basePricePerHour: 250000,
      phoneNumber: '+998 91 700-70-70',
      hasLighting: true,
      hasParking: true,
      hasShowers: false,
      hasCafe: false,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Avtoturargoh', icon: Icons.local_parking),
      ],
    ),
    FootballField(
      id: '8',
      name: 'Zamin Sport Majmuasi',
      address: 'Toshkent, Mirobod tumani, Shahrisabz koʻchasi',
      latitude: 41.298,
      longitude: 69.270,
      size: FieldSize.small,
      surface: FieldSurface.artificial,
      rating: 4.2,
      reviewCount: 67,
      basePricePerHour: 200000,
      phoneNumber: '+998 95 800-80-80',
      hasLighting: false,
      hasParking: true,
      hasShowers: false,
      hasCafe: false,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Suv bepul', icon: Icons.water_drop),
      ],
    ),
    FootballField(
      id: '9',
      name: 'Grand Sport Arena',
      address: 'Toshkent, Shayxontohur tumani, Navoiy koʻchasi',
      latitude: 41.328,
      longitude: 69.245,
      size: FieldSize.large,
      surface: FieldSurface.natural,
      rating: 4.6,
      reviewCount: 278,
      basePricePerHour: 400000,
      phoneNumber: '+998 99 900-90-90',
      hasLighting: true,
      hasParking: true,
      hasShowers: true,
      hasCafe: true,
      amenities: [
        FieldAmenity(name: 'VIP kiyinish xonasi', icon: Icons.star),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Hakam xizmati', icon: Icons.sports, price: 120000),
        FieldAmenity(name: 'Massaj', icon: Icons.spa, price: 100000),
        FieldAmenity(name: 'Tablo', icon: Icons.scoreboard),
      ],
    ),
    FootballField(
      id: '10',
      name: 'Olympus Futsal',
      address: 'Toshkent, Yashnobod tumani, Taraqqiyot koʻchasi',
      latitude: 41.308,
      longitude: 69.310,
      size: FieldSize.small,
      surface: FieldSurface.parquet,
      rating: 4.0,
      reviewCount: 45,
      basePricePerHour: 130000,
      phoneNumber: '+998 94 100-10-10',
      hasLighting: true,
      hasParking: false,
      hasShowers: true,
      hasCafe: false,
      amenities: [
        FieldAmenity(name: 'Kiyinish xonasi', icon: Icons.meeting_room),
        FieldAmenity(name: 'Dush', icon: Icons.shower),
        FieldAmenity(name: 'Toʻp ijarasi', icon: Icons.sports_soccer, price: 10000),
      ],
    ),
  ];
}