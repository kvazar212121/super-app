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

}
