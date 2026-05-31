class Barber {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final List<String> specializations;

  Barber({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.specializations,
  });
}

class BarberShop {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> services;
  final Map<String, double> prices;
  final List<Barber> barbers; // Added barbers list

  BarberShop({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.services,
    required this.prices,
    required this.barbers,
  });

  factory BarberShop.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final barbersRaw = meta['barbers'] as List<dynamic>? ?? [];
    return BarberShop(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      images: const [],
      services: services.isNotEmpty ? services : ['Erkaklar kesimi', 'Soqol olish'],
      prices: {for (final s in services) s: 50000.0},
      barbers: barbersRaw.map((b) {
        final m = b as Map<String, dynamic>;
        return Barber(
          id: m['name'] ?? '',
          name: m['name'] ?? '',
          imageUrl: '',
          rating: (m['rating'] as num?)?.toDouble() ?? 4.5,
          specializations: services,
        );
      }).toList(),
    );
  }

}
