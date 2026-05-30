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

  static List<Master> demoMasters = [
    Master(
      id: "m1",
      name: "Usta Ali",
      specialty: "Santexnik",
      rating: 4.9,
      reviewCount: 45,
      latitude: 41.3215,
      longitude: 69.2595,
      phoneNumber: "+998 90 333 22 11",
      services: ["Kran tuzatish", "Quvur almashtirish", "Kanalizatsiya tozalash"],
      prices: {"Kran tuzatish": 50000, "Quvur almashtirish": 120000, "Kanalizatsiya tozalash": 80000},
    ),
    Master(
      id: "m2",
      name: "Usta Vali",
      specialty: "Elektrik",
      rating: 4.7,
      reviewCount: 32,
      latitude: 41.3055,
      longitude: 69.2305,
      phoneNumber: "+998 91 111 22 33",
      services: ["Rozetka o'rnatish", "Lyustra osish", "Sim almashtirish"],
      prices: {"Rozetka o'rnatish": 30000, "Lyustra osish": 60000, "Sim almashtirish": 150000},
    ),
    Master(
      id: "m3",
      name: "Gulnora",
      specialty: "Tozalash",
      rating: 4.8,
      reviewCount: 56,
      latitude: 41.3300,
      longitude: 69.2700,
      phoneNumber: "+998 93 555 44 33",
      services: ["Xonadon tozalash", "Oyna yuvish", "Kimyoviy tozalash"],
      prices: {"Xonadon tozalash": 200000, "Oyna yuvish": 50000, "Kimyoviy tozalash": 150000},
    ),
    Master(
      id: "m4",
      name: "Auto-SOS Jamoasi",
      specialty: "Avto-yordam",
      rating: 4.9,
      reviewCount: 128,
      latitude: 41.2900,
      longitude: 69.2100,
      phoneNumber: "+998 99 777 88 99",
      services: ["Evakuator", "Motor ta'mirlash", "Benzin yetkazish", "Akkumulyator"],
      prices: {"Evakuator": 150000, "Motor ta'mirlash": 100000, "Benzin yetkazish": 30000, "Akkumulyator": 50000},
    ),
    Master(
      id: "m5",
      name: "Tezkor Benzin",
      specialty: "Avto-yordam",
      rating: 4.7,
      reviewCount: 89,
      latitude: 41.3100,
      longitude: 69.2800,
      phoneNumber: "+998 97 111 44 55",
      services: ["Benzin yetkazish (AI-92)", "Benzin yetkazish (AI-95)"],
      prices: {"Benzin yetkazish (AI-92)": 20000, "Benzin yetkazish (AI-95)": 25000},
    ),
    Master(
      id: "m6",
      name: "Akmal Konditsioner",
      specialty: "Konditsioner",
      rating: 4.8,
      reviewCount: 42,
      latitude: 41.3400,
      longitude: 69.2500,
      phoneNumber: "+998 90 222 33 44",
      services: ["Montaj", "Demontaj", "Profilaktika", "Gaz quyish"],
      prices: {"Montaj": 300000, "Demontaj": 150000, "Profilaktika": 100000, "Gaz quyish": 200000},
    ),
    Master(
      id: "e1",
      name: "Zuhra opa",
      specialty: "Enaga",
      rating: 5.0,
      reviewCount: 84,
      latitude: 41.3150,
      longitude: 69.2650,
      phoneNumber: "+998 90 444 55 66",
      services: ["Soatbay qarash", "Kechki qarash", "Yarim kun", "To'liq kun"],
      prices: {"Soatbay qarash": 40000, "Kechki qarash": 50000, "Yarim kun": 150000, "To'liq kun": 250000},
    ),
    Master(
      id: "r1",
      name: "Jasur Tutor",
      specialty: "Repetitor",
      rating: 4.9,
      reviewCount: 38,
      latitude: 41.3000,
      longitude: 69.2400,
      phoneNumber: "+998 90 888 77 66",
      services: ["Matematika", "Fizika", "Imtihonga tayyorlov"],
      prices: {"Matematika": 80000, "Fizika": 80000, "Imtihonga tayyorlov": 120000},
    ),
  ];
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

  static List<Worker> demoWorkers = [
    Worker(id: "w1", name: "Eshmat", type: "Yuk tashuvchi", rating: 4.5, latitude: 41.3150, longitude: 69.2450, phoneNumber: "+998 90 000 00 01"),
    Worker(id: "w2", name: "Toshmat", type: "Yordamchi ishchi", rating: 4.2, latitude: 41.3100, longitude: 69.2550, phoneNumber: "+998 90 000 00 02"),
  ];
}
