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

  static List<BarberShop> demoShops = [
    BarberShop(
      id: "1",
      name: "Style Barbershop",
      address: "Amir Temur ko'chasi, 15",
      phoneNumber: "+998 90 123 45 67",
      rating: 4.8,
      reviewCount: 124,
      latitude: 41.3115,
      longitude: 69.2495,
      images: ["shop1.jpg"],
      services: ["Erkaklar kesimi", "Soqol olish", "Bolalar kesimi"],
      prices: {"Erkaklar kesimi": 50000, "Soqol olish": 20000, "Bolalar kesimi": 35000},
      barbers: [
        Barber(id: "b1", name: "Aziz", imageUrl: "assets/barber1.jpg", rating: 4.9, specializations: ["Erkaklar kesimi"]),
        Barber(id: "b2", name: "Jahongir", imageUrl: "assets/barber2.jpg", rating: 4.7, specializations: ["Soqol", "Styling"]),
        Barber(id: "b3", name: "Timur", imageUrl: "assets/barber3.jpg", rating: 4.8, specializations: ["Bolalar kesimi"]),
      ],
    ),
    BarberShop(
      id: "2",
      name: "Premium Cut",
      address: "Chilonzor tumani, 5-mavze",
      phoneNumber: "+998 93 987 65 43",
      rating: 4.9,
      reviewCount: 89,
      latitude: 41.2995,
      longitude: 69.2205,
      images: ["shop2.jpg"],
      services: ["Erkaklar kesimi", "Soqol olish", "Styling"],
      prices: {"Erkaklar kesimi": 70000, "Soqol olish": 25000, "Styling": 30000},
      barbers: [
        Barber(id: "b4", name: "Sardor", imageUrl: "assets/barber4.jpg", rating: 5.0, specializations: ["Vip kesim"]),
        Barber(id: "b5", name: "Doston", imageUrl: "assets/barber5.jpg", rating: 4.8, specializations: ["Klassika"]),
      ],
    ),
    BarberShop(
      id: "3",
      name: "Classic Barber",
      address: "Yunusobod tumani, Katta Halqa yo'li",
      phoneNumber: "+998 94 555 44 33",
      rating: 4.6,
      reviewCount: 56,
      latitude: 41.3355,
      longitude: 69.2675,
      images: ["shop3.jpg"],
      services: ["Erkaklar kesimi", "Soqol olish"],
      prices: {"Erkaklar kesimi": 45000, "Soqol olish": 15000},
      barbers: [
        Barber(id: "b6", name: "Rustam", imageUrl: "assets/barber6.jpg", rating: 4.6, specializations: ["Usta"]),
      ],
    ),
  ];
}
