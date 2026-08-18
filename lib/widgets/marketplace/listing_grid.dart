/// Chatdagi e'lonlar GRIDI — 2 ustun, 20 tagacha karta.
///
/// Foydalanuvchi aniq so'radi: qidiruv natijasi chatда vertikal
/// tugmalar emas, KARTALAR bo'lib chiqsin. Karta bosilganda esa
/// yangi ekran emas, MODAL oyna ochiladi.
library;

import 'package:flutter/material.dart';

import '../../models/marketplace/listing.dart';
import 'listing_card.dart';
import 'listing_modal.dart';

/// Chatда bir vaqtda ko'rsatiladigan eng ko'p karta soni.
const int kListingGridMax = 20;

class ListingGrid extends StatelessWidget {
  final List<Listing> listings;

  /// Karta bosilganda. Berilmasa standart MODAL ochiladi.
  final void Function(Listing listing)? onTap;

  const ListingGrid({super.key, required this.listings, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Chatда 20 tadan ko'pi ekranni to'ldirib yuboradi va suhbat
    // yo'qoladi — shuning uchun qat'iy chegara.
    final items = listings.take(kListingGridMax).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      // Chat ro'yxati ichida turadi: o'z aylanishi bo'lmasin.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final listing = items[index];
        return ListingCard(
          listing: listing,
          onTap: () {
            if (onTap != null) {
              onTap!(listing);
            } else {
              showListingModal(context, listing);
            }
          },
        );
      },
    );
  }
}
