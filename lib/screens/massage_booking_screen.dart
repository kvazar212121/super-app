import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/massage_hijoma.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../widgets/booking_common_widgets.dart';

class MassageBookingScreen extends StatefulWidget {
  final MassageHijoma service;

  const MassageBookingScreen({super.key, required this.service});

  @override
  State<MassageBookingScreen> createState() => _MassageBookingScreenState();
}

class _MassageBookingScreenState extends State<MassageBookingScreen> {
  ServiceType? _selectedServiceType;
  String? _selectedPriceOption;
  GenderType? _selectedGender;
  bool _isHomeVisit = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF8B5CF6);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(accentColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceHeader(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Xizmat turi"),
                  const SizedBox(height: 12),
                  _buildServiceTypeGrid(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Narx variantlari"),
                  const SizedBox(height: 12),
                  _buildPriceOptionsList(currencyFormat, accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Jinsiyat"),
                  const SizedBox(height: 12),
                  _buildGenderSelector(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Joylashuv"),
                  const SizedBox(height: 12),
                  _buildLocationSelector(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Sana"),
                  const SizedBox(height: 12),
                  HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    accentColor: accentColor,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                    daysCount: 14,
                    startDaysOffset: 1,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Vaqt"),
                  const SizedBox(height: 12),
                  TimeSlotGrid(
                    timeSlots: _timeSlots,
                    selectedTimeSlot: _selectedTimeSlot,
                    accentColor: accentColor,
                    onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                    crossAxisCount: 5,
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(accentColor, currencyFormat),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color color) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
          child: Center(
            child: Icon(
              LucideIcons.hand,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.service.name,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.star, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    widget.service.rating.toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.phone, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              widget.service.phoneNumber,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.users, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              widget.service.gender.label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        if (widget.service.homeVisit) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.home, size: 14, color: Colors.purple[700]),
                const SizedBox(width: 4),
                Text(
                  "Uyga chiqish mavjud",
                  style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceTypeGrid(Color color) {
    final availableTypes = widget.service.serviceTypes;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: availableTypes.length,
      itemBuilder: (context, index) {
        final type = availableTypes[index];
        final isSelected = _selectedServiceType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedServiceType = type),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon,
                    color: isSelected ? color : Colors.grey[500], size: 20),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceOptionsList(NumberFormat format, Color color) {
    final options = widget.service.prices.keys.toList();
    return Column(
      children: options.map((option) {
        final isSelected = _selectedPriceOption == option;
        return GestureDetector(
          onTap: () => setState(() => _selectedPriceOption = option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(option,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  format.format(widget.service.prices[option]),
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector(Color color) {
    final availableGenders = [
      if (widget.service.gender == GenderType.male ||
          widget.service.gender == GenderType.both)
        GenderType.male,
      if (widget.service.gender == GenderType.female ||
          widget.service.gender == GenderType.both)
        GenderType.female,
    ];

    if (availableGenders.isEmpty) return const SizedBox.shrink();

    return Row(
      children: availableGenders.map((gender) {
        final isSelected = _selectedGender == gender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = gender),
            child: Container(
              margin: EdgeInsets.only(
                  right:
                      gender == availableGenders.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(gender.icon,
                      size: 20,
                      color: isSelected ? color : Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    gender.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationSelector(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isHomeVisit ? color.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHomeVisit ? color : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isHomeVisit ? LucideIcons.home : LucideIcons.building2,
            color: _isHomeVisit ? color : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHomeVisit ? "Uyga keladi" : "Salonda",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _isHomeVisit
                      ? "Mutaxassis uyga keladi"
                      : "Salonga tashrif buyuring",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (widget.service.homeVisit)
            Switch(
              value: _isHomeVisit,
              onChanged: (value) => setState(() => _isHomeVisit = value),
              activeThumbColor: color,
            )
          else
            Text(
              "Salon",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color color, NumberFormat currencyFormat) {
    final bool canBook = _selectedServiceType != null &&
        _selectedPriceOption != null &&
        _selectedTimeSlot != null &&
        _selectedGender != null;

    double? totalPrice;
    if (_selectedPriceOption != null) {
      totalPrice = widget.service.prices[_selectedPriceOption];
      if (_isHomeVisit) {
        final homeVisitPrice = widget.service.prices['Uyga chiqish (+50%)'];
        if (homeVisitPrice != null) {
          totalPrice = totalPrice! + homeVisitPrice;
        }
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canBook ? () => _confirmBooking(currencyFormat, totalPrice) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[200],
            ),
            child: Text(
              canBook
                  ? "Band qilish — ${currencyFormat.format(totalPrice)}"
                  : "Band qilish",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "${widget.service.phoneNumber} raqamiga bog'lanilmoqda...")),
              );
            },
            icon: const Icon(LucideIcons.phone),
            label: const Text("Mutaxassis bilan bog'lanish"),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking(NumberFormat currencyFormat, double? totalPrice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Band qilishni tasdiqlang",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DetailRow(label: "Markaz", value: widget.service.name),
            DetailRow(label: "Xizmat", value: _selectedServiceType!.label),
            DetailRow(label: "Turi", value: _selectedPriceOption!),
            DetailRow(label: "Jinsiyat", value: _selectedGender!.label),
            DetailRow(
                label: "Joylashuv", value: _isHomeVisit ? "Uyga chiqish" : "Salonda"),
            DetailRow(
                label: "Vaqt",
                value: "${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot"),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Narxi:",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormat.format(totalPrice),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final hour = int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 9;
                  final minute = int.tryParse(_selectedTimeSlot!.split(':')[1]) ?? 0;
                  final dateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                    minute,
                  );

                  final order = ServiceOrder(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    category: ServiceHubKind.massajHijoma,
                    serviceName: '${widget.service.name} — ${_selectedServiceType!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: _isHomeVisit ? 'Mijoz xonadoni' : 'Salonda',
                    notes: 'Mutaxassis jinsi: ${_selectedGender!.label}',
                    date: dateTime,
                    price: totalPrice ?? 120000.0,
                    status: OrderStatus.pending,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Muvaffaqiyatli band qilindi!"),
                        backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Tasdiqlash",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
