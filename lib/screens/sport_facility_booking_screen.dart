import 'package:flutter/material.dart';
import '../models/sport_facility.dart';
import '../models/service_hub_kind.dart';
import '../widgets/sport_facility_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../widgets/save_provider_button.dart';
import '../utils/call_helper.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class SportFacilityBookingScreen extends StatefulWidget {
  final SportFacility facility;

  const SportFacilityBookingScreen({super.key, required this.facility});

  @override
  State<SportFacilityBookingScreen> createState() =>
      _SportFacilityBookingScreenState();
}

class _SportFacilityBookingScreenState
    extends State<SportFacilityBookingScreen> {
  final Set<int> _selectedAmenities = {};
  double _totalPrice = 0.0;
  final _notesCtrl = TextEditingController();

  SportFacility get field => widget.facility;
  Color get _accent => ServiceHubKind.sportMaydon.accent;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    double price = field.basePricePerHour;
    for (int i in _selectedAmenities) {
      price += field.amenities[i].additionalPrice ?? 0;
    }
    setState(() => _totalPrice = price);
  }

  void _startCall() {
    CallHelper.startCallWithPurposeCheck(
      context,
      field.providerId > 0 ? field.providerId : 1, // Fallback for demo
      field.name,
      categoryKey: ServiceHubKind.sportMaydon.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(field.name),
          backgroundColor: Colors.transparent,
          foregroundColor: _accent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            SportFacilityVisualWidget(facility: field, accent: _accent),
            const SizedBox(height: 20),
            SportFacilityInfoCard(facility: field),
            const SizedBox(height: 20),
            if (field.amenities.isNotEmpty) ...[
              SectionTitle('Qo\'shimcha qulayliklar', Icons.add_circle_outline),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(field.amenities.length, (i) {
                  final a = field.amenities[i];
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
            SectionTitle("Qo'shimcha izoh", Icons.note_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'Masalan: raketkalar tayyor turishini xohlayman...'.tr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SportPriceSummaryCard(
              facility: field,
              amenities: field.amenities,
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
            const SizedBox(height: 10),
            SaveProviderButton(
              id: field.id,
              categoryKey: ServiceHubKind.sportMaydon.name,
              name: field.name,
              address: field.address,
              rating: 0.0,
              type: 'sport_facility',
              rawJson: const <String, dynamic>{},
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
