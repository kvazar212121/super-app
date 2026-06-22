class DentalDentist {
  final String name;
  final String specialty;

  const DentalDentist({required this.name, this.specialty = 'Stomatolog'});
}

/// Stomatologiya klinikasi
class DentalClinic {
  final String id;
  final int providerId;
  final String name;
  final String address;
  final String phoneNumber;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> services;
  final Map<String, double> prices;
  final List<DentalDentist> dentists;
  final List<String> timeSlots;
  final Map<String, dynamic>? rawJson;

  const DentalClinic({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.rating,
    this.reviewCount = 0,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.prices,
    this.dentists = const [],
    this.timeSlots = const [],
    this.rawJson,
  });

  factory DentalClinic.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0),
    );

    final dentistsRaw = meta['dentists'] as List<dynamic>? ?? [];
    final dentists = dentistsRaw.map((d) {
      final m = d as Map<String, dynamic>? ?? {};
      return DentalDentist(
        name: m['name']?.toString() ?? 'Shifokor',
        specialty: m['specialty']?.toString() ?? 'Stomatolog',
      );
    }).toList();

    return DentalClinic(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phoneNumber: json['phone']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      services: services.isNotEmpty
          ? services
          : ['Ko\'rik va maslahat', 'Professional tozalash', 'Plomba'],
      prices: prices.isNotEmpty
          ? prices
          : {
              'Ko\'rik va maslahat': 80000,
              'Professional tozalash': 150000,
            },
      dentists: dentists,
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rawJson: json,
    );
  }
}
