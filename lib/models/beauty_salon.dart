class SalonStaff {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String imageUrl;

  SalonStaff({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
  });
}

class BeautySalon {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> services;
  final Map<String, double> prices;
  final List<SalonStaff> staff;

  BeautySalon({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.prices,
    required this.staff,
  });

  factory BeautySalon.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return BeautySalon(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      services: services.isNotEmpty ? services : ['Fen', 'Manikyur'],
      prices: {for (final s in services) s: 50000.0},
      staff: const [],
    );
  }

  static List<BeautySalon> demoSalons = [
    BeautySalon(
      id: "s1",
      name: "Belleza Salon",
      address: "Toshkent sh., Navoiy ko'chasi, 21",
      phoneNumber: "+998 90 444 33 22",
      rating: 4.9,
      reviewCount: 210,
      latitude: 41.3155,
      longitude: 69.2555,
      services: ["Fen", "Manikyur", "Makiyaj", "Soch bo'yash"],
      prices: {"Fen": 40000, "Manikyur": 60000, "Makiyaj": 150000, "Soch bo'yash": 200000},
      staff: [
        SalonStaff(id: "st1", name: "Malika", specialty: "Stilist", rating: 4.9, imageUrl: ""),
        SalonStaff(id: "st2", name: "Nigora", specialty: "Vizajist", rating: 4.8, imageUrl: ""),
        SalonStaff(id: "st3", name: "Zuhra", specialty: "Manikyur", rating: 5.0, imageUrl: ""),
      ],
    ),
    BeautySalon(
      id: "s2",
      name: "Glow Up Studio",
      address: "Yakkasaroy tumani, Shota Rustaveli",
      phoneNumber: "+998 93 111 22 33",
      rating: 4.7,
      reviewCount: 156,
      latitude: 41.2855,
      longitude: 69.2455,
      services: ["Fen", "Pedikyur", "Kiprik o'stirish"],
      prices: {"Fen": 35000, "Pedikyur": 80000, "Kiprik o'stirish": 120000},
      staff: [
        SalonStaff(id: "st4", name: "Diyora", specialty: "Master", rating: 4.7, imageUrl: ""),
      ],
    ),
  ];
}
