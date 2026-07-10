class SportFacilityAmenity {
  final String id;
  final String name;
  final String iconStr;
  final double? additionalPrice;

  const SportFacilityAmenity({
    required this.id,
    required this.name,
    required this.iconStr,
    this.additionalPrice,
  });
}

class SportFacility {
  final String id;
  final int providerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// e.g. "Tennis", "Basseyn", "Basketbol", "Voleybol", "Universal zal"
  final String sportType;

  /// e.g. "Hard", "Clay", "Yopiq", "Ochiq", "Isitiladigan"
  final String surfaceType;

  final double basePricePerHour;
  final List<SportFacilityAmenity> amenities;
  final List<String> gallery;

  const SportFacility({
    required this.id,
    required this.providerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.sportType,
    required this.surfaceType,
    required this.basePricePerHour,
    required this.amenities,
    required this.gallery,
  });
}

// Dummy Data
final mockSportFacilities = [
  SportFacility(
    id: 's1',
    providerId: 301,
    name: 'Olimpik Tennis Korti',
    address: 'Chilonzor tumani, 12-kvartal',
    latitude: 41.282,
    longitude: 69.213,
    sportType: 'Tennis',
    surfaceType: 'Hard (Yopiq)',
    basePricePerHour: 120000,
    amenities: const [
      SportFacilityAmenity(id: 'a1', name: 'Dush', iconStr: 'shower'),
      SportFacilityAmenity(
        id: 'a2',
        name: 'Raketka ijarasi',
        iconStr: 'sports_tennis',
        additionalPrice: 20000,
      ),
      SportFacilityAmenity(
        id: 'a3',
        name: 'Koptoklar',
        iconStr: 'circle',
        additionalPrice: 10000,
      ),
      SportFacilityAmenity(
        id: 'a4',
        name: 'Avtoturargoh',
        iconStr: 'local_parking',
      ),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=600&auto=format&fit=crop',
    ],
  ),
  SportFacility(
    id: 's2',
    providerId: 302,
    name: 'Aqua Blue Basseyn',
    address: 'Yunusobod tumani, 4-kvartal',
    latitude: 41.365,
    longitude: 69.288,
    sportType: 'Basseyn',
    surfaceType: 'Yopiq (Isitiladigan)',
    basePricePerHour: 80000,
    amenities: const [
      SportFacilityAmenity(id: 'a1', name: 'Dush va Sauna', iconStr: 'hot_tub'),
      SportFacilityAmenity(
        id: 'a2',
        name: 'Kiyinish xonasi',
        iconStr: 'checkroom',
      ),
      SportFacilityAmenity(id: 'a3', name: 'Kafe', iconStr: 'local_cafe'),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1576013551627-11971f36b6ab?q=80&w=600&auto=format&fit=crop',
    ],
  ),
  SportFacility(
    id: 's3',
    providerId: 303,
    name: 'Universal Sport Zali',
    address: 'Mirobod tumani, Nukus ko\'chasi',
    latitude: 41.299,
    longitude: 69.278,
    sportType: 'Basketbol/Voleybol',
    surfaceType: 'Parket (Yopiq)',
    basePricePerHour: 150000,
    amenities: const [
      SportFacilityAmenity(id: 'a1', name: 'Dush', iconStr: 'shower'),
      SportFacilityAmenity(id: 'a2', name: 'Tribuna', iconStr: 'groups'),
      SportFacilityAmenity(
        id: 'a3',
        name: 'Koptok',
        iconStr: 'sports_basketball',
      ),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=600&auto=format&fit=crop',
    ],
  ),
];
