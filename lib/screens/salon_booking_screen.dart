import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/beauty_salon.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../widgets/booking_common_widgets.dart';

class SalonBookingScreen extends StatefulWidget {
  final BeautySalon salon;

  const SalonBookingScreen({super.key, required this.salon});

  @override
  State<SalonBookingScreen> createState() => _SalonBookingScreenState();
}

class _SalonBookingScreenState extends State<SalonBookingScreen> {
  String? _selectedService;
  SalonStaff? _selectedStaff;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00"
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFE91E63); // Pink for Salon
    final currencyFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

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
                  _buildSalonHeader(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Xizmatni tanlang"),
                  const SizedBox(height: 12),
                  _buildServicesList(currencyFormat, accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Mutaxassisni tanlang"),
                  const SizedBox(height: 12),
                  _buildStaffList(accentColor),
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
                  _buildActionButtons(accentColor),
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
              LucideIcons.sparkles,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalonHeader(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.salon.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
                    widget.salon.rating.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.salon.address,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildServicesList(NumberFormat format, Color color) {
    return Column(
      children: widget.salon.services.map((service) {
        final isSelected = _selectedService == service;
        return GestureDetector(
          onTap: () => setState(() => _selectedService = service),
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
                  child: Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(format.format(widget.salon.prices[service]), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStaffList(Color color) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.salon.staff.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final st = widget.salon.staff[index];
          final isSelected = _selectedStaff?.id == st.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedStaff = st),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isSelected ? color : Colors.pink[50],
                  child: Icon(LucideIcons.user, color: isSelected ? Colors.white : color),
                ),
                const SizedBox(height: 4),
                Text(
                  st.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Color color) {
    final bool canBook = _selectedService != null && _selectedStaff != null && _selectedTimeSlot != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canBook ? _confirmBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[200],
            ),
            child: const Text("Band qilish", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${widget.salon.phoneNumber} raqamiga bog'lanilmoqda...")),
              );
            },
            icon: const Icon(LucideIcons.phone),
            label: const Text("Salon bilan bog'lanish"),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Band qilishni tasdiqlang", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DetailRow(label: "Salon", value: widget.salon.name),
            DetailRow(label: "Mutaxassis", value: _selectedStaff!.name),
            DetailRow(label: "Xizmat", value: _selectedService!),
            DetailRow(label: "Vaqt", value: "${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
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
                    category: ServiceHubKind.salon,
                    serviceName: '${widget.salon.name} — $_selectedService',
                    providerName: widget.salon.name,
                    variant: _selectedService!,
                    address: widget.salon.address,
                    notes: 'Mutaxassis: ${_selectedStaff!.name}',
                    date: dateTime,
                    price: 80000.0,
                    status: OrderStatus.pending,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Muvaffaqiyatli band qilindi!"), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Tasdiqlash", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
