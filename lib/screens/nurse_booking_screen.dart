import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/nurse_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../services/provider_availability_service.dart';

class NurseBookingScreen extends StatefulWidget {
  final NurseService service;
  final MedicalService? initialMedicalService;

  const NurseBookingScreen({
    super.key,
    required this.service,
    this.initialMedicalService,
  });

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

  bool _loadingSlots = true;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  final _availabilityService = ProviderAvailabilityService();

  bool _isPriceRelevantForService(String priceKey, MedicalService? service) {
    if (service == null) return true;
    final keyLower = priceKey.toLowerCase();
    final labelLower = service.label.toLowerCase();
    
    if (keyLower.contains(labelLower)) return true;

    if (service == MedicalService.injection && keyLower.contains('in\'ektsiya')) return true;
    if (service == MedicalService.bloodTest && keyLower.contains('qon')) return true;
    if (service == MedicalService.drip && keyLower.contains('kapelnitsa')) return true;
    if (service == MedicalService.drip && keyLower.contains('tomchil')) return true;

    bool matchesAny = widget.service.medicalServices.any((s) {
      final sLabel = s.label.toLowerCase();
      if (keyLower.contains(sLabel)) return true;
      if (s == MedicalService.injection && keyLower.contains('in\'ektsiya')) return true;
      if (s == MedicalService.bloodTest && keyLower.contains('qon')) return true;
      if (s == MedicalService.drip && keyLower.contains('kapelnitsa')) return true;
      return false;
    });

    if (!matchesAny) return true;
    return false;
  }

  Map<String, double> get _filteredPrices {
    if (_selectedMedicalService == null) return widget.service.prices;
    
    final filtered = <String, double>{};
    for (final entry in widget.service.prices.entries) {
      if (_isPriceRelevantForService(entry.key, _selectedMedicalService)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  void _onMedicalServiceSelected(MedicalService s) {
    setState(() {
      _selectedMedicalService = s;
      if (_selectedPriceOption != null) {
        if (!_isPriceRelevantForService(_selectedPriceOption!, s)) {
          _selectedPriceOption = null;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedMedicalService = widget.initialMedicalService;
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingSlots = true;
      _selectedTimeSlot = null;
    });

    final availability = await _availabilityService.fetch(
      providerId: widget.service.providerId,
      date: _selectedDate,
    );

    if (!mounted) return;
    setState(() {
      _timeSlots = availability.slots.isNotEmpty
          ? availability.slots
          : (widget.service.timeSlots.isNotEmpty
              ? widget.service.timeSlots
              : ProviderAvailability.defaultSlots);
      _bookedSlots = availability.booked;
      _loadingSlots = false;
    });
  }

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
                  if (widget.service.serviceArea != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hudud: ${widget.service.serviceArea}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.home, color: accentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.service.visitLabel,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Hamshira sizning manzilingizga keladi',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Tibbiy xizmat turi"),
                  const SizedBox(height: 12),
                  SelectableIconGrid(
                    items: widget.service.medicalServices,
                    selected: _selectedMedicalService,
                    iconOf: (s) => s.icon,
                    labelOf: (s) => s.label,
                    onSelect: _onMedicalServiceSelected,
                    accent: accentColor,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Narx variantlari"),
                  const SizedBox(height: 12),
                  PriceOptionList(
                    prices: _filteredPrices,
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
                  const SizedBox(height: 24),
                  const SectionTitle('Manzil (uyga chaqirish)'),
                  const SizedBox(height: 12),
                  BookingTextArea(
                    controller: _addressController,
                    hint: 'Ko\'cha, uy, kvartira — to\'liq manzil',
                    icon: LucideIcons.mapPin,
                    accent: accentColor,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Sana"),
                  const SizedBox(height: 12),
                  HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    accentColor: accentColor,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                      _loadAvailability();
                    },
                    daysCount: 14,
                    startDaysOffset: 1,
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle("Vaqt"),
                  const SizedBox(height: 12),
                  _loadingSlots
                      ? const Center(child: CircularProgressIndicator())
                      : TimeSlotGrid(
                          timeSlots: _timeSlots,
                          selectedTimeSlot: _selectedTimeSlot,
                          accentColor: accentColor,
                          disabledTimeSlots: _bookedSlots,
                          onTimeSelected: (slot) =>
                              setState(() => _selectedTimeSlot = slot),
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
                            _addressController.text.trim().length >= 5)
                        ? "Band qilish — ${currencyFormat.format(widget.service.prices[_selectedPriceOption])}"
                        : "Band qilish",
                    onPrimary: (_selectedMedicalService != null &&
                            _selectedPriceOption != null &&
                            _patientNameController.text.isNotEmpty &&
                            _selectedAgeGroup != null &&
                            _selectedTimeSlot != null &&
                            _addressController.text.trim().length >= 5)
                        ? () => _confirmBooking(currencyFormat)
                        : null,
                    secondaryLabel: "Hamshira bilan bog'lanish",
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
                color: isSelected ? color : Colors.white,
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
            DetailRow(label: 'Qabul', value: widget.service.visitLabel),
            DetailRow(label: 'Manzil', value: _addressController.text),
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
                onPressed: () async {
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
                    providerId: widget.service.providerId > 0
                        ? widget.service.providerId
                        : null,
                  );

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  );

                  try {
                    await context.read<AppProvider>().addOrder(order);

                    if (context.mounted) {
                      Navigator.pop(context); // pop loading dialog
                      Navigator.pop(context); // pop bottom sheet
                      Navigator.pop(context); // pop booking screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Muvaffaqiyatli band qilindi!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // pop loading dialog
                      String errMsg = e.toString();
                      if (e is DioException) {
                        final data = e.response?.data;
                        if (data is Map && data.containsKey('detail')) {
                          errMsg = data['detail'].toString();
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Xatolik yuz berdi: $errMsg"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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
