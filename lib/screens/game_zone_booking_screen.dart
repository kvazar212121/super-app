import 'package:flutter/material.dart';
import '../models/game_zone.dart';
import '../models/service_hub_kind.dart';
import '../widgets/booking_common_widgets.dart' hide SectionTitle;
import '../widgets/game_zone_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../utils/call_helper.dart';
import 'package:super_app/l10n/locale_controller.dart';

class GameZoneBookingScreen extends StatefulWidget {
  final GameZone zone;

  const GameZoneBookingScreen({super.key, required this.zone});

  @override
  State<GameZoneBookingScreen> createState() => _GameZoneBookingScreenState();
}

class _GameZoneBookingScreenState extends State<GameZoneBookingScreen> {
  final Set<int> _selectedAmenities = {};
  double _totalPrice = 0.0;
  final _notesCtrl = TextEditingController();

  GameZone get zone => widget.zone;
  Color get _accent => ServiceHubKind.gameZona.accent;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  void _recalc() {
    double price = zone.basePricePerHour;
    for (int i in _selectedAmenities) {
      price += zone.amenities[i].additionalPrice ?? 0;
    }
    setState(() => _totalPrice = price);
  }

  void _startCall() {
    CallHelper.startCallWithPurposeCheck(
      context,
      zone.providerId > 0 ? zone.providerId : 1, // Fallback for demo
      zone.name,
      categoryKey: ServiceHubKind.gameZona.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(zone.name),
          backgroundColor: Colors.transparent,
          foregroundColor: _accent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            GameZoneVisualWidget(zone: zone, accent: _accent),
            const SizedBox(height: 20),
            GameZoneInfoCard(zone: zone),
            const SizedBox(height: 20),
            if (zone.amenities.isNotEmpty) ...[
              SectionTitle('Qo\'shimcha qulayliklar', Icons.add_circle_outline),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(zone.amenities.length, (i) {
                  final a = zone.amenities[i];
                  final isSel = _selectedAmenities.contains(i);
                  return FilterChip(
                    label: Text(a.name.tr),
                    selected: isSel,
                    selectedColor: _accent.withOpacity(0.2),
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
            SectionTitle("Qo'shimcha istaklar", Icons.note_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Masalan: FIFA yozilgan kompyuter...'.tr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            GameZonePriceSummaryCard(
              zone: zone,
              amenities: zone.amenities,
              selectedAmenities: _selectedAmenities,
              totalPrice: _totalPrice,
              accent: _accent,
            ),
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
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle(this.title, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
