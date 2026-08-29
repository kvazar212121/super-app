import 'package:flutter/material.dart';
import '../models/event_venue.dart';
import '../models/service_hub_kind.dart';
import '../widgets/event_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../widgets/save_provider_button.dart';
import '../utils/call_helper.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class EventVenueBookingScreen extends StatefulWidget {
  final EventVenue venue;

  const EventVenueBookingScreen({super.key, required this.venue});

  @override
  State<EventVenueBookingScreen> createState() =>
      _EventVenueBookingScreenState();
}

class _EventVenueBookingScreenState extends State<EventVenueBookingScreen> {
  final Set<int> _selectedAmenities = {};
  double _totalPrice = 0.0;

  EventVenue get venue => widget.venue;
  Color get _accent => ServiceHubKind.tadbirlar.accent;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  void _recalc() {
    double price = venue.basePrice;
    for (int i in _selectedAmenities) {
      price += venue.amenities[i].additionalPrice ?? 0;
    }
    setState(() => _totalPrice = price);
  }

  void _startCall() {
    CallHelper.startCallWithPurposeCheck(
      context,
      venue.providerId > 0 ? venue.providerId : 1, // Fallback for demo
      venue.name,
      categoryKey: ServiceHubKind.tadbirlar.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(venue.name),
          backgroundColor: Colors.transparent,
          foregroundColor: _accent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            EventVenueVisualWidget(venue: venue, accent: _accent),
            const SizedBox(height: 20),
            EventVenueInfoCard(venue: venue),
            const SizedBox(height: 20),
            if (venue.amenities.isNotEmpty) ...[
              const _SectionTitle(
                'Qo\'shimcha xizmatlar',
                Icons.add_circle_outline,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(venue.amenities.length, (i) {
                  final a = venue.amenities[i];
                  final isSel = _selectedAmenities.contains(i);
                  return FilterChip(
                    label: Text(a.name.tr),
                    selected: isSel,
                    selectedColor: _accent.withValues(alpha: 0.2),
                    checkmarkColor: _accent,
                    onSelected: (val) {
                      if (val) {
                        _selectedAmenities.add(i);
                      } else {
                        _selectedAmenities.remove(i);
                      }
                      _recalc();
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
            EventPriceSummaryCard(totalPrice: _totalPrice, accent: _accent),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _startCall,
                icon: const Icon(Icons.phone_in_talk, size: 22),
                label: const Text(
                  'Ma\'muriyatga qo\'ng\'iroq qilish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SaveProviderButton(
              id: venue.id,
              categoryKey: ServiceHubKind.tadbirlar.name,
              name: venue.name,
              address: venue.address,
              rating: 0.0,
              type: 'event_venue',
              rawJson: const <String, dynamic>{},
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: LuxTokens.textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
