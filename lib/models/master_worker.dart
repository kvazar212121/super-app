import '../utils/geo_utils.dart';

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
  final int providerId;
  final String? serviceArea;
  final String address;
  final bool isHomeVisit;
  final String? cleanerRole;
  final String? masterRole;
  final String? electricianRole;
  final String? plumberRole;
  final String? acRole;
  final int? teamSize;
  final String? subCategory;
  final String? about;
  final Map<String, dynamic>? rawJson;
  final bool isTravelFeeIncluded;
  final double travelFee;
  final int ownerUserId;

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
    this.providerId = 0,
    this.serviceArea,
    this.address = '',
    this.isHomeVisit = false,
    this.cleanerRole,
    this.masterRole,
    this.electricianRole,
    this.plumberRole,
    this.acRole,
    this.teamSize,
    this.subCategory,
    this.about,
    this.rawJson,
    this.isTravelFeeIncluded = true,
    this.travelFee = 0.0,
    this.ownerUserId = 0,
  });

  bool get isAcSolo => acRole == 'solo';
  bool get isAcTechnician =>
      acRole != null || specialty.toLowerCase().contains('kond');
  bool get isPlumberSolo => plumberRole == 'solo';
  bool get isPlumber =>
      plumberRole != null || specialty.toLowerCase().contains('sant');
  bool get isElectricianSolo => electricianRole == 'solo';
  bool get isElectrician =>
      electricianRole != null || specialty.toLowerCase().contains('elek');
  bool get isCleaningSolo => cleanerRole == 'solo';
  bool get isCleaningTeam => cleanerRole == 'team';
  bool get isCleaner =>
      cleanerRole != null || specialty.toLowerCase().contains('toza');
  bool get isMasterSolo => masterRole == 'solo';
  bool get isMasterBrigade => masterRole == 'brigade';
  bool get isDispatchMaster => masterRole != null;

  String get locationLabel {
    if (address.isNotEmpty) return address;
    if (serviceArea != null && serviceArea!.isNotEmpty) return serviceArea!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  double distanceKmFrom(double userLat, double userLng) =>
      distanceKm(userLat, userLng, latitude, longitude);

  factory Master.fromProviderJson(
    Map<String, dynamic> json, [
    String? defaultSpecialty,
  ]) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final role = meta['barber_role']?.toString();
    final salonRole = meta['salon_role']?.toString();
    final cleanerRole = meta['cleaner_role']?.toString();
    final masterRole = meta['master_role']?.toString();
    final electricianRole = meta['electrician_role']?.toString();
    final plumberRole = meta['plumber_role']?.toString();
    final acRole = meta['ac_role']?.toString();
    final isMobile =
        role == 'mobile' || salonRole == 'mobile' || meta['is_mobile'] == true;
    final isCleaner =
        cleanerRole != null ||
        (defaultSpecialty?.toLowerCase().contains('toza') ?? false) ||
        (meta['specialty'] as String? ?? '').toLowerCase().contains('toza');
    final isElectrician =
        electricianRole != null ||
        (defaultSpecialty?.toLowerCase().contains('elek') ?? false) ||
        (meta['specialty'] as String? ?? '').toLowerCase().contains('elek');
    final isPlumber =
        plumberRole != null ||
        (defaultSpecialty?.toLowerCase().contains('sant') ?? false) ||
        (meta['specialty'] as String? ?? '').toLowerCase().contains('sant');
    final isAc =
        acRole != null ||
        (defaultSpecialty?.toLowerCase().contains('kond') ?? false) ||
        (meta['specialty'] as String? ?? '').toLowerCase().contains('kond');

    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final specialty = isMobile && salonRole == 'mobile'
        ? 'Mobil kosmetolog'
        : isMobile
        ? 'Mobil sartarosh'
        : cleanerRole == 'solo'
        ? 'Yakka tozalovchi'
        : cleanerRole == 'team'
        ? 'Tozalash jamoasi'
        : masterRole == 'solo'
        ? 'Yakka usta'
        : masterRole == 'brigade'
        ? 'Ustalar brigadasi'
        : electricianRole == 'solo'
        ? 'Elektrik'
        : plumberRole == 'solo'
        ? 'Santexnik'
        : acRole == 'solo'
        ? 'Konditsioner'
        : (meta['specialty'] as String? ?? defaultSpecialty ?? 'Usta');

    final serviceList = services.isNotEmpty ? services : [specialty];

    final pricesRaw = meta['prices'] as Map<String, dynamic>?;
    final prices = <String, double>{};
    if (pricesRaw != null) {
      for (final entry in pricesRaw.entries) {
        prices[entry.key] = (entry.value as num).toDouble();
      }
    }
    for (final s in serviceList) {
      prices.putIfAbsent(
        s,
        () => _defaultPrice(
          s,
          isMobile,
          isCleaner,
          isElectrician,
          isPlumber,
          isAc,
        ),
      );
    }

    final rawId = json['id'];
    final pid = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final teamSizeRaw = meta['team_size'];
    final teamSize = teamSizeRaw is int
        ? teamSizeRaw
        : int.tryParse(teamSizeRaw?.toString() ?? '');

    return Master(
      id: rawId?.toString() ?? '',
      name: json['name'] ?? '',
      specialty: specialty,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      phoneNumber: json['phone'] ?? '',
      services: serviceList,
      prices: prices,
      providerId: pid,
      serviceArea: meta['service_area']?.toString(),
      address: json['address']?.toString() ?? '',
      isHomeVisit:
          isMobile ||
          isCleaner ||
          masterRole != null ||
          electricianRole != null ||
          plumberRole != null ||
          acRole != null,
      cleanerRole: cleanerRole,
      masterRole: masterRole,
      electricianRole: electricianRole,
      plumberRole: plumberRole,
      acRole: acRole,
      teamSize: teamSize,
      subCategory: meta['sub_category']?.toString(),
      about:
          meta['about']?.toString() ??
          meta['bio']?.toString() ??
          meta['description']?.toString(),
      rawJson: json,
      isTravelFeeIncluded: meta['is_travel_fee_included'] as bool? ?? true,
      travelFee: (meta['travel_fee'] as num?)?.toDouble() ?? 0.0,
      ownerUserId: (json['owner_user_id'] as num?)?.toInt() ?? 0,
    );
  }

  static double _defaultPrice(
    String service,
    bool isMobile,
    bool isCleaner,
    bool isElectrician,
    bool isPlumber,
    bool isAc,
  ) {
    final lower = service.toLowerCase();
    if (isElectrician) {
      if (lower.contains('shoshil')) return 200000;
      if (lower.contains('sim')) return 250000;
      if (lower.contains('rozet') || lower.contains('lyust')) return 100000;
      if (lower.contains('tekshir')) return 180000;
      return 120000;
    }
    if (isPlumber) {
      if (lower.contains('shoshil')) return 250000;
      if (lower.contains('smesitel') || lower.contains('kran')) return 120000;
      if (lower.contains('toshma') || lower.contains('probka')) return 150000;
      if (lower.contains('quvur')) return 200000;
      return 120000;
    }
    if (isAc) {
      if (lower.contains('montaj')) return 600000;
      if (lower.contains('demontaj')) return 250000;
      if (lower.contains('profil') || lower.contains('tozal')) return 180000;
      if (lower.contains('gaz') ||
          lower.contains('freon') ||
          lower.contains('toldir')) {
        return 350000;
      }
      return 200000;
    }
    if (isCleaner) {
      if (lower.contains('1 xonali')) return 200000;
      if (lower.contains('2 xonali')) return 320000;
      if (lower.contains('3 xonali')) return 450000;
      if (lower.contains('ofis')) return 400000;
      if (lower.contains('general')) return 350000;
      return 250000;
    }
    if (isMobile) {
      if (lower.contains('soqol')) return 20000;
      return 35000;
    }
    if (lower.contains('kran')) return 80000;
    if (lower.contains('quvur')) return 120000;
    return 100000;
  }
}

class Worker {
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
  final String? subCategory;
  final int ownerUserId;

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
    this.subCategory,
    this.ownerUserId = 0,
  });

  factory Worker.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final rawId = json['id'];
    final pid = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final skillsRaw = meta['skills'];
    final skillsList = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];

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
      subCategory: meta['sub_category']?.toString(),
      ownerUserId: (json['owner_user_id'] as num?)?.toInt() ?? 0,
    );
  }
}
