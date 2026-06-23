class GameZoneAmenity {
  final String id;
  final String name;
  final String iconStr;
  final double? additionalPrice;

  const GameZoneAmenity({
    required this.id,
    required this.name,
    required this.iconStr,
    this.additionalPrice,
  });
}

class GameZone {
  final String id;
  final int providerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// e.g. "PS5 Klub", "PC Arena", "VR Zona"
  final String zoneType; 
  
  /// e.g. "VIP Xona", "Umumiy zal"
  final String roomType; 
  
  final double basePricePerHour;
  final List<GameZoneAmenity> amenities;
  final List<String> gallery;

  const GameZone({
    required this.id,
    required this.providerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.zoneType,
    required this.roomType,
    required this.basePricePerHour,
    required this.amenities,
    required this.gallery,
  });
}

// Dummy Data
final mockGameZones = [
  GameZone(
    id: 'g1',
    providerId: 401,
    name: 'Cyber Arena PC Club',
    address: 'Yunusobod tumani, Mega Planet yonida',
    latitude: 41.365,
    longitude: 69.288,
    zoneType: 'PC Arena',
    roomType: 'Umumiy zal (RTX 4070)',
    basePricePerHour: 20000,
    amenities: const [
      GameZoneAmenity(id: 'a1', name: 'Bar / Kafe', iconStr: 'local_cafe'),
      GameZoneAmenity(id: 'a2', name: 'VIP xona', iconStr: 'meeting_room', additionalPrice: 15000),
      GameZoneAmenity(id: 'a3', name: 'Energy drinks', iconStr: 'sports_bar'),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600&auto=format&fit=crop',
    ],
  ),
  GameZone(
    id: 'g2',
    providerId: 402,
    name: 'NextGen PS5 Lounge',
    address: 'Chilonzor tumani, Oqtepa do\'irasi',
    latitude: 41.282,
    longitude: 69.213,
    zoneType: 'PS5 Klub',
    roomType: 'Alohida VIP kabina',
    basePricePerHour: 30000,
    amenities: const [
      GameZoneAmenity(id: 'a1', name: '4K TV (85 inch)', iconStr: 'tv'),
      GameZoneAmenity(id: 'a2', name: 'Ovqat buyurtma', iconStr: 'fastfood'),
      GameZoneAmenity(id: 'a3', name: '4 ta Djoystik', iconStr: 'gamepad', additionalPrice: 10000),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1605901309584-818e25960b8f?q=80&w=600&auto=format&fit=crop',
    ],
  ),
  GameZone(
    id: 'g3',
    providerId: 403,
    name: 'Matrix VR Zone',
    address: 'Mirobod tumani, Makro markazi',
    latitude: 41.299,
    longitude: 69.278,
    zoneType: 'VR Zona',
    roomType: 'Virtual Reallik xonasi',
    basePricePerHour: 50000,
    amenities: const [
      GameZoneAmenity(id: 'a1', name: 'Oculus Quest 3', iconStr: 'visibility'),
      GameZoneAmenity(id: 'a2', name: 'Qo\'shimcha vaqt (30 min)', iconStr: 'timer', additionalPrice: 20000),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1622979135225-d2ba269cf1ac?q=80&w=600&auto=format&fit=crop',
    ],
  ),
];
