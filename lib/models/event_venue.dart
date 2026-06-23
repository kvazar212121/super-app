class EventVenueAmenity {
  final String id;
  final String name;
  final String iconStr;
  final double? additionalPrice;

  const EventVenueAmenity({
    required this.id,
    required this.name,
    required this.iconStr,
    this.additionalPrice,
  });
}

class EventVenue {
  final String id;
  final int providerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// e.g. "Restoran", "To'yxona", "Hovli", "Ochiq maydon", "Konferens zal"
  final String venueType; 
  
  final int maxGuests;
  final double basePrice; // starting price or rental price
  final List<EventVenueAmenity> amenities;
  final List<String> gallery;

  const EventVenue({
    required this.id,
    required this.providerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.venueType,
    required this.maxGuests,
    required this.basePrice,
    required this.amenities,
    required this.gallery,
  });
}

// Dummy Data
final mockEventVenues = [
  EventVenue(
    id: 'ev1',
    providerId: 501,
    name: 'Yakkasaroy To\'yxonasi',
    address: 'Yakkasaroy tumani, Shota Rustaveli',
    latitude: 41.282,
    longitude: 69.253,
    venueType: 'To\'yxona',
    maxGuests: 600,
    basePrice: 5000000,
    amenities: const [
      EventVenueAmenity(id: 'a1', name: 'Katta avtoturargoh', iconStr: 'local_parking'),
      EventVenueAmenity(id: 'a2', name: 'Markaziy konditsioner', iconStr: 'ac_unit'),
      EventVenueAmenity(id: 'a3', name: 'VIP stol', iconStr: 'star', additionalPrice: 500000),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=600&auto=format&fit=crop',
    ],
  ),
  EventVenue(
    id: 'ev2',
    providerId: 502,
    name: 'Zomin Ochiq Maydoni',
    address: 'Zomin tog\'lari, Jizzax',
    latitude: 39.95,
    longitude: 68.46,
    venueType: 'Ochiq maydon (Tabiat)',
    maxGuests: 200,
    basePrice: 1500000,
    amenities: const [
      EventVenueAmenity(id: 'a1', name: 'O\'t o\'chirish joyi (Gulxan)', iconStr: 'local_fire_department'),
      EventVenueAmenity(id: 'a2', name: 'Elektr toki (Generator)', iconStr: 'electrical_services', additionalPrice: 300000),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?q=80&w=600&auto=format&fit=crop',
    ],
  ),
  EventVenue(
    id: 'ev3',
    providerId: 503,
    name: 'Hilton Konferens Zali',
    address: 'Tashkent City',
    latitude: 41.314,
    longitude: 69.255,
    venueType: 'Konferens zal',
    maxGuests: 150,
    basePrice: 10000000,
    amenities: const [
      EventVenueAmenity(id: 'a1', name: 'Proyektor va LED ekran', iconStr: 'tv'),
      EventVenueAmenity(id: 'a2', name: 'Sinxron tarjima uskunalari', iconStr: 'headphones', additionalPrice: 2000000),
      EventVenueAmenity(id: 'a3', name: 'Kofe-breyk xizmati', iconStr: 'local_cafe', additionalPrice: 1500000),
    ],
    gallery: [
      'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=600&auto=format&fit=crop',
    ],
  ),
];
