import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Color accentColor;
  final int daysCount;
  final int startDaysOffset;
  final bool showBugun;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.accentColor,
    this.daysCount = 14,
    this.startDaysOffset = 1,
    this.showBugun = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: daysCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index + startDaysOffset));
          final isToday = showBugun && index == 0 && startDaysOffset == 0;
          final isSelected = selectedDate.day == date.day &&
              selectedDate.month == date.month;
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? "Bugun" : DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeSlotGrid extends StatelessWidget {
  final String? selectedTimeSlot;
  final List<String> timeSlots;
  final ValueChanged<String> onTimeSelected;
  final Color accentColor;
  final int crossAxisCount;
  final double childAspectRatio;
  final List<String>? disabledTimeSlots;

  const TimeSlotGrid({
    super.key,
    required this.selectedTimeSlot,
    required this.timeSlots,
    required this.onTimeSelected,
    required this.accentColor,
    this.crossAxisCount = 5,
    this.childAspectRatio = 1.8,
    this.disabledTimeSlots,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final isSelected = selectedTimeSlot == slot;
        final isDisabled = disabledTimeSlots?.contains(slot) ?? false;
        return GestureDetector(
          onTap: isDisabled ? null : () => onTimeSelected(slot),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? accentColor 
                  : (isDisabled ? Colors.grey[50] : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? accentColor 
                    : (isDisabled ? Colors.grey[200]! : Colors.grey[300]!),
              ),
            ),
            child: Center(
              child: Text(
                slot,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isDisabled ? Colors.grey[400] : Colors.black),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
