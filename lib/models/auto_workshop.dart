class AutoWorkshop {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String phoneNumber;
  final List<String> specializations; // e.g. "Xodovoy", "Motor", "Elektronika"
  final bool isOpen;

  AutoWorkshop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.phoneNumber,
    required this.specializations,
    this.isOpen = true,
  });

  factory AutoWorkshop.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final specs = (meta['specializations'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return AutoWorkshop(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      phoneNumber: json['phone'] ?? '',
      specializations: specs.isNotEmpty ? specs : ['Motor', 'Diagnostika'],
    );
  }

}
