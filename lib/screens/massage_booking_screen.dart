import '../utils/call_helper.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/massage_hijoma.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class MassageBookingScreen extends StatefulWidget {
  final MassageHijoma service;
  final MassageVisitMode? initialVisitMode;

  const MassageBookingScreen({
    super.key,
    required this.service,
    this.initialVisitMode,
  });

  @override
  State<MassageBookingScreen> createState() => _MassageBookingScreenState();
}

class _MassageBookingScreenState extends State<MassageBookingScreen> {
  ServiceType? _selectedServiceType;
  String? _selectedPriceOption;
  GenderType? _selectedGender;
  MassageVisitMode? _visitMode;
  final _addressCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  List<String> get _timeSlots => widget.service.timeSlots.isNotEmpty
      ? widget.service.timeSlots
      : const [
          '09:00', '10:00', '11:00', '12:00',
          '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
        ];

  List<MassageVisitMode> get _availableVisitModes {
    final m = widget.service.visitModes;
    if (m.isEmpty) {
      return [
        if (widget.service.supportsHomeVisit) MassageVisitMode.homeVisit,
        if (widget.service.supportsAtCenter) MassageVisitMode.atCenter,
      ];
    }
    return m;
  }

  @override
  void initState() {
    super.initState();
    _visitMode = MassageVisitMode.atCenter;
    _addressCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  double? get _totalPrice {
    if (_selectedPriceOption == null) return null;
    var total = (widget.service.prices[_selectedPriceOption] ?? 0).toDouble();
    if (_visitMode == MassageVisitMode.homeVisit) {
      final travel = widget.service.isTravelFeeIncluded ? 0.0 : widget.service.travelFee;
      total += travel;
    }
    return total;
  }

  bool get _canBook {
    if (_selectedServiceType == null ||
        _selectedPriceOption == null ||
        _selectedTimeSlot == null ||
        _selectedGender == null ||
        _visitMode == null) {
      return false;
    }
    if (_visitMode == MassageVisitMode.homeVisit &&
        _addressCtrl.text.trim().length < 5) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE11D48);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: true,
          child: CustomScrollView(
            slivers: [
            BookingSliverAppBar(
              color: accentColor,
              icon: LucideIcons.heartPulse,
              rawJson: widget.service.rawJson,
            ),
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
                      onCallPressed: () {
                        CallHelper.makeDirectCall(context, widget.service.ownerUserId, widget.service.name);
                      },
                      contactLabel: "Mutaxassis bilan bog'lanish",
                    ),
                    if (widget.service.visitModesLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.service.visitModesLabel,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (widget.service.address.isNotEmpty) ...[
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
                            Icon(LucideIcons.mapPin, color: accentColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.service.address,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_visitMode == MassageVisitMode.homeVisit) ...[
                      const SizedBox(height: 16),
                      BookingInputField(
                        controller: _addressCtrl,
                        hint: 'Uy manzili (ko\'cha, uy, kvartira)',
                        icon: LucideIcons.home,
                        accent: accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.service.isTravelFeeIncluded
                            ? 'Yo\'l kira: Bepul (narx ichida)'
                            : 'Yo\'l kira: +${currencyFormat.format(widget.service.travelFee)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.service.isTravelFeeIncluded ? Colors.green[800] : Colors.amber[900],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmat turi'),
                    const SizedBox(height: 12),
                    SelectableIconGrid<ServiceType>(
                      items: widget.service.serviceTypes,
                      selected: _selectedServiceType,
                      iconOf: (t) => t.icon,
                      labelOf: (t) => t.label,
                      onSelect: (t) => setState(() => _selectedServiceType = t),
                      accent: accentColor,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Narx variantlari'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: Map.fromEntries(
                        widget.service.prices.entries.where(
                          (e) => !e.key.contains("Uyga chiqish qo'shimcha"),
                        ),
                      ),
                      selected: _selectedPriceOption,
                      onSelect: (o) => setState(() => _selectedPriceOption = o),
                      accent: accentColor,
                      format: currencyFormat,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Jinsiyat'),
                    const SizedBox(height: 12),
                    _buildGenderSelector(accentColor),
                    const SizedBox(height: 24),
                    const SectionTitle('Sana'),
                    const SizedBox(height: 12),
                    HorizontalDatePicker(
                      selectedDate: _selectedDate,
                      accentColor: accentColor,
                      onDateSelected: (date) => setState(() => _selectedDate = date),
                      daysCount: 14,
                      startDaysOffset: 1,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Vaqt'),
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
                      primaryLabel: _canBook
                          ? "Band qilish — ${currencyFormat.format(_totalPrice)}"
                          : 'Band qilish',
                      onPrimary: _canBook
                          ? () => _confirmBooking(currencyFormat, _totalPrice)
                          : null,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
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
                right: gender == availableGenders.last ? 0 : 8,
              ),
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
                  Icon(gender.icon,
                      size: 20, color: isSelected ? color : Colors.grey[500]),
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

  void _confirmBooking(NumberFormat currencyFormat, double? totalPrice) async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Band qilishni tasdiqlang',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DetailRow(label: 'Xizmat', value: widget.service.name),
            DetailRow(label: 'Turi', value: _selectedServiceType!.label),
            DetailRow(label: 'Paket', value: _selectedPriceOption!),
            DetailRow(label: 'Jinsiyat', value: _selectedGender!.label),
            DetailRow(label: 'Qabul', value: _visitMode!.label),
            if (_visitMode == MassageVisitMode.homeVisit) ...[
              DetailRow(
                label: "Yo'l kira",
                value: widget.service.isTravelFeeIncluded ? "Bepul (narx ichida)" : currencyFormat.format(widget.service.travelFee),
              ),
              DetailRow(label: 'Manzil', value: _addressCtrl.text.trim()),
            ]
            else if (widget.service.address.isNotEmpty)
              DetailRow(label: 'Salon', value: widget.service.address),
            DetailRow(
              label: 'Vaqt',
              value:
                  '${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot',
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Narxi:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final hour =
                      int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 9;
                  final minute =
                      int.tryParse(_selectedTimeSlot!.split(':')[1]) ?? 0;
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
                    serviceName:
                        '${widget.service.name} — ${_selectedServiceType!.label}',
                    providerName: widget.service.name,
                    variant: _selectedPriceOption!,
                    address: widget.service.address,
                    notes:
                        'Mutaxassis jinsi: ${_selectedGender!.label}',
                    date: dateTime,
                    price: totalPrice ?? 150000.0,
                    status: OrderStatus.pending,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Muvaffaqiyatli band qilindi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Tasdiqlash',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
