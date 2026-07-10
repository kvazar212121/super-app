import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tutor_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';

class TutorBookingScreen extends StatefulWidget {
  final TutorService tutor;
  final LessonMode? preselectedMode;

  const TutorBookingScreen({
    super.key,
    required this.tutor,
    this.preselectedMode,
  });

  @override
  State<TutorBookingScreen> createState() => _TutorBookingScreenState();
}

class _TutorBookingScreenState extends State<TutorBookingScreen> {
  final _availability = ProviderAvailabilityService();
  final _studentCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _onlineCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  LessonMode? _lessonMode;
  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  bool _loadingSlots = true;

  static const _accent = Color(0xFF7C3AED);

  double get _selectedPrice {
    if (_selectedService == null) return 0.0;
    final base = (widget.tutor.prices[_selectedService] ?? 100000).toDouble();
    final travel =
        (_lessonMode == LessonMode.homeVisit &&
            !widget.tutor.isTravelFeeIncluded)
        ? widget.tutor.travelFee
        : 0.0;
    return base + travel;
  }

  bool get _canSubmit {
    if (_selectedService == null || _selectedTimeSlot == null || _loadingSlots)
      return false;
    if (_studentCtrl.text.trim().length < 2) return false;
    if (_lessonMode == LessonMode.homeVisit &&
        _addressCtrl.text.trim().length < 5)
      return false;
    if (_lessonMode == LessonMode.online && _onlineCtrl.text.trim().isEmpty)
      return false;
    return _lessonMode != null;
  }

  List<LessonMode> get _availableModes {
    final modes = widget.tutor.lessonModes;
    if (modes.isEmpty) return [LessonMode.online, LessonMode.homeVisit];
    return modes;
  }

  @override
  void initState() {
    super.initState();
    _lessonMode = widget.preselectedMode;
    if (_lessonMode != null && !_availableModes.contains(_lessonMode)) {
      _lessonMode = _availableModes.first;
    }
    _studentCtrl.addListener(() => setState(() {}));
    _addressCtrl.addListener(() => setState(() {}));
    _onlineCtrl.addListener(() => setState(() {}));
    _loadAvailability();
  }

  @override
  void dispose() {
    _studentCtrl.dispose();
    _goalCtrl.dispose();
    _addressCtrl.dispose();
    _onlineCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loadingSlots = true);
    if (widget.tutor.providerId <= 0) {
      _timeSlots = widget.tutor.timeSlots.isNotEmpty
          ? widget.tutor.timeSlots
          : ProviderAvailability.defaultSlots;
      _bookedSlots = [];
    } else {
      final avail = await _availability.fetch(
        providerId: widget.tutor.providerId,
        date: _selectedDate,
      );
      _timeSlots = avail.slots.isNotEmpty
          ? avail.slots
          : (widget.tutor.timeSlots.isNotEmpty
                ? widget.tutor.timeSlots
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
    final student = _studentCtrl.text.trim();
    final goal = _goalCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final online = _onlineCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Dars bronini tasdiqlang',
      details: [
        MapEntry('Repetitor', widget.tutor.name),
        MapEntry('Fan / dars', _selectedService!),
        MapEntry('Format', _lessonMode!.label),
        MapEntry('O\'quvchi', student),
        if (goal.isNotEmpty) MapEntry('Maqsad', goal),
        if (_lessonMode == LessonMode.homeVisit) ...[
          MapEntry(
            "Yo'l kira",
            widget.tutor.isTravelFeeIncluded
                ? "Bepul (narx ichida)"
                : currency.format(widget.tutor.travelFee),
          ),
          MapEntry('Manzil', address),
        ],
        if (_lessonMode == LessonMode.online) MapEntry('Onlayn', online),
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

    final noteParts = <String>[
      'O\'quvchi: $student',
      'Format: ${_lessonMode!.label}',
      if (goal.isNotEmpty) 'Maqsad: $goal',
      if (_lessonMode == LessonMode.online) 'Onlayn: $online',
      if (notes.isNotEmpty) notes,
    ];

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.repetitor,
      serviceName: '${widget.tutor.name} — $_selectedService',
      providerName: widget.tutor.name,
      variant: _selectedService!,
      address: _lessonMode == LessonMode.homeVisit ? address : online,
      notes: noteParts.join('. '),
      date: dateTime,
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.tutor.providerId > 0 ? widget.tutor.providerId : null,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('So\'rov yuborildi! Repetitor javob beradi.'),
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
              icon: LucideIcons.bookOpen,
              rawJson: widget.tutor.rawJson,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.tutor.name,
                      rating: widget.tutor.rating,
                      phone: widget.tutor.phoneNumber,
                      accent: _accent,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Dars formati'),
                    const SizedBox(height: 12),
                    ..._availableModes.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(m.icon, size: 16),
                              const SizedBox(width: 6),
                              Text(m.label.tr),
                            ],
                          ),
                          selected: _lessonMode == m,
                          selectedColor: _accent,
                          onSelected: (_) => setState(() => _lessonMode = m),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const SectionTitle('Fan / dars turi'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: {
                        for (final s in widget.tutor.services)
                          s: widget.tutor.prices[s] ?? 0,
                      },
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: _accent,
                      format: currency,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Kim uchun dars?'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _studentCtrl,
                      hint: 'Ism (o\'zingiz yoki farzandingiz)',
                      icon: LucideIcons.user,
                      accent: _accent,
                    ),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _goalCtrl,
                      hint: 'Maqsad (masalan: 9-sinf algebra, IELTS)',
                      icon: LucideIcons.target,
                      accent: _accent,
                    ),
                    if (_lessonMode == LessonMode.homeVisit) ...[
                      const SizedBox(height: 16),
                      BookingInputField(
                        controller: _addressCtrl,
                        hint: 'Uy manzili',
                        icon: LucideIcons.mapPin,
                        accent: _accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.tutor.isTravelFeeIncluded
                            ? "Yo'l kira: Bepul (narx ichida)"
                            : "Yo'l kira: +${currency.format(widget.tutor.travelFee)}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.tutor.isTravelFeeIncluded
                              ? Colors.green[800]
                              : Colors.amber[900],
                        ),
                      ),
                    ],
                    if (_lessonMode == LessonMode.online) ...[
                      const SizedBox(height: 16),
                      BookingInputField(
                        controller: _onlineCtrl,
                        hint: 'Telegram / Zoom havola yoki telefon',
                        icon: LucideIcons.video,
                        accent: _accent,
                      ),
                    ],
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
