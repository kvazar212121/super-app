/// Karta bosilganda ochiladigan MODAL oyna.
///
/// Foydalanuvchi aniq so'radi: yangi ekran emas, modal. Ichida
/// rasmlar aylanmasi, to'liq tavsif va "Sotuvchiga yozish" tugmasi.
///
/// ⚠️ TELEFON RAQAMI YO'Q: aloqa faqat ilova ichida. Backend ham
/// raqamni yubormaydi, bu yerda ham ko'rsatiladigan joyi yo'q.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/marketplace/listing.dart';
import '../../screens/calls/dm_chat_screen.dart';
import '../../screens/marketplace/listing_detail_screen.dart';
import '../../services/marketplace_service.dart';
import '../../theme/glass_tokens.dart';
import 'photo_carousel.dart';
import 'safety_warning_dialog.dart';

Future<void> showListingModal(BuildContext context, Listing listing) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: GlassTokens.glassFill(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GlassTokens.radiusLg),
      ),
    ),
    builder: (_) => ListingModal(listing: listing),
  );
}

class ListingModal extends StatelessWidget {
  final Listing listing;

  const ListingModal({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matn = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PhotoCarousel(photos: listing.photos),
              const SizedBox(height: 12),
              Text(
                listing.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: matn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                listing.priceText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(context, LucideIcons.package, listing.conditionText),
                  if (listing.distanceText.isNotEmpty)
                    _chip(context, LucideIcons.mapPin, listing.distanceText),
                  _chip(context, LucideIcons.eye, '${listing.views}'),
                ],
              ),
              if (listing.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  listing.description,
                  style: TextStyle(fontSize: 14, height: 1.4, color: matn),
                ),
              ],
              if (listing.attributes.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...listing.attributes.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(fontSize: 13, color: matn),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      listing.address,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _writeToSeller(context),
                      icon: const Icon(LucideIcons.messageCircle, size: 18),
                      label: const Text('Sotuvchiga yozish'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailScreen(listing: listing),
                        ),
                      );
                    },
                    child: const Text('Batafsil'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aloqadan OLDIN ogohlantirish chiqadi (foydalanuvchi talabi).
  Future<void> _writeToSeller(BuildContext context) async {
    final javob = await showSafetyWarning(context, listing.id);
    if (!context.mounted) return;

    if (javob == SafetyChoice.report) {
      final sabab = await askReportReason(context);
      if (sabab == null || !context.mounted) return;
      await MarketplaceService().report(listing.id, sabab);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shikoyat yuborildi')),
      );
      return;
    }
    if (javob == SafetyChoice.dismissed) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DmChatScreen(
          peerId: listing.userId,
          peerName: listing.title,
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
