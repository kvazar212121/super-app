import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/disinfection_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class DisinfectionBookingScreen extends StatefulWidget {
  final DisinfectionService service;
  final AreaType? initialAreaType;
  final String? initialPriceOption;

  const DisinfectionBookingScreen({
    super.key,
    required this.service,
    this.initialAreaType,
    this.initialPriceOption,
  });

  @override
  State<DisinfectionBookingScreen> createState() =>
      _DisinfectionBookingScreenState();
}

class _DisinfectionBookingScreenState extends State<DisinfectionBookingScreen> {
  late AreaType? _selectedAreaType;
  late String? _selectedPriceOption;

  @override
  void initState() {
    super.initState();
    _selectedAreaType = widget.initialAreaType;
    _selectedPriceOption = widget.initialPriceOption;
    if (_selectedPriceOption == null && _selectedAreaType != null) {
      for (final entry in widget.service.prices.entries) {
        final label = _selectedAreaType!.label.toLowerCase();
        if (entry.key.toLowerCase().contains(label)) {
          _selectedPriceOption = entry.key;
          break;
        }
      }
    }
  }
  ChemicalProduct? _selectedChemical;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  final _areaSizeController = TextEditingController();

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
    _areaSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF10B981);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    final canBook = _selectedAreaType != null &&
        _selectedPriceOption != null &&
        _selectedTimeSlot != null;
    final totalPrice =
        _selectedPriceOption != null ? widget.service.prices[_selectedPriceOption] : null;

    return GlassBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          BookingSliverAppBar(color: accentColor, icon: LucideIcons.shieldCheck),
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
                  const SectionTitle("Hudud turini tanlang"),
                  const SizedBox(height: 12),
                  SelectableIconGrid<AreaType>(
                    items: widget.service.areaTypes,
                    selected: _selectedAreaType,
                    iconOf: (t) => t.icon,
                    labelOf: (t) => t.label,
                    onSelect: (t) => setState(() => _selectedAreaType = t),
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
                  if (_selectedAreaType == AreaType.apartment ||
                      _selectedAreaType == AreaType.office) ...[
                    const SizedBox(height: 24),
                    const SectionTitle("Maydon (m²)"),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _areaSizeController,
                      hint: "Maydonni kiriting (m²)",
                      icon: LucideIcons.ruler,
                      accent: accentColor,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: "m²",
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionTitle("Kimyoviy vosita"),
                  const SizedBox(height: 12),
                  _buildChemicalList(accentColor),
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
                    secondaryLabel: "Xizmat bilan bog'lanish",
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

  Widget _buildChemicalList(Color color) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.service.chemicals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final chemical = widget.service.chemicals[index];
          final isSelected = _selectedChemical == chemical;
          return GestureDetector(
            onTap: () => setState(() => _selectedChemical = chemical),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chemical.icon,
                      size: 18, color: isSelected ? color : Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    chemical.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  if (chemical.isEcoFriendly) ...[
                    const SizedBox(width: 4),
                    Icon(LucideIcons.leaf, size: 14, color: Colors.green[600]),
                  ],
                ],
              ),
            ),
          );
        },
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
            DetailRow(label: "Hudud", value: _selectedAreaType!.label),
            DetailRow(label: "Turi", value: _selectedPriceOption!),
            if (_areaSizeController.text.isNotEmpty)
              DetailRow(label: "Maydon", value: "${_areaSizeController.text} m²"),
            if (_selectedChemical != null)
              DetailRow(label: "Kimyoviy vosita", value: _selectedChemical!.name),
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
                      color: const Color(0xFF10B981)),
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
                    category: ServiceHubKind.dezinfeksiya,
                    serviceName: '${widget.service.name} — ${_selectedAreaType!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: 'Mijoz obyekti',
                    notes: 'Maydoni: ${_areaSizeController.text.trim()} m²\nVosita: ${_selectedChemical?.name ?? "Noma‘lum"}',
                    date: dateTime,
                    price: totalPrice ?? 80000.0,
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
