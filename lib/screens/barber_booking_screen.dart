import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/barber_shop.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../widgets/booking_common_widgets.dart';

class BarberBookingScreen extends StatefulWidget {
  final BarberShop shop;

  const BarberBookingScreen({super.key, required this.shop});

  @override
  State<BarberBookingScreen> createState() => _BarberBookingScreenState();
}

class _BarberBookingScreenState extends State<BarberBookingScreen> {
  String? _selectedService;
  Barber? _selectedBarber;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  // Mock available time slots
  final List<String> _timeSlots = [
    "09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00", "18:00"
  ];
  final List<String> _bookedSlots = ["11:00", "15:00"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShopHeader(theme),
                  const SizedBox(height: 24),
                  const SectionTitle("Xizmatni tanlang"),
                  const SizedBox(height: 12),
                  _buildServicesList(currencyFormat, theme),
                  const SizedBox(height: 24),
                  const SectionTitle("Sartaroshni tanlang"),
                  const SizedBox(height: 12),
                  _buildBarberList(theme),
                  const SizedBox(height: 24),
                  const SectionTitle("Sana"),
                  const SizedBox(height: 12),
                  HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    accentColor: theme.colorScheme.primary,
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
                    accentColor: theme.colorScheme.primary,
                    onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                    crossAxisCount: 5,
                    disabledTimeSlots: _bookedSlots,
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFF1E1E1E),
          child: Center(
            child: Icon(
              LucideIcons.scissors,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.shop.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    widget.shop.rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.shop.address,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildServicesList(NumberFormat format, ThemeData theme) {
    return Column(
      children: widget.shop.services.map((service) {
        final isSelected = _selectedService == service;
        return GestureDetector(
          onTap: () => setState(() => _selectedService = service),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("30-45 daqiqa", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Text(format.format(widget.shop.prices[service]), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarberList(ThemeData theme) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.shop.barbers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final barber = widget.shop.barbers[index];
          final isSelected = _selectedBarber?.id == barber.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedBarber = barber),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(LucideIcons.user, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  barber.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF6366F1) : Colors.black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalDatePicker(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index + 1));
          final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _buildTimeGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final isBooked = _bookedSlots.contains(slot);
        final isSelected = _selectedTimeSlot == slot;

        return GestureDetector(
          onTap: isBooked ? null : () => setState(() => _selectedTimeSlot = slot),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                ? const Color(0xFF6366F1) 
                : (isBooked ? Colors.grey[50] : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? const Color(0xFF6366F1) 
                  : (isBooked ? Colors.grey[200]! : Colors.grey[300]!),
              ),
            ),
            child: Center(
              child: Text(
                slot,
                style: TextStyle(
                  color: isSelected 
                    ? Colors.white 
                    : (isBooked ? Colors.grey[400] : Colors.black),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  decoration: isBooked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final bool canBook = _selectedService != null && 
                        _selectedBarber != null && 
                        _selectedTimeSlot != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canBook ? _confirmBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[200],
            ),
            child: const Text("Bron qilish", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${widget.shop.phoneNumber} raqamiga qo'ng'iroq qilinmoqda...")),
              );
            },
            icon: const Icon(LucideIcons.phone),
            label: const Text("Usta bilan bog'lanish", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tasdiqlash"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow("Sartaroshxona", widget.shop.name),
            _buildDialogRow("Usta", _selectedBarber!.name),
            _buildDialogRow("Xizmat", _selectedService!),
            _buildDialogRow("Vaqt", "${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () {
              final hour = int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 10;
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
                category: ServiceHubKind.sartarosh,
                serviceName: '${widget.shop.name} — $_selectedService',
                providerName: widget.shop.name,
                variant: _selectedService!,
                address: widget.shop.address,
                notes: 'Usta: ${_selectedBarber!.name}',
                date: dateTime,
                price: 65000.0,
                status: OrderStatus.pending,
              );

              context.read<AppProvider>().addOrder(order);

              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Muvaffaqiyatli band qilindi!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Tasdiqlash"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
