import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Provider ro'yxatdan o'tish ID → backend category_key
class ProviderCategoryConfig {
  final String registrationId;
  final String categoryKey;
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<String>? subCategories;

  const ProviderCategoryConfig({
    required this.registrationId,
    required this.categoryKey,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.subCategories,
  });

  static const all = [
    barber,
    salon,
    plumber,
    electrician,
    cleaner,
    auto,
    futbol,
    education,
    builder,
    worker,
    nanny,
    tutor,
    disinfection,
    appliance,
    courier,
    massage,
    nurse,
    dental,
    events,
    bozorchi,
    oshxona,
    gameZona,
    sportMaydon,
    kompUsta,
    boshqa,
  ];

  /// [all] — YANGI ro'yxatdan o'tish uchun ochiq kategoriyalar.
  ///
  /// [legacy] — endi taklif qilinmaydigan, ammo AVVAL shu kategoriyada
  /// ro'yxatdan o'tgan provayderlar paneli ochilishi uchun zarur konfiguratsiya.
  /// Konditsioner "Texnika ustasi" ichiga ko'chirilgan.
  // ignore: deprecated_member_use_from_same_package
  static const legacy = [ac];

  /// Yangi + eskirgan kategoriyalar (qidiruv uchun).
  static const allIncludingLegacy = [...all, ...legacy];

  static ProviderCategoryConfig? byRegistrationId(String id) {
    for (final c in allIncludingLegacy) {
      if (c.registrationId == id) return c;
    }
    return null;
  }

  static ProviderCategoryConfig? byCategoryKey(String key) {
    for (final c in allIncludingLegacy) {
      if (c.categoryKey == key) return c;
    }
    return null;
  }

  static const barber = ProviderCategoryConfig(
    registrationId: 'barber',
    categoryKey: 'sartarosh',
    title: 'Sartarosh',
    icon: LucideIcons.scissors,
    accentColor: Color(0xFF6366F1),
    subCategories: ['Oddiy', 'Biznes', 'Class (Premium)'],
  );
  static const salon = ProviderCategoryConfig(
    registrationId: 'salon',
    categoryKey: 'salon',
    title: 'Salon',
    icon: LucideIcons.sparkles,
    accentColor: Color(0xFFEC4899),
    subCategories: ['Soch turmagi', 'Makiyaj', 'Manikyur', 'Kosmetologiya'],
  );
  static const plumber = ProviderCategoryConfig(
    registrationId: 'plumber',
    categoryKey: 'santexnik',
    title: 'Santexnik',
    icon: LucideIcons.droplet,
    accentColor: Color(0xFF3B82F6),
    subCategories: [
      'Quvurlar',
      'Kran va vanna',
      'Issiqlik tizimi',
      'Shoshilinch',
    ],
  );
  static const electrician = ProviderCategoryConfig(
    registrationId: 'electrician',
    categoryKey: 'elektrik',
    title: 'Elektrik',
    icon: LucideIcons.zap,
    accentColor: Color(0xFFF59E0B),
    subCategories: [
      'Montaj',
      'Rozetka va chiroq',
      'Diagnostika',
      'Shoshilinch',
    ],
  );
  static const cleaner = ProviderCategoryConfig(
    registrationId: 'cleaner',
    categoryKey: 'tozalash',
    title: 'Tozalash',
    icon: LucideIcons.sprayCan,
    accentColor: Color(0xFF10B981),
    subCategories: [
      'Uy tozalash',
      'Ofis tozalash',
      'Gilam yuvish',
      'Deraza yuvish',
    ],
  );
  static const auto = ProviderCategoryConfig(
    registrationId: 'auto',
    categoryKey: 'avtoYordam',
    title: 'Avto-yordam',
    icon: LucideIcons.car,
    accentColor: Color(0xFF8B5CF6),
    subCategories: [
      'Evakuator',
      'Shina montaj',
      'Diagnostika',
      'Mator ustasi',
      'Xodovoy',
    ],
  );
  static const futbol = ProviderCategoryConfig(
    registrationId: 'futbol',
    categoryKey: 'futbol',
    title: 'Futbol maydoni',
    icon: LucideIcons.trophy,
    accentColor: Color(0xFF22C55E),
    subCategories: ['Yopiq maydon', 'Ochiq maydon', 'Mini futbol'],
  );
  static const education = ProviderCategoryConfig(
    registrationId: 'education',
    categoryKey: 'repetitor',
    title: 'O\'quv markazi',
    icon: LucideIcons.graduationCap,
    accentColor: Color(0xFF6366F1),
    subCategories: ['Maktab fanlari', 'Tillar', 'IT', 'Musiqa'],
  );
  static const builder = ProviderCategoryConfig(
    registrationId: 'builder',
    categoryKey: 'usta',
    title: 'Usta',
    icon: LucideIcons.hammer,
    accentColor: Color(0xFF78716C),
    subCategories: [
      'Pardozlash',
      'Qurilish',
      'Santexnika',
      'Elektrika',
      'Boshqa',
    ],
  );
  static const worker = ProviderCategoryConfig(
    registrationId: 'worker',
    categoryKey: 'ishchi',
    title: 'Ishchi',
    icon: LucideIcons.hardHat,
    accentColor: Color(0xFFF97316),
    subCategories: [
      'Yuk tashuvchi',
      'Qurilish yordamchisi',
      'Bog\'bon',
      'Qorovul',
    ],
  );
  /// ESKIRGAN: Konditsioner endi "Texnika ustasi" ichidagi subkategoriya.
  /// Yangi ro'yxatdan o'tish uchun ishlatilmaydi ([all] ro'yxatida yo'q),
  /// ammo AVVAL shu kategoriyada ro'yxatdan o'tgan provayderlarning paneli
  /// ochilishi uchun konfiguratsiya saqlab qolinadi.
  @Deprecated('Konditsioner "Texnika ustasi" ichiga ko\'chirildi')
  static const ac = ProviderCategoryConfig(
    registrationId: 'ac',
    categoryKey: 'konditsioner',
    title: 'Konditsioner',
    icon: LucideIcons.wind,
    accentColor: Color(0xFF06B6D4),
    subCategories: ['O\'rnatish', 'Ta\'mirlash', 'Tozalash', 'Freon quyish'],
  );
  static const nanny = ProviderCategoryConfig(
    registrationId: 'nanny',
    categoryKey: 'enaga',
    title: 'Enaga',
    icon: LucideIcons.baby,
    accentColor: Color(0xFFF472B6),
    subCategories: ['Kunduzgi', 'Tungi', 'Soatbay', 'Chaqaloqlar uchun'],
  );
  static const tutor = ProviderCategoryConfig(
    registrationId: 'tutor',
    categoryKey: 'repetitor',
    title: 'Repetitor',
    icon: LucideIcons.bookOpen,
    accentColor: Color(0xFF8B5CF6),
    subCategories: ['Maktab fanlari', 'Tillar', 'IT', 'Musiqa'],
  );
  static const disinfection = ProviderCategoryConfig(
    registrationId: 'disinfection',
    categoryKey: 'dezinfeksiya',
    title: 'Dezinfeksiya',
    icon: LucideIcons.shieldCheck,
    accentColor: Color(0xFF14B8A6),
    subCategories: ['Hasharotlar', 'Kemeruvchilar', 'Viruslar'],
  );
  static const appliance = ProviderCategoryConfig(
    registrationId: 'appliance',
    categoryKey: 'texnikaUstasi',
    title: 'Texnika ustasi',
    icon: LucideIcons.refrigerator,
    accentColor: Color(0xFF64748B),
    // Konditsioner endi ALOHIDA kategoriya emas — shu yerning bir turi.
    subCategories: [
      'Katta texnika',
      'Mayda texnika',
      'Oshxona texnikasi',
      'Konditsioner o\'rnatish',
      'Konditsioner ta\'mirlash',
      'Konditsioner tozalash',
      'Freon quyish',
    ],
  );
  static const courier = ProviderCategoryConfig(
    registrationId: 'courier',
    categoryKey: 'kuryerlik',
    title: 'Kuryer',
    icon: LucideIcons.package,
    accentColor: Color(0xFF0EA5E9),
    subCategories: ['Hujjatlar', 'Yuk', 'Piyoda kuryer', 'Avto kuryer'],
  );
  static const massage = ProviderCategoryConfig(
    registrationId: 'massage',
    categoryKey: 'massajHijoma',
    title: 'Massaj',
    icon: LucideIcons.heartPulse,
    accentColor: Color(0xFFE11D48),
    subCategories: ['Hijoma', 'Massaj'],
  );
  static const nurse = ProviderCategoryConfig(
    registrationId: 'nurse',
    categoryKey: 'hamshira',
    title: 'Hamshira',
    icon: LucideIcons.stethoscope,
    accentColor: Color(0xFFEF4444),
    subCategories: ['Ukol', 'Kapelnitsa', 'Qariyalar parvarishi'],
  );
  static const dental = ProviderCategoryConfig(
    registrationId: 'dental',
    categoryKey: 'stomatologiya',
    title: 'Stomatologiya',
    icon: LucideIcons.smile,
    accentColor: Color(0xFF0EA5E9),
    subCategories: [
      'Terapiya',
      'Jarrohlik',
      'Ortodontiya',
      'Bolalar stomatologi',
    ],
  );
  static const events = ProviderCategoryConfig(
    registrationId: 'events',
    categoryKey: 'tadbirlar',
    title: 'Tadbirlar',
    icon: LucideIcons.partyPopper,
    accentColor: Color(0xFFA855F7),
    subCategories: ['To\'y', 'Tug\'ilgan kun', 'Korporativ', 'Fotosessiya'],
  );
  static const bozorchi = ProviderCategoryConfig(
    registrationId: 'bozorchi',
    categoryKey: 'bozorchi',
    title: 'Bozorchi',
    icon: LucideIcons.shoppingCart,
    accentColor: Color(0xFFFF9800),
    subCategories: ['Oziq-ovqat', 'Kiyim-kechak', 'Uy-ro\'zg\'or', 'Boshqa'],
  );
  static const oshxona = ProviderCategoryConfig(
    registrationId: 'oshxona',
    categoryKey: 'oshxona',
    title: 'Oshxona',
    icon: LucideIcons.utensils,
    accentColor: Color(0xFFF44336),
    subCategories: ['Milliy taomlar', 'Fast food', 'Yevropa', 'Shirinliklar'],
  );
  static const gameZona = ProviderCategoryConfig(
    registrationId: 'game_zona',
    categoryKey: 'game_zona',
    title: 'Game Zona',
    icon: LucideIcons.gamepad2,
    accentColor: Color(0xFF673AB7),
  );
  static const sportMaydon = ProviderCategoryConfig(
    registrationId: 'sport_maydon',
    categoryKey: 'sport_maydon',
    title: 'Sport Maydonlari',
    icon: Icons.sports_soccer,
    accentColor: Color(0xFF4CAF50),
  );
  static const kompUsta = ProviderCategoryConfig(
    registrationId: 'kompyuter_usta',
    categoryKey: 'kompyuter_usta',
    title: 'Kompyuter Ustasi',
    icon: LucideIcons.monitor,
    accentColor: Color(0xFF607D8B),
    subCategories: [
      'Dasturiy ta\'minot',
      'Qurilma ta\'miri',
      'Tarmoq',
      'Noutbuk ta\'miri',
    ],
  );
  static const boshqa = ProviderCategoryConfig(
    registrationId: 'boshqa_xizmatlar',
    // Backend'da bu kategoriya kaliti 'yana' — panelni ochish uchun mos bo'lsin.
    categoryKey: 'yana',
    title: 'Boshqa Xizmatlar',
    icon: LucideIcons.layoutGrid,
    accentColor: Color(0xFF9E9E9E),
  );
}
