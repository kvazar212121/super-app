import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/tutor_service.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import 'tutor_booking_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  final TutorService tutor;
  final LessonMode? preselectedMode;

  const TutorProfileScreen({
    super.key,
    required this.tutor,
    this.preselectedMode,
  });

  static const _accent = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return GlassScaffold(
      showBackButton: true,
      title: 'Repetitor profili',
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
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  child: const Icon(LucideIcons.bookOpen, color: _accent, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  tutor.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const Text(
                  'Repetitor',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${tutor.rating} (${tutor.reviewCount} sharh)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tutor.lessonModes.map((m) {
              return Chip(
                avatar: Icon(m.icon, size: 16, color: _accent),
                label: Text(m.label, style: const TextStyle(fontSize: 12)),
                backgroundColor: _accent.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _infoTile(context, LucideIcons.mapPin, 'Hudud', tutor.serviceArea ?? tutor.address),
          _infoTile(context, LucideIcons.calendar, 'Tajriba', '${tutor.experienceYears} yil'),
          _infoTile(context, LucideIcons.bookOpen, 'Fanlar', tutor.subjectsLabel),
          const SizedBox(height: 16),
          Text(
            'Darslar va narxlar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          ...tutor.services.map((s) {
            final price = tutor.prices[s] ?? 0;
            return GlassSurface(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: GlassTokens.radiusMd,
              child: Row(
                children: [
                  Expanded(child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(
                    currency.format(price),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _accent),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TutorBookingScreen(
                      tutor: tutor,
                      preselectedMode: preselectedMode,
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.calendarCheck),
              label: const Text('Dars bron qilish'),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) {
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
                Text(label, style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context))),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: GlassTokens.primaryText(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
