import '../utils/call_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/service_hub_kind.dart';
import '../models/saved_place_model.dart';
import '../providers/saved_places_provider.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import '../models/nanny_service.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import 'nanny_booking_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Enaga profili — tasdiqlash belgilari va xavfsiz booking oqimi.
class NannyProfileScreen extends StatefulWidget {
  final NannyService nanny;
  final NannyServiceType? preselectedType;

  const NannyProfileScreen({
    super.key,
    required this.nanny,
    this.preselectedType,
  });

  @override
  State<NannyProfileScreen> createState() => _NannyProfileScreenState();
}

class _NannyProfileScreenState extends State<NannyProfileScreen> {
  bool _reviewedProfile = false;
  bool _contactedNanny = false;

  static const _accent = Color(0xFFF472B6);

  NannyService get nanny => widget.nanny;

  bool get _canBook => _reviewedProfile && _contactedNanny;

  void _callNanny() {
    CallHelper.makeDirectCall(context, nanny.ownerUserId, nanny.name);
    setState(() => _contactedNanny = true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return GlassScaffold(
      showBackButton: true,
      title: 'Enaga profili',
      actions: [
        Consumer<SavedPlacesProvider>(
          builder: (context, savedPlaces, _) {
            final isSaved = savedPlaces.isSaved(nanny.id);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : GlassTokens.primaryText(context),
              ),
              onPressed: () {
                final savedItem = SavedPlace(
                  id: nanny.id,
                  categoryKey: 'enaga',
                  name: nanny.name,
                  address: nanny.serviceArea ?? nanny.address,
                  rating: nanny.rating,
                  type: 'nanny',
                  rawJson:
                      nanny.rawJson ??
                      {
                        'id': nanny.id,
                        'name': nanny.name,
                        'phone': nanny.phoneNumber,
                        'rating': nanny.rating,
                        'review_count': nanny.reviewCount,
                        'lat': nanny.latitude,
                        'lng': nanny.longitude,
                        'address': nanny.address,
                        'metadata': {
                          'type': 'nanny',
                          'experience_years': nanny.experienceYears,
                          'age_groups': nanny.ageGroups,
                          'languages': nanny.languages,
                          'service_types': nanny.serviceTypes
                              .map((t) => t.key)
                              .toList(),
                          'services': nanny.services,
                          'prices': nanny.prices,
                          'time_slots': nanny.timeSlots,
                          'verification_status': nanny.verificationStatus,
                          'nanny_role': nanny.nannyRole,
                          'repeat_families': nanny.repeatFamilies,
                        },
                      },
                );
                savedPlaces.toggleSave(savedItem);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSaved
                          ? 'Sevimli ro\'yxatidan o\'chirildi'
                          : 'Sevimli ro\'yxatiga qo\'shildi',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassSurface(
            padding: const EdgeInsets.all(20),
            borderRadius: GlassTokens.radiusLg,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: _accent,
                  child: const Icon(LucideIcons.baby, color: _accent, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  nanny.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const Text(
                  'Bola qarovchi',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${nanny.rating} (${nanny.reviewCount} sharh)'),
                  ],
                ),
                if (nanny.repeatFamilies > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${nanny.repeatFamilies} ta oila qayta murojaat qilgan',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _badgesSection(context),
          const SizedBox(height: 16),
          _infoTile(
            context,
            LucideIcons.mapPin,
            'Hudud',
            nanny.serviceArea ?? nanny.address,
          ),
          _infoTile(
            context,
            LucideIcons.calendar,
            'Tajriba',
            '${nanny.experienceYears} yil',
          ),
          _infoTile(
            context,
            LucideIcons.users,
            'Yosh guruhlari',
            nanny.ageGroupsLabel,
          ),
          _infoTile(
            context,
            LucideIcons.languages,
            'Tillari',
            nanny.languagesLabel,
          ),
          const SizedBox(height: 16),
          Text(
            'Xizmatlar va narxlar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          ...nanny.services.map((s) {
            final price = nanny.prices[s] ?? 0;
            return GlassSurface(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: GlassTokens.radiusMd,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    currency.format(price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          GlassSurface(
            padding: const EdgeInsets.all(16),
            borderRadius: GlassTokens.radiusMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Avval tanishuv',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bolalar xavfsizligi uchun avval enaga bilan qisqa suhbat qiling — telefon orqali yoki uchrashuv.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _callNanny,
                  icon: const Icon(LucideIcons.phone),
                  label: const Text('Qo\'ng\'iroq qilish'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enaga bilan bog\'landim'),
                  value: _contactedNanny,
                  onChanged: (v) =>
                      setState(() => _contactedNanny = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Profil va hujjatlarni ko\'rib chiqdim'),
                  value: _reviewedProfile,
                  onChanged: (v) =>
                      setState(() => _reviewedProfile = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canBook
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NannyBookingScreen(
                            nanny: nanny,
                            preselectedType: widget.preselectedType,
                          ),
                        ),
                      );
                    }
                  : null,
              icon: Icon(LucideIcons.calendarCheck),
              label: Text('Buyurtma berish'.tr),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (!_canBook)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Buyurtma berish uchun yuqoridagi qadamlarni bajaring.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badgesSection(BuildContext context) {
    final docs = nanny.documents;
    final badges = <({String label, bool ok, IconData icon})>[
      (
        label: 'Tibbiy spravka',
        ok: docs.medicalCert,
        icon: LucideIcons.heartPulse,
      ),
      (
        label: 'ID tasdiqlangan',
        ok: docs.idVerified,
        icon: LucideIcons.badgeCheck,
      ),
      (
        label: 'Sudlanganlik yo\'q',
        ok: docs.criminalRecord,
        icon: LucideIcons.shieldCheck,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (nanny.isVerified)
          _badgeChip('Platforma tasdiqlagan', true, LucideIcons.circleCheck),
        ...badges.map((b) => _badgeChip(b.label, b.ok, b.icon)),
      ],
    );
  }

  Widget _badgeChip(String label, bool ok, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (ok ? const Color(0xFF10B981) : Colors.grey),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (ok ? const Color(0xFF10B981) : Colors.grey)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: ok ? const Color(0xFF10B981) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ok ? const Color(0xFF10B981) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: GlassTokens.secondaryText(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
