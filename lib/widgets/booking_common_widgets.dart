import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/glass_tokens.dart';
import '../config/app_config.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Booking ekranlari uchun umumiy ranglar.
/// Kartalar har doim OQ fonda, shuning uchun ulardagi matn qat'iy qora.
/// Mesh fon ustidagi matnlar esa [GlassTokens] orqali temaga moslashadi.
const kBookingInk = Color(0xFF0F172A);
const kBookingSub = Color(0xFF64748B);
const kBookingCard = Colors.white;
const kBookingBorder = Color(0xFFE2E8F0);

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: GlassTokens.primaryText(context),
      ),
    );
  }
}

/// Ranglar gradientli SliverAppBar (xizmat ikonkasi bilan).
class BookingSliverAppBar extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double expandedHeight;
  final String? coverUrl;
  final Map<String, dynamic>? rawJson;
  final List<Widget>? actions;
  final Widget? title;

  const BookingSliverAppBar({
    super.key,
    required this.color,
    required this.icon,
    this.expandedHeight = 180,
    this.coverUrl,
    this.rawJson,
    this.actions,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final String? resolvedCoverUrl =
        (coverUrl != null && coverUrl!.trim().isNotEmpty)
            ? coverUrl
            : AppConfig.resolveCoverImage(rawJson);

    final bool hasImage =
        resolvedCoverUrl != null && resolvedCoverUrl.trim().isNotEmpty;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: color,
      foregroundColor: Colors.white,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: title,
        background: Container(
          color: color,
          child: hasImage
              // Rasm bo'lsa ko'rsatamiz; 404/xato yoki yuklanayotganда
              // rang + icon ko'rinadi (bo'sh rang qolmaydi).
              ? CachedNetworkImage(
                  imageUrl: AppConfig.formatImageUrl(resolvedCoverUrl),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.3),
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (_, _, _) =>
                      Center(child: Icon(icon, size: 64, color: Colors.white)),
                  placeholder: (_, _) =>
                      Center(child: Icon(icon, size: 64, color: Colors.white54)),
                )
              : Center(child: Icon(icon, size: 64, color: Colors.white)),
        ),
      ),
    );
  }
}

/// Xizmat sarlavhasi: nom + reyting + telefon.
class ServiceProfileHeader extends StatelessWidget {
  final String name;
  final double rating;
  final String phone;
  final Color accent;
  final Widget? extra;
  final VoidCallback? onCallPressed;
  final String? contactLabel;

  const ServiceProfileHeader({
    super.key,
    required this.name,
    required this.rating,
    required this.phone,
    required this.accent,
    this.extra,
    this.onCallPressed,
    this.contactLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (onCallPressed != null) ...[
              FilledButton.icon(
                onPressed: onCallPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.15),
                  foregroundColor: accent,
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  ),
                ),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text(
                  "Qo'ng'iroq qilish",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (extra != null) ...[const SizedBox(height: 8), extra!],
      ],
    );
  }
}

/// Ikonka + matnli, tanlanadigan 2 ustunli grid (overflow'siz).
/// [T] — har qanday tur (enum yoki model), faqat ikon va label kerak.
class SelectableIconGrid<T> extends StatelessWidget {
  final List<T> items;
  final T? selected;
  final IconData Function(T) iconOf;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;
  final Color accent;
  final int crossAxisCount;
  final double childAspectRatio;

  const SelectableIconGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.iconOf,
    required this.labelOf,
    required this.onSelect,
    required this.accent,
    this.crossAxisCount = 2,
    this.childAspectRatio = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? accent : kBookingCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : kBookingBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconOf(item),
                  color: isSelected ? Colors.white : kBookingSub,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    labelOf(item),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : kBookingInk,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tanlanadigan chiplar (brend / variant) — Wrap, overflow'siz.
class SelectableChips extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;
  final Color accent;

  const SelectableChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? accent : kBookingCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accent : kBookingBorder,
                width: 1.5,
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : kBookingInk,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Narx variantlari ro'yxati (nom + narx, tanlanadigan).
class PriceOptionList extends StatelessWidget {
  final Map<String, double> prices;
  final String? selected;
  final ValueChanged<String> onSelect;
  final Color accent;
  final NumberFormat format;

  /// Har bir variant ostidagi qo'shimcha matn (masalan: "30-45 daqiqa").
  final String? Function(String option)? subtitleOf;

  const PriceOptionList({
    super.key,
    required this.prices,
    required this.selected,
    required this.onSelect,
    required this.accent,
    required this.format,
    this.subtitleOf,
  });

  @override
  Widget build(BuildContext context) {
    final options = prices.keys.toList();
    return Column(
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? accent : kBookingCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : kBookingBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : kBookingInk,
                        ),
                      ),
                      if (subtitleOf != null &&
                          (subtitleOf!(option)?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleOf!(option)!,
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : kBookingSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  format.format(prices[option]),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : accent,
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

/// Ko'p qatorli matn maydoni (muammo tavsifi / izoh).
class BookingTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accent;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const BookingTextArea({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    this.maxLines = 3,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: kBookingInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kBookingSub),
        filled: true,
        fillColor: kBookingCard,
        prefixIcon: Icon(icon, color: kBookingSub),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBookingBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBookingBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}

/// Bitta qatorli matn maydoni (manzil / vazn va h.k.).
class BookingInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accent;
  final TextInputType keyboardType;
  final String? suffixText;
  final ValueChanged<String>? onChanged;

  const BookingInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    this.keyboardType = TextInputType.text,
    this.suffixText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: kBookingInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kBookingSub),
        suffixText: suffixText,
        filled: true,
        fillColor: kBookingCard,
        prefixIcon: Icon(icon, color: kBookingSub),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBookingBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBookingBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}

/// Asosiy + ikkilamchi (qo'ng'iroq) tugmalar.
/// Tugma matni uzun bo'lsa avtomatik kichrayadi (overflow'siz).
class BookingActionBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Color accent;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;
  final VoidCallback? onPrimaryDisabled;

  const BookingActionBar({
    super.key,
    required this.accent,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
    this.onPrimaryDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                onPrimary ??
                (onPrimaryDisabled ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Iltimos, barcha kerakli maydonlarni to'ldiring".tr,
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }),
            style: ElevatedButton.styleFrom(
              backgroundColor: onPrimary != null
                  ? accent
                  : Colors.grey[300]!.withValues(alpha: 0.5),
              foregroundColor: onPrimary != null
                  ? Colors.white
                  : Colors.grey[500],
              elevation: onPrimary != null ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                primaryLabel,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onSecondary,
              icon: Icon(secondaryIcon ?? Icons.phone),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(secondaryLabel!, maxLines: 1),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
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
          Text(
            label.tr,
            style: TextStyle(color: GlassTokens.secondaryText(context)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: GlassTokens.primaryText(context),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mutaxassis / xodim tanlash — salon, sartarosh va boshqa sohalar uchun.
class BookingStaffOption {
  final String id;
  final String name;
  final String? subtitle;
  final int providerId;

  const BookingStaffOption({
    required this.id,
    required this.name,
    this.subtitle,
    this.providerId = 0,
  });
}

class SelectableStaffRow extends StatelessWidget {
  final List<BookingStaffOption> staff;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final Color accent;
  final bool showAnyOption;
  final String anyOptionId;
  final String anyOptionLabel;

  const SelectableStaffRow({
    super.key,
    required this.staff,
    required this.selectedId,
    required this.onSelect,
    required this.accent,
    this.showAnyOption = true,
    this.anyOptionId = '__any_staff__',
    this.anyOptionLabel = 'Har qanday bo\'sh mutaxassis',
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      if (showAnyOption)
        BookingStaffOption(id: anyOptionId, name: anyOptionLabel),
      ...staff,
    ];

    if (items.isEmpty) {
      return Text(
        'Mutaxassislar ro\'yxati tez orada qo\'shiladi',
        style: TextStyle(color: GlassTokens.secondaryText(context)),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          final isAny = item.id == anyOptionId;
          final isSelected = selectedId == item.id;
          return GestureDetector(
            onTap: () => onSelect(item.id),
            child: SizedBox(
              width: isAny ? 88 : 72,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: isSelected ? accent : kBookingCard,
                      child: Icon(
                        isAny ? Icons.groups_outlined : Icons.person_outline,
                        color: isSelected ? Colors.white : kBookingSub,
                        size: isAny ? 26 : 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? accent
                          : GlassTokens.primaryText(context),
                      height: 1.15,
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

/// Buyurtma tasdiqlash pastki paneli — barcha sohalar uchun.
Future<bool> showBookingConfirmSheet(
  BuildContext context, {
  required String title,
  required List<MapEntry<String, String>> details,
  required String totalLabel,
  required String totalValue,
  required Color accent,
  String confirmLabel = 'Tasdiqlash',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBookingCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(ctx).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBookingBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kBookingInk,
            ),
          ),
          const SizedBox(height: 16),
          ...details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      d.key,
                      style: const TextStyle(color: kBookingSub),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      d.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kBookingInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: const TextStyle(color: kBookingSub, fontSize: 15),
              ),
              Text(
                totalValue,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
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
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(
            Duration(days: index + startDaysOffset),
          );
          final isToday = showBugun && index == 0 && startDaysOffset == 0;
          final isSelected =
              selectedDate.day == date.day && selectedDate.month == date.month;
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
