import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nurse_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class NurseBookingScreen extends StatefulWidget {
  final NurseService service;

  const NurseBookingScreen({super.key, required this.service});

  @override
  State<NurseBookingScreen> createState() => _NurseBookingScreenState();
}

class _NurseBookingScreenState extends State<NurseBookingScreen> {
  MedicalService? _selectedMedicalService;
  String? _selectedPriceOption;
  final _patientNameController = TextEditingController();
  String? _selectedAgeGroup;
  final _addressController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    "08:00",
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
    _patientNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFEF4444);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    return GlassBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          BookingSliverAppBar(color: accentColor, icon: LucideIcons.heartPulse),
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
                  const SectionTitle("Tibbiy xizmat turi"),
                  const SizedBox(height: 12),
                  SelectableIconGrid(
                    items: widget.service.medicalServices,
                    selected: _selectedMedicalService,
                    iconOf: (s) => s.icon,
                    labelOf: (s) => s.label,
                    onSelect: (s) => setState(() => _selectedMedicalService = s),
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Narx variantlari"),
                  const SizedBox(height: 12),
                  PriceOptionList(
                    prices: widget.service.prices,
                    selected: _selectedPriceOption,
                    onSelect: (o) => setState(() => _selectedPriceOption = o),
                    accent: accentColor,
                    format: currencyFormat,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Bemor ismi"),
                  const SizedBox(height: 12),
                  BookingInputField(
                    controller: _patientNameController,
                    hint: "Bemor ismini kiriting",
                    icon: LucideIcons.user,
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Yosh guruhi"),
                  const SizedBox(height: 12),
                  _buildAgeGroupSelector(accentColor),
                  if (widget.service.homeVisit) ...[
                    const SizedBox(height: 24),
                    const SectionTitle("Manzil (uyga chiqish)"),
                    const SizedBox(height: 12),
                    BookingTextArea(
                      controller: _addressController,
                      hint: "Manzilni kiriting...",
                      icon: LucideIcons.mapPin,
                      accent: accentColor,
                      maxLines: 2,
                    ),
                  ],
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
                    primaryLabel: (_selectedMedicalService != null &&
                            _selectedPriceOption != null &&
                            _patientNameController.text.isNotEmpty &&
                            _selectedAgeGroup != null &&
                            _selectedTimeSlot != null &&
                            (!widget.service.homeVisit ||
                                _addressController.text.isNotEmpty))
                        ? "Band qilish — ${currencyFormat.format(widget.service.prices[_selectedPriceOption])}"
                        : "Band qilish",
                    onPrimary: (_selectedMedicalService != null &&
                            _selectedPriceOption != null &&
                            _patientNameController.text.isNotEmpty &&
                            _selectedAgeGroup != null &&
                            _selectedTimeSlot != null &&
                            (!widget.service.homeVisit ||
                                _addressController.text.isNotEmpty))
                        ? () => _confirmBooking(currencyFormat)
                        : null,
                    secondaryLabel: "Hamshira bilan bog'lanish",
                    secondaryIcon: LucideIcons.phone,
                    onSecondary: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "${widget.service.phoneNumber} raqamiga bog'lanilmoqda...")),
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

  Widget _buildAgeGroupSelector(Color color) {
    final ageGroups = ["Katta", "Bola"];
    return Row(
      children: ageGroups.asMap().entries.map((entry) {
        final group = entry.value;
        final isSelected = _selectedAgeGroup == group;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedAgeGroup = group),
            child: Container(
              margin: EdgeInsets.only(
                  right: entry.key == ageGroups.length - 1 ? 0 : 8),
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
                  Icon(
                    group == "Katta" ? LucideIcons.user : LucideIcons.baby,
                    size: 20,
                    color: isSelected ? color : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group,
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
            DetailRow(label: "Tibbiy xizmat", value: _selectedMedicalService!.label),
            DetailRow(label: "Narx varianti", value: _selectedPriceOption!),
            DetailRow(label: "Bemor", value: _patientNameController.text),
            DetailRow(label: "Yosh guruhi", value: _selectedAgeGroup!),
            if (widget.service.homeVisit && _addressController.text.isNotEmpty)
              DetailRow(label: "Manzil", value: _addressController.text),
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
                      color: const Color(0xFFEF4444)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final hour = int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 8;
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
                    category: ServiceHubKind.hamshira,
                    serviceName: '${widget.service.name} — ${_selectedMedicalService!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Bemor uyi',
                    notes: 'Bemor: ${_patientNameController.text.trim()} (${_selectedAgeGroup})',
                    date: dateTime,
                    price: totalPrice ?? 100000.0,
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
