import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/football_field.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../widgets/football_field_widgets.dart';

/// Optimallashtirilgan futbol maydoni bron qilish ekrani
class FootballFieldBookingScreen extends StatefulWidget {
  final FootballField field;

  const FootballFieldBookingScreen({super.key, required this.field});

  @override
  State<FootballFieldBookingScreen> createState() =>
      _FootballFieldBookingScreenState();
}

class _FootballFieldBookingScreenState extends State<FootballFieldBookingScreen> {
  FootballField get field => widget.field;

  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _playersCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  final Set<int> _selectedAmenities = {}; // amenity index bo'yicha

  @override
  void initState() {
    super.initState();
    _playersCtrl.text = field.size.minPlayers.toString();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _playersCtrl.dispose();
    super.dispose();
  }

  List<TimeSlot> get _todaySlots => field.getSlotsForDate(_selectedDate);

  // Umumiy narx hisobi
  double get _totalPrice {
    double price = _selectedSlot?.price ?? 0;
    for (final i in _selectedAmenities) {
      final amenity = field.amenities[i];
      if (amenity.price != null) {
        price += amenity.price!;
      }
    }
    return price;
  }

  void _submitBooking() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, vaqt oralig‘ini tanlang'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedSlot!.start.hour,
      _selectedSlot!.start.minute,
    );

    final amenityNames = _selectedAmenities
        .map((i) => field.amenities[i].name)
        .toList();

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.futbol,
      serviceName: '${field.name} — ${field.size.shortLabel}',
      providerName: field.name,
      variant: '${field.size.shortLabel} — ${_selectedSlot!.formatted}',
      address: field.address,
      notes: '${_notesCtrl.text.trim()}${amenityNames.isNotEmpty ? '\nQoʻshimcha: ${amenityNames.join(', ')}' : ''}',
      date: dateTime,
      price: _totalPrice,
      status: OrderStatus.pending,
    );

    // Call addOrder (which calls backend API now!)
    context.read<AppProvider>().addOrder(order).then((_) {
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${field.name} maydoni bron qilindi!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik yuz berdi: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF4CAF50); // futbol yashil
    return Scaffold(
      appBar: AppBar(
        title: Text(field.name),
        backgroundColor: accent.withValues(alpha: 0.1),
        foregroundColor: accent,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Xaritada koʻrish',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xaritada koʻrilmoqda')),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // === Vizual maydon sxemasi ===
            FieldVisualWidget(
              field: field,
              accent: accent,
            ),
            const SizedBox(height: 20),

            // === Maydon haqida tezkor ma'lumot ===
            FieldInfoCard(field: field),
            const SizedBox(height: 20),

            // === Sana tanlash ===
            const SectionTitle('Sana tanlang', Icons.calendar_month_outlined),
            const SizedBox(height: 8),
            DateChips(
              selectedDate: _selectedDate,
              onDateSelected: (d) {
                setState(() {
                  _selectedDate = d;
                  _selectedSlot = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // === Vaqt slotlari ===
            const SectionTitle('Vaqt oralig‘i', Icons.schedule),
            const SizedBox(height: 8),
            TimeSlotGrid(
              slots: _todaySlots,
              selectedSlot: _selectedSlot,
              accent: accent,
              onSlotSelected: (s) => setState(() => _selectedSlot = s),
            ),
            const SizedBox(height: 20),

            // === O'yinchilar soni ===
            SectionTitle(
              "O'yinchilar soni (${field.size.minPlayers}—${field.size.maxPlayers})",
              Icons.people_outline,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _playersCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nechta o‘yinchi?',
                prefixIcon: const Icon(Icons.people),
                border: const OutlineInputBorder(),
                suffixText:
                    'min ${field.size.minPlayers} / max ${field.size.maxPlayers}',
              ),
            ),
            const SizedBox(height: 20),

            // === Qo'shimcha xizmatlar ===
            if (field.amenities.isNotEmpty) ...[
              const SectionTitle('Qo‘shimcha xizmatlar', Icons.workspace_premium),
              const SizedBox(height: 8),
              ...field.amenities.asMap().entries.map((e) {
                final idx = e.key;
                final amenity = e.value;
                final selected = _selectedAmenities.contains(idx);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedAmenities.add(idx);
                      } else {
                        _selectedAmenities.remove(idx);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Icon(amenity.icon, size: 20, color: accent),
                      const SizedBox(width: 8),
                      Text(amenity.name),
                      if (amenity.price != null) ...[
                        const Spacer(),
                        Text(
                          '${NumberFormat('#,###').format(amenity.price)} soʻm',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  activeColor: accent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 20),
            ],

            // === Izoh ===
            const SectionTitle("Qo'shimcha izoh", Icons.note_outlined),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Masalan: hakam kerak, formali o‘yin...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 20),

            // === Narx kartasi ===
            PriceSummaryCard(
              field: field,
              selectedSlot: _selectedSlot,
              amenities: field.amenities,
              selectedAmenities: _selectedAmenities,
              totalPrice: _totalPrice,
              accent: accent,
            ),
            const SizedBox(height: 20),

            // === Bron tugmasi ===
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submitBooking,
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'Maydonni bron qilish',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}