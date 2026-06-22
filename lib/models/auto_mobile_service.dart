import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AutoVehicleType { evakuator, serviceVan, fuelTruck, combo }

extension AutoVehicleTypeX on AutoVehicleType {
  String get key => switch (this) {
        AutoVehicleType.evakuator => 'evakuator',
        AutoVehicleType.serviceVan => 'service_van',
        AutoVehicleType.fuelTruck => 'fuel_truck',
        AutoVehicleType.combo => 'combo',
      };

  String get label => switch (this) {
        AutoVehicleType.evakuator => 'Evakuator',
        AutoVehicleType.serviceVan => 'Xizmat mashinasi',
        AutoVehicleType.fuelTruck => 'Benzin yetkazuvchi',
        AutoVehicleType.combo => 'Ko\'p funksiyali',
      };

  IconData get icon => switch (this) {
        AutoVehicleType.evakuator => LucideIcons.truck,
        AutoVehicleType.serviceVan => LucideIcons.wrench,
        AutoVehicleType.fuelTruck => LucideIcons.fuel,
        AutoVehicleType.combo => LucideIcons.car,
      };
}

AutoVehicleType autoVehicleTypeFromKey(String? key) {
  switch (key?.toLowerCase()) {
    case 'evakuator':
      return AutoVehicleType.evakuator;
    case 'service_van':
      return AutoVehicleType.serviceVan;
    case 'fuel_truck':
      return AutoVehicleType.fuelTruck;
    default:
      return AutoVehicleType.combo;
  }
}

/// Mobil avto-yordam birligi
class AutoMobileService {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<String> services;
  final Map<String, double> prices;
  final String? serviceArea;
  final String? autoRole;
  final AutoVehicleType vehicleType;
  final int providerId;
  final Map<String, dynamic>? rawJson;

  const AutoMobileService({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.services,
    required this.prices,
    this.serviceArea,
    this.autoRole,
    this.vehicleType = AutoVehicleType.combo,
    this.providerId = 0,
    this.rawJson,
  });

  bool get isAutoMobile => autoRole == 'mobile';

  bool offersService(String keyword) =>
      services.any((s) => s.toLowerCase().contains(keyword.toLowerCase()));

  factory AutoMobileService.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final serviceList = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final pricesRaw = meta['prices'] as Map<String, dynamic>?;
    final prices = <String, double>{};
    if (pricesRaw != null) {
      for (final entry in pricesRaw.entries) {
        prices[entry.key] = (entry.value as num).toDouble();
      }
    }
    for (final s in serviceList) {
      prices.putIfAbsent(s, () => _defaultPrice(s));
    }

    final rawId = json['id'];
    final pid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return AutoMobileService(
      id: rawId?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      services: serviceList.isNotEmpty
          ? serviceList
          : const ['Evakuator', 'Joyida ta\'mirlash', 'Benzin yetkazish (AI-92, 10L)'],
      prices: prices,
      serviceArea: meta['service_area']?.toString(),
      autoRole: meta['auto_role']?.toString(),
      vehicleType: autoVehicleTypeFromKey(meta['vehicle_type']?.toString()),
      providerId: pid,
      rawJson: json,
    );
  }

  static double _defaultPrice(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('evak')) return 250000;
    if (lower.contains('benzin')) return 120000;
    if (lower.contains('akkum')) return 80000;
    if (lower.contains('shino')) return 70000;
    if (lower.contains('ta\'mir') || lower.contains('tamir')) return 150000;
    return 100000;
  }
}
