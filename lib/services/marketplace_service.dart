/// Savdo bo'limi uchun API chaqiruvlari.
///
/// Ekranlar va widgetlar to'g'ridan-to'g'ri `ApiService` ga
/// murojaat qilmaydi: shu yerda JSON -> model aylantiriladi va
/// testlarda almashtirish nuqtasi bor.
library;

import '../models/marketplace/listing.dart';
import '../models/marketplace/listing_filter.dart';
import 'api_service.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._();
  factory MarketplaceService() => _instance;
  MarketplaceService._();

  final _api = ApiService();

  /// TESTLAR uchun: haqiqiy tarmoq so'rovini almashtirish nuqtasi.
  Future<List<Listing>> Function(ListingFilter filter)? debugSearchOverride;

  Future<List<Listing>> search(ListingFilter filter) async {
    final override = debugSearchOverride;
    if (override != null) return override(filter);
    final raw = await _api.searchListings(filter.toQuery());
    return raw
        .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Listing> byId(int id) async {
    return Listing.fromJson(await _api.getListing(id));
  }

  /// «Mening e'lonlarim» va uzaytirish shartlari (narx, kun, premiummi).
  Future<({List<Listing> items, Map<String, dynamic> extend})>
  myListings() async {
    final data = await _api.getMyListings();
    final items = ((data['listings'] as List?) ?? const [])
        .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (
      items: items,
      extend: Map<String, dynamic>.from((data['extend'] as Map?) ?? const {}),
    );
  }

  Future<String> uploadPhoto(String path) => _api.uploadListingPhoto(path);

  Future<Listing> markSold(int id) async =>
      Listing.fromJson(await _api.listingAction(id, 'sold'));

  Future<Listing> hide(int id) async =>
      Listing.fromJson(await _api.listingAction(id, 'hide'));

  Future<Listing> reopen(int id) async =>
      Listing.fromJson(await _api.listingAction(id, 'reopen'));

  /// Muddatni uzaytirish. Premium bepul, boshqasi balansdan yechiladi.
  Future<Listing> extend(int id) async =>
      Listing.fromJson(await _api.listingAction(id, 'extend'));

  Future<void> report(int id, String reason) => _api.reportListing(id, reason);
}
