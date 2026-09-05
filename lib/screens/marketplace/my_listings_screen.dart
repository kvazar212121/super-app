/// «Mening e'lonlarim» — Buyurtmalarim ichidagi bo'lim.
///
/// Foydalanuvchi qarori: muddat tugagach e'lon o'chmaydi, shu yerda
/// turadi va UZAYTIRILADI (premium bepul, boshqasi balansdan).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/marketplace/listing.dart';
import '../../services/marketplace_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/marketplace/listing_modal.dart';
import '../../theme/lux_tokens.dart';
import '../../l10n/locale_controller.dart';
import '../chat_screen.dart';

class MyListingsScreen extends StatefulWidget {
  /// «Buyurtmalarim» ichida tab sifatida ochilgan bo'lsa true.
  final bool embedded;

  const MyListingsScreen({super.key, this.embedded = false});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _service = MarketplaceService();

  List<Listing> _items = const [];
  Map<String, dynamic> _extend = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final natija = await _service.myListings();
      if (!mounted) return;
      setState(() {
        _items = natija.items;
        _extend = natija.extend;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'E\'lonlar yuklanmadi';
        _loading = false;
      });
    }
  }

  Future<void> _openCreateListing() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(
          initialText: "Sotiladigan buyum e'lonini joylashtirmoqchiman: ",
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _body();
    final fab = Container(
      height: 52,
      margin: EdgeInsets.only(bottom: widget.embedded ? 90 : 16),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33102A43),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _openCreateListing,
        borderRadius: BorderRadius.circular(26),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.plus, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'E\'lon berish'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: fab,
        body: bodyContent,
      );
    }

    return GlassScaffold(
      title: 'Mening e\'lonlarim'.tr,
      showBackButton: true,
      body: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: fab,
        body: bodyContent,
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Qayta')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: GlassSurface(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            borderRadius: GlassTokens.radiusLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shoppingBag,
                    size: 40,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hozircha e\'loningiz yo\'q'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sotiladigan buyumingiz bo\'lsa e\'lon berishingiz mumkin.'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF102A43),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(Listing listing) {
    final tugagan = listing.isExpired;
    final sotilgan = listing.status == ListingStatus.sold;
    final rang = sotilgan
        ? Colors.grey
        : (tugagan ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
        border: Border.all(color: GlassTokens.glassBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: rang.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  listingStatusLabel(
                    tugagan && !sotilgan ? ListingStatus.expired : listing.status,
                  ),
                  style: TextStyle(fontSize: 11, color: rang),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(listing.priceText, style: const TextStyle(color: LuxTokens.gold)),
          const SizedBox(height: 4),
          Text(
            _muddatMatni(listing),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => showListingModal(context, listing),
                icon: const Icon(LucideIcons.eye, size: 14),
                label: const Text('Ko\'rish'),
              ),
              if (listing.status == ListingStatus.active && !tugagan)
                OutlinedButton.icon(
                  onPressed: () => _amal(listing, 'sold'),
                  icon: const Icon(LucideIcons.check, size: 14),
                  label: const Text('Sotildi'),
                ),
              if (tugagan && !sotilgan)
                FilledButton.icon(
                  onPressed: () => _uzaytirish(listing),
                  icon: const Icon(LucideIcons.clock, size: 14),
                  label: Text(_uzaytirishMatni),
                ),
              if (sotilgan || listing.status == ListingStatus.hidden)
                OutlinedButton.icon(
                  onPressed: () => _amal(listing, 'reopen'),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Qayta e\'lon'),
                ),
              if (listing.status == ListingStatus.active)
                TextButton.icon(
                  onPressed: () => _amal(listing, 'hide'),
                  icon: const Icon(LucideIcons.eyeOff, size: 14),
                  label: const Text('Yashirish'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String get _uzaytirishMatni {
    if (_extend['free'] == true) return 'Uzaytirish (bepul)';
    final narx = (_extend['price'] as num?)?.toInt();
    return narx == null ? 'Uzaytirish' : 'Uzaytirish · $narx so\'m';
  }

  String _muddatMatni(Listing listing) {
    if (listing.status == ListingStatus.sold) return 'Sotilgan';
    if (listing.isExpired) return 'Muddati tugagan';
    return '${listing.daysLeft} kun qoldi · ${listing.views} ko\'rilgan';
  }

  Future<void> _amal(Listing listing, String amal) async {
    try {
      switch (amal) {
        case 'sold':
          await _service.markSold(listing.id);
        case 'hide':
          await _service.hide(listing.id);
        case 'reopen':
          await _service.reopen(listing.id);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amal bajarilmadi')));
    }
  }

  /// Uzaytirish PULLIK bo'lishi mumkin — shuning uchun tasdiq so'raladi.
  Future<void> _uzaytirish(Listing listing) async {
    final tasdiq = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Muddatni uzaytirish'),
        content: Text(
          (_extend['message'] as String?) ??
              'E\'lon muddati uzaytiriladi. Davom etamizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Bekor'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
    if (tasdiq != true) return;
    try {
      await _service.extend(listing.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzaytirilmadi: balansni tekshiring')),
      );
    }
  }
}
