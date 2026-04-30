class BarberShop {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> services;
  final Map<String, double> prices;

  BarberShop({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.services,
    required this.prices,
  });

  static List<BarberShop> demoShops = [
    BarberShop(
      id: "1",
      name: "Style Barbershop",
      address: "Amir Temur ko'chasi, 15",
      rating: 4.8,
      reviewCount: 124,
      latitude: 41.3115,
      longitude: 69.2495,
      images: ["shop1.jpg"],
      services: ["Erkaklar kesimi", "Soqol olish", "Bolalar kesimi"],
      prices: {"Erkaklar kesimi": 50000, "Soqol olish": 20000, "Bolalar kesimi": 35000},
    ),
    BarberShop(
      id: "2",
      name: "Premium Cut",
      address: "Chilonzor tumani, 5-mavze",
      rating: 4.9,
      reviewCount: 89,
      latitude: 41.2995,
      longitude: 69.2205,
      images: ["shop2.jpg"],
      services: ["Erkaklar kesimi", "Soqol olish", "Styling"],
      prices: {"Erkaklar kesimi": 70000, "Soqol olish": 25000, "Styling": 30000},
    ),
    BarberShop(
      id: "3",
      name: "Classic Barber",
      address: "Yunusobod tumani, Katta Halqa yo'li",
      rating: 4.6,
      reviewCount: 56,
      latitude: 41.3355,
      longitude: 69.2675,
      images: ["shop3.jpg"],
      services: ["Erkaklar kesimi", "Soqol olish"],
      prices: {"Erkaklar kesimi": 45000, "Soqol olish": 15000},
    ),
  ];
}

class BarberBooking {
  final String id;
  final String shopId;
  final String serviceName;
  final DateTime dateTime;
  final double price;
  final String status;

  BarberBooking({
    required this.id,
    required this.shopId,
    required this.serviceName,
    required this.dateTime,
    required this.price,
    this.status = "pending",
  });
}
