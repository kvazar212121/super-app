/// Savdo (marketplace) modellari — buyum e'lonlari.
///
/// Backend: /api/v1/marketplace/*
///
/// DIQQAT: bu modelda sotuvchining TELEFON RAQAMI yo'q va bo'lmaydi
/// ham — backend uni umuman yubormaydi. Aloqa faqat ilova ichida.
library;

enum ListingStatus { active, sold, expired, hidden, unknown }

ListingStatus listingStatusFrom(String? raw) {
  switch (raw) {
    case 'active':
      return ListingStatus.active;
    case 'sold':
      return ListingStatus.sold;
    case 'expired':
      return ListingStatus.expired;
    case 'hidden':
      return ListingStatus.hidden;
    default:
      return ListingStatus.unknown;
  }
}

String listingStatusLabel(ListingStatus s) {
  switch (s) {
    case ListingStatus.active:
      return 'Faol';
    case ListingStatus.sold:
      return 'Sotildi';
    case ListingStatus.expired:
      return 'Muddati tugagan';
    case ListingStatus.hidden:
      return 'Yashirilgan';
    case ListingStatus.unknown:
      return '—';
  }
}

/// Buyum holati — xaridor uchun eng muhim ma'lumotlardan biri.
String conditionLabel(String? raw) {
  switch (raw) {
    case 'new':
      return 'Yangi';
    case 'like_new':
      return 'Ideal';
    case 'good':
      return 'Yaxshi';
    case 'used':
      return 'Ishlatilgan';
    case 'parts':
      return 'Ehtiyot qismga';
    default:
      return '—';
  }
}

class Listing {
  final int id;
  final int userId;
  final String categoryKey;
  final String title;
  final String description;

  /// Sotuvchi kiritgan narx va valyuta (UZS yoki USD).
  final double? price;
  final String currency;

  /// Xaridorga KO'RSATILADIGAN narx — doim so'mda (backend hisoblaydi).
  final double? priceUzs;
  final bool isNegotiable;

  final String? condition;
  final Map<String, dynamic> attributes;
  final String address;
  final double? lat;
  final double? lng;
  final ListingStatus status;
  final int views;
  final List<String> photos;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// Xaridordan qancha uzoqda (km). Koordinata bo'lgandagina keladi.
  final double? distanceKm;

  const Listing({
    required this.id,
    required this.userId,
    required this.categoryKey,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.priceUzs,
    required this.isNegotiable,
    required this.condition,
    required this.attributes,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.views,
    required this.photos,
    required this.expiresAt,
    required this.createdAt,
    required this.distanceKm,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      categoryKey: json['category_key'] as String? ?? 'boshqa',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'UZS',
      priceUzs: (json['price_uzs'] as num?)?.toDouble(),
      isNegotiable: json['is_negotiable'] == true,
      condition: json['condition'] as String?,
      attributes: Map<String, dynamic>.from(
        (json['attributes'] as Map?) ?? const {},
      ),
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      status: listingStatusFrom(json['status'] as String?),
      views: (json['views'] as num?)?.toInt() ?? 0,
      photos: ((json['photos'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      expiresAt: _date(json['expires_at']),
      createdAt: _date(json['created_at']),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  static DateTime? _date(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  /// Kartada ko'rinadigan asosiy rasm (birinchisi).
  String? get mainPhoto => photos.isEmpty ? null : photos.first;

  /// Narx matni — DOIM so'mda. Dollarli e'lon bo'lsa asli qavsda.
  String get priceText {
    if (isNegotiable || priceUzs == null) return 'Kelishamiz';
    final asosiy = '${_thousands(priceUzs!)} so\'m';
    if (currency == 'USD' && price != null) {
      return '$asosiy (${_thousands(price!)} \$)';
    }
    return asosiy;
  }

  String get conditionText => conditionLabel(condition);

  String get distanceText =>
      distanceKm == null ? '' : '${distanceKm!.toStringAsFixed(1)} km';

  /// Muddat tugashiga qolgan kun. Tugagan bo'lsa 0.
  int get daysLeft {
    if (expiresAt == null) return 0;
    final qolgan = expiresAt!.difference(DateTime.now()).inDays;
    return qolgan < 0 ? 0 : qolgan;
  }

  bool get isExpired =>
      status == ListingStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));

  static String _thousands(double value) {
    final butun = value.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < butun.length; i++) {
      if (i > 0 && (butun.length - i) % 3 == 0) buf.write(' ');
      buf.write(butun[i]);
    }
    return buf.toString();
  }
}
