import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/courier_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class CourierBookingScreen extends StatefulWidget {
  final CourierService service;

  const CourierBookingScreen({super.key, required this.service});

  @override
  State<CourierBookingScreen> createState() => _CourierBookingScreenState();
}

class _CourierBookingScreenState extends State<CourierBookingScreen> {
  DeliveryType? _selectedDeliveryType;
  String? _selectedPriceOption;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isExpress = false;
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
    _fromController.dispose();
    _toController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF6366F1);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    final canBook = _selectedDeliveryType != null &&
        _fromController.text.isNotEmpty &&
        _toController.text.isNotEmpty &&
        _selectedTimeSlot != null;
    double? totalPrice = 0;
    if (_selectedPriceOption != null) {
      totalPrice = widget.service.prices[_selectedPriceOption];
      if (_isExpress) {
        final expressPrice = widget.service.prices['Express (+50%)'];
        if (expressPrice != null) totalPrice = (totalPrice ?? 0) + expressPrice;
      }
    }

    return GlassBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          BookingSliverAppBar(color: accentColor, icon: LucideIcons.package),
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
                  const SectionTitle("Yetkazish turi"),
                  const SizedBox(height: 12),
                  SelectableIconGrid<DeliveryType>(
                    items: widget.service.deliveryTypes,
                    selected: _selectedDeliveryType,
                    iconOf: (t) => t.icon,
                    labelOf: (t) => t.label,
                    onSelect: (t) => setState(() => _selectedDeliveryType = t),
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Qayerdan"),
                  const SizedBox(height: 12),
                  BookingInputField(
                    controller: _fromController,
                    hint: "Manzilni kiriting...",
                    icon: LucideIcons.mapPin,
                    accent: accentColor,
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle("Qayerga"),
                  const SizedBox(height: 12),
                  BookingInputField(
                    controller: _toController,
                    hint: "Yetkazish manzili...",
                    icon: LucideIcons.navigation,
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
                  const SectionTitle("Vazni (kg)"),
                  const SizedBox(height: 12),
                  BookingInputField(
                    controller: _weightController,
                    hint: "Yuk vaznini kiriting",
                    icon: LucideIcons.scale,
                    accent: accentColor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: "kg",
                  ),
                  const SizedBox(height: 24),
                  _buildExpressToggle(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Sana"),
                  const SizedBox(height: 12),
                  HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Vaqt"),
                  const SizedBox(height: 12),
                  TimeSlotGrid(
                    selectedTimeSlot: _selectedTimeSlot,
                    timeSlots: _timeSlots,
                    onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 32),
                  BookingActionBar(
                    accent: accentColor,
                    primaryLabel: canBook
                        ? "Buyurtma berish — ${currencyFormat.format(totalPrice)}"
                        : "Buyurtma berish",
                    onPrimary: canBook ? () => _confirmBooking(currencyFormat, totalPrice) : null,
                    secondaryLabel: "Kuryer bilan bog'lanish",
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

  Widget _buildExpressToggle(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isExpress ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpress ? color : kBookingBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.zap,
              color: _isExpress ? color : kBookingSub, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Express yetkazish",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: kBookingInk)),
                Text(
                  "Tezkor yetkazib berish (+50% narx)",
                  style: TextStyle(color: kBookingSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _isExpress,
            onChanged: (value) => setState(() => _isExpress = value),
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  void _confirmBooking(NumberFormat currencyFormat, double? totalPrice) async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
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
            const Text("Buyurtmani tasdiqlang",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DetailRow(label: "Kuryer", value: widget.service.name),
            DetailRow(label: "Yetkazish turi", value: _selectedDeliveryType!.label),
            DetailRow(label: "Manzil", value: _fromController.text),
            DetailRow(label: "Yetkazish", value: _toController.text),
            DetailRow(label: "Turi", value: _selectedPriceOption!),
            if (_weightController.text.isNotEmpty)
              DetailRow(label: "Vazn", value: "${_weightController.text} kg"),
            if (_isExpress)
              DetailRow(label: "Express", value: "Ha"),
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
                      color: const Color(0xFF6366F1)),
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
                    category: ServiceHubKind.kuryerlik,
                    serviceName: '${widget.service.name} — ${_selectedDeliveryType!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: 'Kimdan: ${_fromController.text.trim()} -> Kimga: ${_toController.text.trim()}',
                    notes: 'Vazn: ${_weightController.text.trim()} kg, Tezkor: ${_isExpress ? "Ha" : "Yo‘q"}',
                    date: dateTime,
                    price: totalPrice ?? 15000.0,
                    status: OrderStatus.pending,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Muvaffaqiyatli buyurtma berildi!"),
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
