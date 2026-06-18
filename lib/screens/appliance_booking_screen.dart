import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appliance_repair.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class ApplianceBookingScreen extends StatefulWidget {
  final ApplianceRepair service;

  const ApplianceBookingScreen({super.key, required this.service});

  @override
  State<ApplianceBookingScreen> createState() =>
      _ApplianceBookingScreenState();
}

class _ApplianceBookingScreenState extends State<ApplianceBookingScreen> {
  ApplianceType? _selectedApplianceType;
  String? _selectedBrand;
  String? _selectedPriceOption;
  final _problemController = TextEditingController();
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
  ];

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFF59E0B);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    final canBook = _selectedApplianceType != null &&
        _selectedPriceOption != null &&
        _selectedTimeSlot != null;
    final totalPrice =
        _selectedPriceOption != null ? widget.service.prices[_selectedPriceOption] : null;

    return GlassBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          BookingSliverAppBar(color: accentColor, icon: LucideIcons.wrench),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceProfileHeader(
                    name: widget.service.name,
                    rating: widget.service.rating,
                    phone: widget.service.phoneNumber,
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Texnika turini tanlang"),
                  const SizedBox(height: 12),
                  SelectableIconGrid<ApplianceType>(
                    items: widget.service.applianceTypes,
                    selected: _selectedApplianceType,
                    iconOf: (t) => t.icon,
                    labelOf: (t) => t.label,
                    onSelect: (t) => setState(() => _selectedApplianceType = t),
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Brendni tanlang"),
                  const SizedBox(height: 12),
                  SelectableChips(
                    items: widget.service.brands,
                    selected: _selectedBrand,
                    onSelect: (b) => setState(() => _selectedBrand = b),
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Xizmat turi"),
                  const SizedBox(height: 12),
                  PriceOptionList(
                    prices: widget.service.prices,
                    selected: _selectedPriceOption,
                    onSelect: (o) => setState(() => _selectedPriceOption = o),
                    accent: accentColor,
                    format: currencyFormat,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Muammo tavsifi"),
                  const SizedBox(height: 12),
                  BookingTextArea(
                    controller: _problemController,
                    hint: "Muammoni batafsil yozing...",
                    icon: LucideIcons.messageSquare,
                    accent: accentColor,
                  ),
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
                  BookingActionBar(
                    accent: accentColor,
                    primaryLabel: canBook
                        ? "Band qilish — ${currencyFormat.format(totalPrice)}"
                        : "Band qilish",
                    onPrimary: canBook ? () => _confirmBooking(currencyFormat) : null,
                    secondaryLabel: "Usta bilan bog'lanish",
                    secondaryIcon: LucideIcons.phone,
                    onSecondary: () {
                      final targetId = int.tryParse(widget.service.id) ?? 0;
                      CallService().startCall(targetId, widget.service.name);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CallScreen(isIncoming: false),
                        ),
                      );
                    },
                  ),
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

  void _confirmBooking(NumberFormat currencyFormat) async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
    final totalPrice = widget.service.prices[_selectedPriceOption];

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
            DetailRow(label: "Xizmat", value: widget.service.name),
            DetailRow(label: "Texnika", value: _selectedApplianceType!.label),
            if (_selectedBrand != null)
              DetailRow(label: "Brend", value: _selectedBrand!),
            DetailRow(label: "Turi", value: _selectedPriceOption!),
            if (_problemController.text.isNotEmpty)
              DetailRow(label: "Muammo", value: _problemController.text),
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
                      color: const Color(0xFFF59E0B)),
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
                    category: ServiceHubKind.texnikaUstasi,
                    serviceName: '${widget.service.name} — ${_selectedApplianceType!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: 'Mijoz xonadoni',
                    notes: 'Brend: ${_selectedBrand ?? "Noma‘lum"}\nMuammo: ${_problemController.text.trim()}',
                    date: dateTime,
                    price: totalPrice ?? 50000.0,
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
