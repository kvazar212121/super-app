class SavedPlace {
  final String id;
  final String categoryKey;
  final String name;
  final String address;
  final double rating;
  final String
  type; // 'barber_shop', 'beauty_salon', 'football_field', 'massage_center', 'master'
  final Map<String, dynamic> rawJson;

  SavedPlace({
    required this.id,
    required this.categoryKey,
    required this.name,
    required this.address,
    required this.rating,
    required this.type,
    required this.rawJson,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryKey': categoryKey,
    'name': name,
    'address': address,
    'rating': rating,
    'type': type,
    'rawJson': rawJson,
  };

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    id: json['id'] ?? '',
    categoryKey: json['categoryKey'] ?? '',
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    type: json['type'] ?? '',
    rawJson: Map<String, dynamic>.from(json['rawJson'] ?? {}),
  );
}
