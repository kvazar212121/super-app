import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/football_field.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';

/// Optimallashtirilgan futbol maydoni bron qilish ekrani
/// — vizual maydon sxemasi (CustomPaint)
/// — vaqt slotlari gridi
/// — qo'shimcha xizmatlar tanlovi
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

    context.read<AppProvider>().addOrder(order);

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${field.name} maydoni bron qilindi!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
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
              // Already on booking screen from map
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
            _FieldVisualWidget(
              field: field,
              accent: accent,
            ),
            const SizedBox(height: 20),

            // === Maydon haqida tezkor ma'lumot ===
            _FieldInfoCard(field: field),
            const SizedBox(height: 20),

            // === Sana tanlash ===
            _SectionTitle('Sana tanlang', Icons.calendar_month_outlined),
            const SizedBox(height: 8),
            _DateChips(
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
            _SectionTitle('Vaqt oralig‘i', Icons.schedule),
            const SizedBox(height: 8),
            _TimeSlotGrid(
              slots: _todaySlots,
              selectedSlot: _selectedSlot,
              accent: accent,
              onSlotSelected: (s) => setState(() => _selectedSlot = s),
            ),
            const SizedBox(height: 20),

            // === O'yinchilar soni ===
            _SectionTitle(
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
              _SectionTitle('Qo‘shimcha xizmatlar', Icons.workspace_premium),
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
            _SectionTitle("Qo'shimcha izoh", Icons.note_outlined),
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
            _PriceSummaryCard(
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

// ===================================================================
//              VIZUAL MAYDON SXEMASI (CustomPaint)
// ===================================================================
class _FieldVisualWidget extends StatelessWidget {
  final FootballField field;
  final Color accent;

  const _FieldVisualWidget({required this.field, required this.accent});

  @override
  Widget build(BuildContext context) {
    final surfaceLabel = field.surface.label;
    final sizeLabel = field.size.shortLabel;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                field.surface.color.withValues(alpha: 0.2),
                field.surface.color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: field.surface.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Maydon chizmasi
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _FootballFieldPainter(
                    surface: field.surface,
                    size: field.size,
                  ),
                  size: const Size(double.infinity, 180),
                ),
              ),
              // Maydon turi yorlig'i
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: field.surface.color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(field.surface.icon, color: field.surface.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$surfaceLabel · $sizeLabel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: field.surface.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Maydon rasmini chizuvchi CustomPainter
class _FootballFieldPainter extends CustomPainter {
  final FieldSurface surface;
  final FieldSize size;

  _FootballFieldPainter({required this.surface, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final margin = 24.0;

    // Maydon ichki maydoni
    final fieldRect = RRect.fromLTRBR(
      margin,
      margin,
      w - margin,
      h - margin,
      const Radius.circular(8),
    );

    // Maysa rangi
    final grassColor = surface == FieldSurface.natural
        ? const Color(0xFF66BB6A)
        : surface == FieldSurface.artificial
            ? const Color(0xFF43A047)
            : const Color(0xFF8D6E63);

    // Fon (maysa)
    fillPaint.color = grassColor.withValues(alpha: 0.3);
    canvas.drawRRect(fieldRect, fillPaint);

    // Tashqi chiziq
    paint.color = Colors.white.withValues(alpha: 0.9);
    paint.strokeWidth = 2.0;
    canvas.drawRRect(fieldRect, paint);

    // Yarim chiziq
    final midX = w / 2;
    paint.color = Colors.white.withValues(alpha: 0.7);
    paint.strokeWidth = 1.5;
    canvas.drawLine(
      Offset(midX, margin),
      Offset(midX, h - margin),
      paint,
    );

    // Markaz aylanasi
    final centerY = h / 2;
    paint.strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(midX, centerY),
      28,
      paint,
    );
    // Markaz nuqtasi
    fillPaint.color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(midX, centerY), 3, fillPaint);

    // Penalty maydonchalari (chap)
    final penW = (w - 2 * margin) * 0.2;
    final penH = (h - 2 * margin) * 0.6;
    final penY = centerY - penH / 2;

    paint.strokeWidth = 1.5;
    paint.color = Colors.white.withValues(alpha: 0.7);

    // Chap penalty
    canvas.drawRect(
      Rect.fromLTRB(margin, penY, margin + penW, penY + penH),
      paint,
    );

    // O'ng penalty
    canvas.drawRect(
      Rect.fromLTRB(w - margin - penW, penY, w - margin, penY + penH),
      paint,
    );

    // Darvoza maydonchalari
    final goalW = 12.0;
    final goalH = penH * 0.55;
    final goalY = centerY - goalH / 2;
    paint.strokeWidth = 2.0;
    paint.color = Colors.white;

    // Chap darvoza
    canvas.drawRect(
      Rect.fromLTRB(margin - 4, goalY, margin + goalW, goalY + goalH),
      paint,
    );
    // O'ng darvoza
    canvas.drawRect(
      Rect.fromLTRB(w - margin - goalW, goalY, w - margin + 4, goalY + goalH),
      paint,
    );

    // Burchak yoylari
    paint.strokeWidth = 1.2;
    paint.color = Colors.white.withValues(alpha: 0.8);
    final arcR = 16.0;
    // Yuqori-chap
    canvas.drawArc(
      Rect.fromLTWH(margin - arcR / 2, margin - arcR / 2, arcR, arcR),
      0,
      1.57,
      false,
      paint,
    );
    // Yuqori-o'ng
    canvas.drawArc(
      Rect.fromLTWH(w - margin - arcR / 2, margin - arcR / 2, arcR, arcR),
      1.57,
      1.57,
      false,
      paint,
    );
    // Pastki-chap
    canvas.drawArc(
      Rect.fromLTWH(margin - arcR / 2, h - margin - arcR / 2, arcR, arcR),
      4.71,
      1.57,
      false,
      paint,
    );
    // Pastki-o'ng
    canvas.drawArc(
      Rect.fromLTWH(w - margin - arcR / 2, h - margin - arcR / 2, arcR, arcR),
      3.14,
      1.57,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===================================================================
//              FIELD INFO CARD
// ===================================================================
class _FieldInfoCard extends StatelessWidget {
  final FootballField field;

  const _FieldInfoCard({required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reyting
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      field.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      ' (${field.reviewCount})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                field.address,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Qulayliklar
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (field.hasLighting)
                _InfoChip(icon: Icons.light_mode, label: 'Yoritish'),
              if (field.hasParking)
                _InfoChip(icon: Icons.local_parking, label: 'Avtoturargoh'),
              if (field.hasShowers)
                _InfoChip(icon: Icons.shower, label: 'Dush'),
              if (field.hasCafe)
                _InfoChip(icon: Icons.local_cafe, label: 'Kafe'),
            ],
          ),
          const SizedBox(height: 12),
          // Narx
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                '${NumberFormat('#,###').format(field.basePricePerHour)} soʻm / soat',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//              SANA CHIPLARI (tezkor tanlov)
// ===================================================================
class _DateChips extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateChips({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // 7 kunlik tezkor tanlov
    final dates = List.generate(7, (i) => today.add(Duration(days: i + 1)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((d) {
          final isSelected = d.day == selectedDate.day &&
              d.month == selectedDate.month &&
              d.year == selectedDate.year;
          final weekday = DateFormat('E', 'uz_UZ').format(d);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${d.day}.${d.month}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF4CAF50),
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onSelected: (_) => onDateSelected(d),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ===================================================================
//              VAQT SLOTLARI GRIDI
// ===================================================================
class _TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final Color accent;
  final ValueChanged<TimeSlot> onSlotSelected;

  const _TimeSlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.accent,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Bu kun uchun boʻsh vaqt yoʻq'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected =
            selectedSlot != null && selectedSlot!.id == slot.id;

        return GestureDetector(
          onTap: slot.isAvailable ? () => onSlotSelected(slot) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 48 - 8) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: !slot.isAvailable
                  ? Colors.grey.shade100
                  : isSelected
                      ? accent
                      : accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !slot.isAvailable
                    ? Colors.grey.shade300
                    : isSelected
                        ? accent
                        : accent.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  slot.formatted,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: !slot.isAvailable
                        ? Colors.grey
                        : isSelected
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (slot.isAvailable)
                  Text(
                    '${NumberFormat('#,###').format(slot.price)} soʻm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : accent,
                    ),
                  )
                else
                  const Text(
                    'Band',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ===================================================================
//              SECTION TITLE
// ===================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionTitle(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

// ===================================================================
//              NARX XULOSASI CARD
// ===================================================================
class _PriceSummaryCard extends StatelessWidget {
  final FootballField field;
  final TimeSlot? selectedSlot;
  final List<FieldAmenity> amenities;
  final Set<int> selectedAmenities;
  final double totalPrice;
  final Color accent;

  const _PriceSummaryCard({
    required this.field,
    required this.selectedSlot,
    required this.amenities,
    required this.selectedAmenities,
    required this.totalPrice,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: accent),
              const SizedBox(width: 8),
              const Text(
                'Buyurtma xulosasi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PriceLine(
            label: field.name,
            value: selectedSlot != null
                ? '${NumberFormat('#,###').format(selectedSlot!.price)} soʻm'
                : '—',
          ),
          _PriceLine(
            label: 'Sana: ${DateFormat('dd.MM.yyyy', 'uz_UZ').format(
                  DateTime.now().add(const Duration(days: 1)), // placeholder
                )}',
            value: selectedSlot?.formatted ?? 'tanlanmagan',
          ),
          if (selectedAmenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
            ...selectedAmenities.map((i) {
              final a = amenities[i];
              return _PriceLine(
                label: a.name,
                value: a.price != null
                    ? '+${NumberFormat('#,###').format(a.price)} soʻm'
                    : 'bepul',
                isGreen: a.price == null,
              );
            }),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jami:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                selectedSlot != null
                    ? '${NumberFormat('#,###').format(totalPrice)} soʻm'
                    : '—',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const _PriceLine({
    required this.label,
    required this.value,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}