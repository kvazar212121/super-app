/// Xaridor qidiruvi uchun filtr.
///
/// Narx SO'MDA: xaridor so'mda o'ylaydi, dollarli e'lonlarni backend
/// kursga ko'ra o'zi taqqoslaydi.
library;

class ListingFilter {
  final String? query;
  final String? category;
  final double? priceMin;
  final double? priceMax;
  final String? condition;
  final double? lat;
  final double? lng;
  final double? radiusKm;

  /// relevant (yaqinlik+yangilik), price_asc, price_desc, new
  final String sort;

  const ListingFilter({
    this.query,
    this.category,
    this.priceMin,
    this.priceMax,
    this.condition,
    this.lat,
    this.lng,
    this.radiusKm,
    this.sort = 'relevant',
  });

  ListingFilter copyWith({
    String? query,
    String? category,
    double? priceMin,
    double? priceMax,
    String? condition,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sort,
  }) {
    return ListingFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      condition: condition ?? this.condition,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      sort: sort ?? this.sort,
    );
  }

  /// Bo'sh maydonlar YUBORILMAYDI — backendda ular "filtr yo'q"
  /// degani, `null` yuborilsa Dio uni `"null"` qilib jo'natardi.
  Map<String, dynamic> toQuery() {
    final map = <String, dynamic>{'sort': sort};
    if (query != null && query!.trim().isNotEmpty) map['query'] = query!.trim();
    if (category != null && category!.isNotEmpty) map['category'] = category;
    if (priceMin != null) map['price_min'] = priceMin;
    if (priceMax != null) map['price_max'] = priceMax;
    if (condition != null && condition!.isNotEmpty) {
      map['condition'] = condition;
    }
    if (lat != null && lng != null) {
      map['lat'] = lat;
      map['lng'] = lng;
      if (radiusKm != null) map['radius_km'] = radiusKm;
    }
    return map;
  }
}
