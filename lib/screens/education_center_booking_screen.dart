import 'package:flutter/material.dart';
import 'package:super_app/l10n/locale_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/education_center.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class EducationCenterBookingScreen extends StatefulWidget {
  final EducationCenter center;
  final String? preselectedService;

  const EducationCenterBookingScreen({
    super.key,
    required this.center,
    this.preselectedService,
  });

  @override
  State<EducationCenterBookingScreen> createState() =>
      _EducationCenterBookingScreenState();
}

class _EducationCenterBookingScreenState
    extends State<EducationCenterBookingScreen> {
  final _availability = ProviderAvailabilityService();
  final _studentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  bool _loadingSlots = true;

  static const _accent = Color(0xFF2563EB);

  List<String> get _services => widget.center.services.isNotEmpty
      ? widget.center.services
      : widget.center.courses;

  double get _selectedPrice {
    if (_selectedService == null) return 0;
    return widget.center.prices[_selectedService] ?? 150000;
  }

  bool get _canSubmit =>
      _selectedService != null &&
      _selectedTimeSlot != null &&
      _studentCtrl.text.trim().length >= 2 &&
      !_loadingSlots;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedService != null &&
        _services.contains(widget.preselectedService)) {
      _selectedService = widget.preselectedService;
    }
    _studentCtrl.addListener(() => setState(() {}));
    _loadAvailability();
  }

  @override
  void dispose() {
    _studentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loadingSlots = true);
    if (widget.center.providerId <= 0) {
      _timeSlots = widget.center.timeSlots.isNotEmpty
          ? widget.center.timeSlots
          : ProviderAvailability.defaultSlots;
      _bookedSlots = [];
    } else {
      final avail = await _availability.fetch(
        providerId: widget.center.providerId,
        date: _selectedDate,
      );
      _timeSlots = avail.slots.isNotEmpty
          ? avail.slots
          : ProviderAvailability.defaultSlots;
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
    final student = _studentCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final prices = <String, double>{
      for (final s in _services) s: widget.center.prices[s] ?? 150000,
    };

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Markazda dars bronini tasdiqlang',
      details: [
        MapEntry('Markaz', widget.center.name),
        MapEntry('Kurs', _selectedService!),
        MapEntry('O\'quvchi', student),
        MapEntry('Manzil', widget.center.address),
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

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.repetitor,
      serviceName: '${widget.center.name} — $_selectedService',
      providerName: widget.center.name,
      variant: _selectedService!,
      address: widget.center.address,
      notes: 'O\'quvchi: $student${notes.isNotEmpty ? '. $notes' : ''}',
      date: dateTime,
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.center.providerId > 0
          ? widget.center.providerId
          : null,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('So\'rov yuborildi! Markaz javob beradi.'.tr),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Buyurtma yuborib bo\'lmadi'.tr)),
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
    final prices = <String, double>{
      for (final s in _services) s: widget.center.prices[s] ?? 150000,
    };

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            BookingSliverAppBar(
              color: _accent,
              icon: LucideIcons.school,
              rawJson: widget.center.rawJson,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.center.name,
                      rating: widget.center.rating,
                      phone: widget.center.phoneNumber,
                      accent: _accent,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 14, color: _accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.center.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Kurs / dars'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: prices,
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: _accent,
                      format: currency,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('O\'quvchi'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _studentCtrl,
                      hint: 'Ism va sinf (masalan: Ali, 10-sinf)',
                      icon: LucideIcons.user,
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
                          ? 'Bron qilish — ${currency.format(_selectedPrice)}'
                          : 'Bron qilish',
                      onPrimary: _canSubmit ? _confirmBooking : null,
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
