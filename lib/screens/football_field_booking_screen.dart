import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/football_field.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart' hide SectionTitle, TimeSlotGrid;
import '../widgets/football_field_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../widgets/save_provider_button.dart';
import '../utils/call_helper.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Futbol maydoni bron qilish — API slotlari bilan.
class FootballFieldBookingScreen extends StatefulWidget {
  final FootballField field;

  const FootballFieldBookingScreen({super.key, required this.field});

  @override
  State<FootballFieldBookingScreen> createState() =>
      _FootballFieldBookingScreenState();
}

class _FootballFieldBookingScreenState
    extends State<FootballFieldBookingScreen> {
  FootballField get field => widget.field;

  final _availability = ProviderAvailabilityService();
  final _notesCtrl = TextEditingController();
  final _playersCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  final Set<int> _selectedAmenities = {};
  List<TimeSlot> _slots = [];
  bool _loadingSlots = true;

  Color get _accent => ServiceHubKind.futbol.accent;

  @override
  void initState() {
    super.initState();
    _playersCtrl.text = field.size.minPlayers.toString();
    _loadSlots();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _playersCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    Set<String> booked = {};
    if (field.providerId > 0) {
      final avail = await _availability.fetch(
        providerId: field.providerId,
        date: _selectedDate,
      );
      booked = avail.booked.toSet();
    }
    if (mounted) {
      setState(() {
        _slots = field.getSlotsForDate(_selectedDate, booked: booked);
        _loadingSlots = false;
        if (_selectedSlot != null &&
            !_slots.any((s) => s.id == _selectedSlot!.id && s.isAvailable)) {
          _selectedSlot = null;
        }
      });
    }
  }

  double get _totalPrice {
    double price = _selectedSlot?.price ?? 0;
    for (final i in _selectedAmenities) {
      final amenity = field.amenities[i];
      if (amenity.price != null) price += amenity.price!;
    }
    return price;
  }

  void _startCall() {
    CallHelper.startCallWithPurposeCheck(
      context,
      field.providerId > 0 ? field.providerId : 1, // Fallback to 1 for demo
      field.name,
      categoryKey: ServiceHubKind.futbol.name,
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
            FieldVisualWidget(field: field, accent: _accent),
            const SizedBox(height: 20),
            FieldInfoCard(field: field),
            const SizedBox(height: 20),
            const SectionTitle('Sana tanlang', Icons.calendar_month_outlined),
            const SizedBox(height: 8),
            DateChips(
              selectedDate: _selectedDate,
              onDateSelected: (d) {
                setState(() => _selectedDate = d);
                _loadSlots();
              },
            ),
            const SizedBox(height: 20),
            const SectionTitle('Vaqt oralig\'i', Icons.schedule),
            const SizedBox(height: 8),
            if (_loadingSlots)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              TimeSlotGrid(
                slots: _slots,
                selectedSlot: _selectedSlot,
                accent: _accent,
                onSlotSelected: (s) => setState(() => _selectedSlot = s),
              ),
            const SizedBox(height: 20),
            SectionTitle(
              "O'yinchilar soni (${field.size.minPlayers}—${field.size.maxPlayers})",
              Icons.people_outline,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _playersCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nechta o\'yinchi?',
                prefixIcon: const Icon(Icons.people),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle("Qo'shimcha izoh", Icons.note_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Masalan: hakam kerak...'.tr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            PriceSummaryCard(
              field: field,
              selectedSlot: _selectedSlot,
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
              categoryKey: ServiceHubKind.futbol.name,
              name: field.name,
              address: field.address,
              rating: field.rating,
              type: 'football_field',
              rawJson: field.rawJson ?? const <String, dynamic>{},
            ),
          ],
        ),
      ),
    );
  }
}
