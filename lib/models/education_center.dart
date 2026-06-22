class EducationCenter {
  final String id;
  final int providerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final List<String> courses;
  final String phoneNumber;
  final List<String> services;
  final Map<String, double> prices;
  final List<String> timeSlots;
  final Map<String, dynamic>? rawJson;

  EducationCenter({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    this.reviewCount = 0,
    required this.courses,
    required this.phoneNumber,
    this.services = const [],
    this.prices = const {},
    this.timeSlots = const [],
    this.rawJson,
  });

  factory EducationCenter.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final courses = (meta['courses'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0),
    );

    return EducationCenter(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      courses: courses.isNotEmpty ? courses : ['Kurslar'],
      phoneNumber: json['phone'] ?? '',
      services: services,
      prices: prices,
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rawJson: json,
    );
  }
}
