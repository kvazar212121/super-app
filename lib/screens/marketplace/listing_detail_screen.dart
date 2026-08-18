/// E'lonning to'liq sahifasi ("Batafsil" tugmasidan ochiladi).
///
/// Modal oyna qisqa ko'rinish uchun; bu yerda hamma narsa bor.
/// TELEFON RAQAMI bu yerda ham YO'Q — aloqa faqat ilova ichida.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/marketplace/listing.dart';
import '../../services/marketplace_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/marketplace/photo_carousel.dart';
import '../../widgets/marketplace/safety_warning_dialog.dart';
import '../calls/dm_chat_screen.dart';
import 'listing_photos_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matn = isDark ? Colors.white : Colors.black87;

    return GlassScaffold(
      title: 'E\'lon',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingPhotosScreen(photos: listing.photos),
              ),
            ),
            child: PhotoCarousel(photos: listing.photos, height: 260),
          ),
          const SizedBox(height: 16),
          Text(
            listing.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: matn,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            listing.priceText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          _qator(LucideIcons.package, 'Holati', listing.conditionText, matn),
          _qator(LucideIcons.mapPin, 'Manzil', listing.address, matn),
          if (listing.distanceText.isNotEmpty)
            _qator(LucideIcons.navigation, 'Masofa', listing.distanceText, matn),
          _qator(LucideIcons.eye, 'Ko\'rilgan', '${listing.views}', matn),
          ...listing.attributes.entries.map(
            (e) => _qator(LucideIcons.info, e.key, '${e.value}', matn),
          ),
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              listing.description,
              style: TextStyle(fontSize: 14, height: 1.5, color: matn),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _writeToSeller(context),
            icon: const Icon(LucideIcons.messageCircle, size: 18),
            label: const Text('Sotuvchiga yozish'),
          ),
          const SizedBox(height: 8),
          // Ogohlantirish har doim ko'rinib tursin: odam tugmani
          // bosmasdan oldin ham o'qisin.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
            ),
            child: const Text(
              kSafetyWarningText,
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qator(IconData icon, String nom, String qiymat, Color matn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$nom: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(qiymat, style: TextStyle(color: matn))),
        ],
      ),
    );
  }

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
}
