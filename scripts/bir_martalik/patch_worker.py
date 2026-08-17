import sys

with open('lib/models/master_worker.dart', 'r') as f:
    content = f.read()

old_worker = """class Worker {
  final String id;
  final String name;
  final String type;
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
}"""

new_worker = """class Worker {
  final String id;
  final String name;
  final String type;
  final double rating;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final int providerId;
  final int? age;
  final int? experienceYears;
  final List<String> skills;
  final double? price;

  Worker({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    this.providerId = 0,
    this.age,
    this.experienceYears,
    this.skills = const [],
    this.price,
  });

  factory Worker.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final rawId = json['id'];
    final pid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    
    final skillsRaw = meta['skills'];
    final skillsList = skillsRaw is List ? skillsRaw.map((e) => e.toString()).toList() : <String>[];
    
    return Worker(
      id: rawId?.toString() ?? '',
      name: json['name'] ?? '',
      type: meta['worker_type'] as String? ?? 'Ishchi',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      phoneNumber: json['phone'] ?? '',
      providerId: pid,
      age: int.tryParse(meta['age']?.toString() ?? ''),
      experienceYears: int.tryParse(meta['experience_years']?.toString() ?? ''),
      skills: skillsList,
      price: (meta['price'] as num?)?.toDouble(),
    );
  }
}"""

content = content.replace(old_worker, new_worker)

with open('lib/models/master_worker.dart', 'w') as f:
    f.write(content)
