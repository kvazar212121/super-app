class Master {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final List<String> services;
  final Map<String, double> prices;

  Master({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.services,
    required this.prices,
  });

  factory Master.fromProviderJson(Map<String, dynamic> json, [String? defaultSpecialty]) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final specialty = meta['specialty'] as String? ?? defaultSpecialty ?? 'Usta';
    return Master(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      specialty: specialty,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      phoneNumber: json['phone'] ?? '',
      services: services.isNotEmpty ? services : [specialty],
      prices: {for (final s in (services.isNotEmpty ? services : [specialty])) s: 100000.0},
    );
  }

}

class Worker {
  final String id;
  final String name;
  final String type; // e.g. "Mardikor", "Yuk tashuvchi"
  final double rating;
  final double latitude;
  final double longitude;
  final String phoneNumber;

  Worker({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
  });

  factory Worker.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    return Worker(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: meta['worker_type'] as String? ?? 'Ishchi',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      phoneNumber: json['phone'] ?? '',
    );
  }

}
