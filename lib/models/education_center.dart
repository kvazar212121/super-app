class EducationCenter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final List<String> courses; // e.g. "IELTS", "Matematika", "Programmalash"
  final String phoneNumber;

  EducationCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.courses,
    required this.phoneNumber,
  });

  factory EducationCenter.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final courses = (meta['courses'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return EducationCenter(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      courses: courses.isNotEmpty ? courses : ['Kurslar'],
      phoneNumber: json['phone'] ?? '',
    );
  }

  static List<EducationCenter> demoCenters = [
    EducationCenter(
      id: "ec1",
      name: "Najot Ta'lim",
      address: "Toshkent, Chilonzor 9-kvartal",
      latitude: 41.2850,
      longitude: 69.2050,
      rating: 4.9,
      courses: ["Programmalash", "Grafik Dizayn", "Marketing"],
      phoneNumber: "+998 71 200 69 06",
    ),
    EducationCenter(
      id: "ec2",
      name: "Cambridge Learning Center",
      address: "Toshkent, Abdulla Qodiriy ko'chasi",
      latitude: 41.3250,
      longitude: 69.2850,
      rating: 4.7,
      courses: ["IELTS", "General English", "Kids English"],
      phoneNumber: "+998 71 200 11 22",
    ),
  ];
}
