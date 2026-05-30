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

  static List<AutoWorkshop> demoWorkshops = [
    AutoWorkshop(
      id: "aw1",
      name: "Grand Auto Service",
      address: "Toshkent sh., Yunusobod, 19-kvartal",
      latitude: 41.3500,
      longitude: 69.2900,
      rating: 4.8,
      phoneNumber: "+998 71 200 00 01",
      specializations: ["Motor", "Xodovoy", "Yog' almashtirish"],
    ),
    AutoWorkshop(
      id: "aw2",
      name: "Express Tuning",
      address: "Sergeli moshina bozori yaqinida",
      latitude: 41.2200,
      longitude: 69.2000,
      rating: 4.6,
      phoneNumber: "+998 90 123 45 67",
      specializations: ["Elektronika", "Tuning", "Diagnostika"],
    ),
  ];
}
