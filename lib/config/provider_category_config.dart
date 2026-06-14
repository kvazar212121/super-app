import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Provider ro'yxatdan o'tish ID → backend category_key
class ProviderCategoryConfig {
  final String registrationId;
  final String categoryKey;
  final String title;
  final IconData icon;
  final Color accentColor;

  const ProviderCategoryConfig({
    required this.registrationId,
    required this.categoryKey,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  static const all = [
    barber, salon, plumber, electrician, cleaner, auto, futbol,
    education, builder, worker, ac, nanny, tutor, disinfection,
    appliance, courier, massage, nurse, dental, events,
    bozorchi, oshxona,
    gameZona, sportMaydon,
    kompUsta, boshqa,
  ];

  static ProviderCategoryConfig? byRegistrationId(String id) {
    for (final c in all) {
      if (c.registrationId == id) return c;
    }
    return null;
  }

  static ProviderCategoryConfig? byCategoryKey(String key) {
    for (final c in all) {
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
  );
  static const salon = ProviderCategoryConfig(
    registrationId: 'salon',
    categoryKey: 'salon',
    title: 'Salon',
    icon: LucideIcons.sparkles,
    accentColor: Color(0xFFEC4899),
  );
  static const plumber = ProviderCategoryConfig(
    registrationId: 'plumber',
    categoryKey: 'santexnik',
    title: 'Santexnik',
    icon: LucideIcons.droplet,
    accentColor: Color(0xFF3B82F6),
  );
  static const electrician = ProviderCategoryConfig(
    registrationId: 'electrician',
    categoryKey: 'elektrik',
    title: 'Elektrik',
    icon: LucideIcons.zap,
    accentColor: Color(0xFFF59E0B),
  );
  static const cleaner = ProviderCategoryConfig(
    registrationId: 'cleaner',
    categoryKey: 'tozalash',
    title: 'Tozalash',
    icon: LucideIcons.sprayCan,
    accentColor: Color(0xFF10B981),
  );
  static const auto = ProviderCategoryConfig(
    registrationId: 'auto',
    categoryKey: 'avtoYordam',
    title: 'Avto-yordam',
    icon: LucideIcons.car,
    accentColor: Color(0xFF8B5CF6),
  );
  static const futbol = ProviderCategoryConfig(
    registrationId: 'futbol',
    categoryKey: 'futbol',
    title: 'Futbol maydoni',
    icon: LucideIcons.trophy,
    accentColor: Color(0xFF22C55E),
  );
  static const education = ProviderCategoryConfig(
    registrationId: 'education',
    categoryKey: 'repetitor',
    title: 'O\'quv markazi',
    icon: LucideIcons.graduationCap,
    accentColor: Color(0xFF6366F1),
  );
  static const builder = ProviderCategoryConfig(
    registrationId: 'builder',
    categoryKey: 'usta',
    title: 'Usta',
    icon: LucideIcons.hammer,
    accentColor: Color(0xFF78716C),
  );
  static const worker = ProviderCategoryConfig(
    registrationId: 'worker',
    categoryKey: 'ishchi',
    title: 'Ishchi',
    icon: LucideIcons.hardHat,
    accentColor: Color(0xFFF97316),
  );
  static const ac = ProviderCategoryConfig(
    registrationId: 'ac',
    categoryKey: 'konditsioner',
    title: 'Konditsioner',
    icon: LucideIcons.wind,
    accentColor: Color(0xFF06B6D4),
  );
  static const nanny = ProviderCategoryConfig(
    registrationId: 'nanny',
    categoryKey: 'enaga',
    title: 'Enaga',
    icon: LucideIcons.baby,
    accentColor: Color(0xFFF472B6),
  );
  static const tutor = ProviderCategoryConfig(
    registrationId: 'tutor',
    categoryKey: 'repetitor',
    title: 'Repetitor',
    icon: LucideIcons.bookOpen,
    accentColor: Color(0xFF8B5CF6),
  );
  static const disinfection = ProviderCategoryConfig(
    registrationId: 'disinfection',
    categoryKey: 'dezinfeksiya',
    title: 'Dezinfeksiya',
    icon: LucideIcons.shieldCheck,
    accentColor: Color(0xFF14B8A6),
  );
  static const appliance = ProviderCategoryConfig(
    registrationId: 'appliance',
    categoryKey: 'texnikaUstasi',
    title: 'Texnika ustasi',
    icon: LucideIcons.refrigerator,
    accentColor: Color(0xFF64748B),
  );
  static const courier = ProviderCategoryConfig(
    registrationId: 'courier',
    categoryKey: 'kuryerlik',
    title: 'Kuryer',
    icon: LucideIcons.package,
    accentColor: Color(0xFF0EA5E9),
  );
  static const massage = ProviderCategoryConfig(
    registrationId: 'massage',
    categoryKey: 'massajHijoma',
    title: 'Massaj',
    icon: LucideIcons.heartPulse,
    accentColor: Color(0xFFE11D48),
  );
  static const nurse = ProviderCategoryConfig(
    registrationId: 'nurse',
    categoryKey: 'hamshira',
    title: 'Hamshira',
    icon: LucideIcons.stethoscope,
    accentColor: Color(0xFFEF4444),
  );
  static const dental = ProviderCategoryConfig(
    registrationId: 'dental',
    categoryKey: 'stomatologiya',
    title: 'Stomatologiya',
    icon: LucideIcons.smile,
    accentColor: Color(0xFF0EA5E9),
  );
  static const events = ProviderCategoryConfig(
    registrationId: 'events',
    categoryKey: 'tadbirlar',
    title: 'Tadbirlar',
    icon: LucideIcons.partyPopper,
    accentColor: Color(0xFFA855F7),
  );
  static const bozorchi = ProviderCategoryConfig(
    registrationId: 'bozorchi',
    categoryKey: 'bozorchi',
    title: 'Bozorchi',
    icon: LucideIcons.shoppingCart,
    accentColor: Color(0xFFFF9800),
  );
  static const oshxona = ProviderCategoryConfig(
    registrationId: 'oshxona',
    categoryKey: 'oshxona',
    title: 'Oshxona',
    icon: LucideIcons.utensils,
    accentColor: Color(0xFFF44336),
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
  );
  static const boshqa = ProviderCategoryConfig(
    registrationId: 'boshqa_xizmatlar',
    categoryKey: 'boshqa_xizmatlar',
    title: 'Boshqa Xizmatlar',
    icon: LucideIcons.layoutGrid,
    accentColor: Color(0xFF9E9E9E),
  );
}
