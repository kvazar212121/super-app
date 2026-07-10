import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/nanny_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';

class NannyBookingScreen extends StatefulWidget {
  final NannyService nanny;
  final NannyServiceType? preselectedType;

  const NannyBookingScreen({
    super.key,
    required this.nanny,
    this.preselectedType,
  });

  @override
  State<NannyBookingScreen> createState() => _NannyBookingScreenState();
}

class _NannyBookingScreenState extends State<NannyBookingScreen> {
  final _availability = ProviderAvailabilityService();
  final _addressCtrl = TextEditingController();
  final _childNameCtrl = TextEditingController();
  final _childAgeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();

  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  bool _loadingSlots = true;
  bool _trialDay = false;

  static const _accent = Color(0xFFF472B6);

  double get _selectedPrice {
    if (_selectedService == null) return 0.0;
    final base = (widget.nanny.prices[_selectedService] ?? 100000).toDouble();
    final travel = widget.nanny.isTravelFeeIncluded
        ? 0.0
        : widget.nanny.travelFee;
    return base + travel;
  }

  bool get _canSubmit =>
      _selectedService != null &&
      _selectedTimeSlot != null &&
      _addressCtrl.text.trim().length >= 5 &&
      _childNameCtrl.text.trim().length >= 2 &&
      _childAgeCtrl.text.trim().isNotEmpty &&
      !_loadingSlots;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectByType(widget.preselectedType!);
    }
    _addressCtrl.addListener(() => setState(() {}));
    _childNameCtrl.addListener(() => setState(() {}));
    _childAgeCtrl.addListener(() => setState(() {}));
    _loadAvailability();
  }

  void _selectByType(NannyServiceType type) {
    for (final s in widget.nanny.services) {
      final lower = s.toLowerCase();
      final match = switch (type) {
        NannyServiceType.hourly => lower.contains('soat'),
        NannyServiceType.halfDay => lower.contains('yarim'),
        NannyServiceType.fullDay => lower.contains('butun'),
        NannyServiceType.overnight => lower.contains('tungi'),
        NannyServiceType.weekly => lower.contains('hafta'),
        NannyServiceType.monthly => lower.contains('oylik'),
      };
      if (match) {
        _selectedService = s;
        break;
      }
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _childNameCtrl.dispose();
    _childAgeCtrl.dispose();
    _notesCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loadingSlots = true);
    if (widget.nanny.providerId <= 0) {
      _timeSlots = widget.nanny.timeSlots.isNotEmpty
          ? widget.nanny.timeSlots
          : ProviderAvailability.defaultSlots;
      _bookedSlots = [];
    } else {
      final avail = await _availability.fetch(
        providerId: widget.nanny.providerId,
        date: _selectedDate,
      );
      _timeSlots = avail.slots.isNotEmpty
          ? avail.slots
          : (widget.nanny.timeSlots.isNotEmpty
                ? widget.nanny.timeSlots
                : ProviderAvailability.defaultSlots);
      _bookedSlots = avail.booked;
    }
    if (mounted) {
      setState(() {
        _loadingSlots = false;
        if (_selectedTimeSlot != null &&
            _bookedSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );
    final childName = _childNameCtrl.text.trim();
    final childAge = _childAgeCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final allergy = _allergyCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Enaga buyurtmasi',
      details: [
        MapEntry('Enaga', widget.nanny.name),
        MapEntry('Xizmat', _selectedService!),
        MapEntry('Bola', '$childName ($childAge yosh)'),
        MapEntry(
          "Yo'l kira",
          widget.nanny.isTravelFeeIncluded
              ? "Bepul (narx ichida)"
              : currency.format(widget.nanny.travelFee),
        ),
        MapEntry('Manzil', address),
        if (allergy.isNotEmpty) MapEntry('Allergiya', allergy),
        if (_trialDay) const MapEntry('Sinov kuni', 'Ha'),
        MapEntry('Sana', DateFormat('dd.MM.yyyy').format(_selectedDate)),
        MapEntry('Vaqt', _selectedTimeSlot!),
      ],
      totalLabel: 'Narxi',
      totalValue: currency.format(_selectedPrice),
      accent: _accent,
      confirmLabel: 'So\'rov yuborish',
    );
    if (!confirmed || !mounted) return;

    final hour = int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 9;
    final minute = int.tryParse(_selectedTimeSlot!.split(':')[1]) ?? 0;
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    final childInfo =
        'Bola: $childName, $childAge yosh'
        '${allergy.isNotEmpty ? '. Allergiya: $allergy' : ''}'
        '${_trialDay ? '. Sinov kuni so\'ralgan' : ''}'
        '${notes.isNotEmpty ? '. $notes' : ''}';

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.enaga,
      serviceName: '${widget.nanny.name} — $_selectedService',
      providerName: widget.nanny.name,
      variant: _selectedService!,
      address: address,
      notes: childInfo,
      date: dateTime,
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.nanny.providerId > 0 ? widget.nanny.providerId : null,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'So\'rov yuborildi! Enaga ko\'rib chiqadi va javob beradi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyurtma yuborib bo\'lmadi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            BookingSliverAppBar(
              color: _accent,
              icon: LucideIcons.baby,
              rawJson: widget.nanny.rawJson,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.nanny.name,
                      rating: widget.nanny.rating,
                      phone: widget.nanny.phoneNumber,
                      accent: _accent,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmat turi'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: {
                        for (final s in widget.nanny.services)
                          s: widget.nanny.prices[s] ?? 0,
                      },
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: _accent,
                      format: currency,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Bola haqida'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _childNameCtrl,
                      hint: 'Bola ismi',
                      icon: LucideIcons.user,
                      accent: _accent,
                    ),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _childAgeCtrl,
                      hint: 'Yoshi (masalan: 3)',
                      icon: LucideIcons.cake,
                      accent: _accent,
                    ),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _allergyCtrl,
                      hint: 'Allergiya / maxsus ehtiyojlar',
                      icon: LucideIcons.heartPulse,
                      accent: _accent,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Sinov kuni'.tr),
                      subtitle: Text(
                        'Birinchi uchrashuv — keyin doimiy shartnoma'.tr,
                      ),
                      value: _trialDay,
                      onChanged: (v) => setState(() => _trialDay = v),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Uy manzili'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _addressCtrl,
                      hint: 'To\'liq manzil',
                      icon: LucideIcons.mapPin,
                      accent: _accent,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Sana'),
                    const SizedBox(height: 12),
                    HorizontalDatePicker(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                        _loadAvailability();
                      },
                      accentColor: _accent,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Vaqt'),
                    const SizedBox(height: 12),
                    if (_loadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      TimeSlotGrid(
                        selectedTimeSlot: _selectedTimeSlot,
                        timeSlots: _timeSlots,
                        disabledTimeSlots: _bookedSlots,
                        onTimeSelected: (slot) =>
                            setState(() => _selectedTimeSlot = slot),
                        accentColor: _accent,
                      ),
                    const SizedBox(height: 16),
                    BookingTextArea(
                      controller: _notesCtrl,
                      hint: 'Qo\'shimcha izoh...',
                      icon: LucideIcons.messageSquare,
                      accent: _accent,
                    ),
                    const SizedBox(height: 32),
                    BookingActionBar(
                      accent: _accent,
                      primaryLabel: _canSubmit
                          ? 'So\'rov yuborish — ${currency.format(_selectedPrice)}'
                          : 'So\'rov yuborish',
                      onPrimary: _canSubmit ? _confirmBooking : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Buyurtma avtomatik tasdiqlanmaydi — enaga so\'rovni ko\'rib, qabul qiladi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
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
}
