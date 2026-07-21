import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/football_field.dart';
import '../theme/glass_tokens.dart';

// ===================================================================
//              VIZUAL MAYDON SXEMASI (CustomPaint)
// ===================================================================
class FieldVisualWidget extends StatelessWidget {
  final FootballField field;
  final Color accent;

  const FieldVisualWidget({
    super.key,
    required this.field,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceLabel = field.surface.label;
    final sizeLabel = field.size.shortLabel;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [field.surface.color, field.surface.color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: field.surface.color, width: 1.5),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: FootballFieldPainter(
                    surface: field.surface,
                    size: field.size,
                  ),
                  size: const Size(double.infinity, 180),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: field.surface.color,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      field.surface.icon,
                      color: field.surface.color,
                      size: 20,
                    ),
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
class FootballFieldPainter extends CustomPainter {
  final FieldSurface surface;
  final FieldSize size;

  FootballFieldPainter({required this.surface, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final margin = 24.0;

    final fieldRect = RRect.fromLTRBR(
      margin,
      margin,
      w - margin,
      h - margin,
      const Radius.circular(8),
    );

    final grassColor = surface == FieldSurface.natural
        ? const Color(0xFF66BB6A)
        : surface == FieldSurface.artificial
        ? const Color(0xFF43A047)
        : const Color(0xFF8D6E63);

    fillPaint.color = grassColor;
    canvas.drawRRect(fieldRect, fillPaint);

    paint.color = Colors.white;
    paint.strokeWidth = 2.0;
    canvas.drawRRect(fieldRect, paint);

    final midX = w / 2;
    paint.color = Colors.white;
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(midX, margin), Offset(midX, h - margin), paint);

    final centerY = h / 2;
    paint.strokeWidth = 1.5;
    canvas.drawCircle(Offset(midX, centerY), 28, paint);
    fillPaint.color = Colors.white;
    canvas.drawCircle(Offset(midX, centerY), 3, fillPaint);

    final penW = (w - 2 * margin) * 0.2;
    final penH = (h - 2 * margin) * 0.6;
    final penY = centerY - penH / 2;

    paint.strokeWidth = 1.5;
    paint.color = Colors.white;

    canvas.drawRect(
      Rect.fromLTRB(margin, penY, margin + penW, penY + penH),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTRB(w - margin - penW, penY, w - margin, penY + penH),
      paint,
    );

    final goalW = 12.0;
    final goalH = penH * 0.55;
    final goalY = centerY - goalH / 2;
    paint.strokeWidth = 2.0;
    paint.color = Colors.white;

    canvas.drawRect(
      Rect.fromLTRB(margin - 4, goalY, margin + goalW, goalY + goalH),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(w - margin - goalW, goalY, w - margin + 4, goalY + goalH),
      paint,
    );

    paint.strokeWidth = 1.2;
    paint.color = Colors.white;
    final arcR = 16.0;
    canvas.drawArc(
      Rect.fromLTWH(margin - arcR / 2, margin - arcR / 2, arcR, arcR),
      0,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(w - margin - arcR / 2, margin - arcR / 2, arcR, arcR),
      1.57,
      1.57,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(margin - arcR / 2, h - margin - arcR / 2, arcR, arcR),
      4.71,
      1.57,
      false,
      paint,
    );
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
class FieldInfoCard extends StatelessWidget {
  final FootballField field;

  const FieldInfoCard({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTokens.glassBorder(context)),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
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
              Expanded(
                child: Text(
                  field.address,
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (field.hasLighting)
                const InfoChip(icon: Icons.light_mode, label: 'Yoritish'),
              if (field.hasParking)
                const InfoChip(
                  icon: Icons.local_parking,
                  label: 'Avtoturargoh',
                ),
              if (field.hasShowers)
                const InfoChip(icon: Icons.shower, label: 'Dush'),
              if (field.hasCafe)
                const InfoChip(icon: Icons.local_cafe, label: 'Kafe'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color: GlassTokens.secondaryText(context),
              ),
              const SizedBox(width: 6),
              Text(
                '${NumberFormat('#,###').format(field.basePricePerHour)} soʻm / soat',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
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
class DateChips extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateChips({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i + 1)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((d) {
          final isSelected =
              d.day == selectedDate.day &&
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
class TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final Color accent;
  final ValueChanged<TimeSlot> onSlotSelected;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.accent,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Bu kun uchun boʻsh vaqt yoʻq',
            style: TextStyle(color: GlassTokens.primaryText(context)),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = selectedSlot != null && selectedSlot!.id == slot.id;

        return GestureDetector(
          onTap: slot.isAvailable ? () => onSlotSelected(slot) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 48 - 8) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: !slot.isAvailable
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100)
                  : isSelected
                  ? accent
                  : accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !slot.isAvailable
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300)
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
                        ? GlassTokens.secondaryText(context)
                        : isSelected
                        ? Colors.white
                        : GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                if (slot.isAvailable)
                  Text(
                    '${NumberFormat('#,###').format(slot.price)} soʻm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : accent,
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
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const SectionTitle(this.text, this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: GlassTokens.secondaryText(context)),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: GlassTokens.primaryText(context),
        ),
      ),
    ],
  );
}

// ===================================================================
//              NARX XULOSASI CARD
// ===================================================================
class PriceSummaryCard extends StatelessWidget {
  final FootballField field;
  final TimeSlot? selectedSlot;
  final List<FieldAmenity> amenities;
  final Set<int> selectedAmenities;
  final double totalPrice;
  final Color accent;

  const PriceSummaryCard({
    super.key,
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
        color: accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Buyurtma xulosasi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PriceLine(
            label: field.name,
            value: selectedSlot != null
                ? '${NumberFormat('#,###').format(selectedSlot!.price)} soʻm'
                : '—',
          ),
          PriceLine(
            label:
                'Sana: ${DateFormat('dd.MM.yyyy', 'uz_UZ').format(DateTime.now().add(const Duration(days: 1)))}',
            value: selectedSlot?.formatted ?? 'tanlanmagan',
          ),
          if (selectedAmenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1, color: Colors.white30),
            const SizedBox(height: 6),
            ...selectedAmenities.map((i) {
              final a = amenities[i];
              return PriceLine(
                label: a.name,
                value: a.price != null
                    ? '+${NumberFormat('#,###').format(a.price)} soʻm'
                    : 'bepul',
                isGreen: a.price == null,
              );
            }),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white30),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jami:',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                selectedSlot != null
                    ? '${NumberFormat('#,###').format(totalPrice)} soʻm'
                    : '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const PriceLine({
    super.key,
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
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.white : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
