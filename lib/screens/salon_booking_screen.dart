import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/beauty_salon.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../theme/glass_tokens.dart';

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

    return GlassBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          BookingSliverAppBar(color: accentColor, icon: LucideIcons.sparkles),
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
                  PriceOptionList(
                    prices: widget.salon.prices,
                    selected: _selectedService,
                    onSelect: (s) => setState(() => _selectedService = s),
                    accent: accentColor,
                    format: currencyFormat,
                  ),
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
                  Builder(builder: (context) {
                    final canBook = _selectedService != null &&
                        _selectedStaff != null &&
                        _selectedTimeSlot != null;
                    return BookingActionBar(
                      accent: accentColor,
                      primaryLabel: "Band qilish",
                      onPrimary: canBook ? _confirmBooking : null,
                      secondaryLabel: "Salon bilan bog'lanish",
                      secondaryIcon: LucideIcons.phone,
                      onSecondary: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "${widget.salon.phoneNumber} raqamiga bog'lanilmoqda...")),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: GlassTokens.primaryText(context)),
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
          style: TextStyle(
              color: GlassTokens.secondaryText(context), fontSize: 14),
        ),
      ],
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
                    color: isSelected ? color : GlassTokens.primaryText(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmBooking() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
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
