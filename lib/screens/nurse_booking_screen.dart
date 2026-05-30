import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nurse_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../widgets/booking_common_widgets.dart';

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
                  const SectionTitle("Tibbiy xizmat turi"),
                  const SizedBox(height: 12),
                  _buildMedicalServiceGrid(accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Narx variantlari"),
                  const SizedBox(height: 12),
                  _buildPriceOptionsList(currencyFormat, accentColor),
                  const SizedBox(height: 24),
                  const SectionTitle("Bemor ismi"),
                  const SizedBox(height: 12),
                  _buildPatientNameInput(),
                  const SizedBox(height: 24),
                  const SectionTitle("Yosh guruhi"),
                  const SizedBox(height: 12),
                  _buildAgeGroupSelector(accentColor),
                  if (widget.service.homeVisit) ...[
                    const SizedBox(height: 24),
                    const SectionTitle("Manzil (uyga chiqish)"),
                    const SizedBox(height: 12),
                    _buildAddressInput(),
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
              LucideIcons.heartPulse,
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.award, size: 14, color: Colors.red[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.service.qualifications,
                  style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        if (widget.service.homeVisit) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.home, size: 14, color: Colors.red[700]),
                const SizedBox(width: 4),
                Text(
                  "Uyga chiqish mavjud",
                  style: TextStyle(
                      color: Colors.red[700],
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

  Widget _buildMedicalServiceGrid(Color color) {
    final availableServices = widget.service.medicalServices;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: availableServices.length,
      itemBuilder: (context, index) {
        final service = availableServices[index];
        final isSelected = _selectedMedicalService == service;
        return GestureDetector(
          onTap: () => setState(() => _selectedMedicalService = service),
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
                Icon(service.icon,
                    color: isSelected ? color : Colors.grey[500], size: 20),
                const SizedBox(width: 8),
                Text(
                  service.label,
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

  Widget _buildPatientNameInput() {
    return TextField(
      controller: _patientNameController,
      decoration: InputDecoration(
        hintText: "Bemor ismini kiriting",
        prefixIcon: Icon(LucideIcons.user, color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
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

  Widget _buildAddressInput() {
    return TextField(
      controller: _addressController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: "Manzilni kiriting...",
        prefixIcon: Icon(LucideIcons.mapPin, color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color color, NumberFormat currencyFormat) {
    final bool canBook = _selectedMedicalService != null &&
        _selectedPriceOption != null &&
        _patientNameController.text.isNotEmpty &&
        _selectedAgeGroup != null &&
        _selectedTimeSlot != null &&
        (!widget.service.homeVisit || _addressController.text.isNotEmpty);

    double? totalPrice;
    if (_selectedPriceOption != null) {
      totalPrice = widget.service.prices[_selectedPriceOption];
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canBook ? () => _confirmBooking(currencyFormat) : null,
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
            label: const Text("Hamshira bilan bog'lanish"),
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

  void _confirmBooking(NumberFormat currencyFormat) {
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
