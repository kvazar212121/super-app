import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/auto_mobile_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class AutoHelpBookingScreen extends StatefulWidget {
  final AutoMobileService service;
  final String? preselectedService;

  const AutoHelpBookingScreen({
    super.key,
    required this.service,
    this.preselectedService,
  });

  @override
  State<AutoHelpBookingScreen> createState() => _AutoHelpBookingScreenState();
}

class _AutoHelpBookingScreenState extends State<AutoHelpBookingScreen> {
  final _availability = ProviderAvailabilityService();
  final _locationCtrl = TextEditingController();
  final _carCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedService;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  bool _loadingSlots = true;

  static const _accent = Color(0xFF8B5CF6);

  double get _selectedPrice =>
      _selectedService == null ? 0 : (widget.service.prices[_selectedService] ?? 100000);

  bool get _canSubmit =>
      _selectedService != null &&
      _selectedTimeSlot != null &&
      _locationCtrl.text.trim().length >= 5 &&
      !_loadingSlots;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedService != null &&
        widget.service.services.contains(widget.preselectedService)) {
      _selectedService = widget.preselectedService;
    }
    _locationCtrl.addListener(() => setState(() {}));
    _loadAvailability();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _carCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loadingSlots = true);
    if (widget.service.providerId <= 0) {
      _timeSlots = ProviderAvailability.defaultSlots;
      _bookedSlots = [];
    } else {
      final avail = await _availability.fetch(
        providerId: widget.service.providerId,
        date: _selectedDate,
      );
      _timeSlots = avail.slots.isNotEmpty ? avail.slots : ProviderAvailability.defaultSlots;
      _bookedSlots = avail.booked;
    }
    if (mounted) {
      setState(() {
        _loadingSlots = false;
        if (_selectedTimeSlot != null && _bookedSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final currency = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);
    final location = _locationCtrl.text.trim();
    final car = _carCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Avto-yordam buyurtmasi',
      details: [
        MapEntry('Xizmat', widget.service.name),
        MapEntry('Tur', _selectedService!),
        MapEntry('Manzil', location),
        if (car.isNotEmpty) MapEntry('Mashina', car),
        MapEntry('Sana', DateFormat('dd.MM.yyyy').format(_selectedDate)),
        MapEntry('Vaqt', _selectedTimeSlot!),
      ],
      totalLabel: 'Narxi',
      totalValue: currency.format(_selectedPrice),
      accent: _accent,
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
      category: ServiceHubKind.avtoYordam,
      serviceName: '${widget.service.name} — $_selectedService',
      providerName: widget.service.name,
      variant: _selectedService!,
      address: location,
      notes: [
        if (car.isNotEmpty) 'Mashina: $car',
        if (notes.isNotEmpty) notes,
      ].join('. '),
      date: dateTime,
      price: _selectedPrice,
      status: OrderStatus.pending,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buyurtma qabul qilindi! ${widget.service.name} yo\'lda.'),
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
    final currency = NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            BookingSliverAppBar(color: _accent, icon: LucideIcons.car),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.service.name,
                      rating: widget.service.rating,
                      phone: widget.service.phoneNumber,
                      accent: _accent,
                    ),
                    if (widget.service.serviceArea != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: _accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.service.serviceArea!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmat turi'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: {
                        for (final s in widget.service.services)
                          s: widget.service.prices[s] ?? 0,
                      },
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: _accent,
                      format: currency,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Mashina qayerda?'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _locationCtrl,
                      hint: 'Manzil yoki mo\'ljal...',
                      icon: LucideIcons.mapPin,
                      accent: _accent,
                    ),
                    const SizedBox(height: 16),
                    const SectionTitle('Mashina modeli (ixtiyoriy)'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _carCtrl,
                      hint: 'Masalan: Cobalt, Nexia 3...',
                      icon: LucideIcons.car,
                      accent: _accent,
                    ),
                    const SizedBox(height: 16),
                    const SectionTitle('Muammo / izoh'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Benzin tugadi, akkumulyator o\'chdi...',
                        filled: true,
                        fillColor: kBookingCard,
                        prefixIcon: Icon(LucideIcons.messageSquare, color: kBookingSub),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else
                      TimeSlotGrid(
                        selectedTimeSlot: _selectedTimeSlot,
                        timeSlots: _timeSlots,
                        disabledTimeSlots: _bookedSlots,
                        onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                        accentColor: _accent,
                      ),
                    const SizedBox(height: 32),
                    BookingActionBar(
                      accent: _accent,
                      primaryLabel: _canSubmit
                          ? 'Chaqirish — ${currency.format(_selectedPrice)}'
                          : 'Chaqirish',
                      onPrimary: _canSubmit ? _confirmBooking : null,
                      secondaryLabel: 'Telefon orqali',
                      secondaryIcon: LucideIcons.phone,
                      onSecondary: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.service.phoneNumber} raqamiga qo\'ng\'iroq...')),
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
}
