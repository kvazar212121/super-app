import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/barber_shop.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../theme/glass_tokens.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class BarberBookingScreen extends StatefulWidget {
  final BarberShop shop;

  const BarberBookingScreen({super.key, required this.shop});

  @override
  State<BarberBookingScreen> createState() => _BarberBookingScreenState();
}

class _BarberBookingScreenState extends State<BarberBookingScreen> {
  static const _anyStaffId = '__any_staff__';

  final _availabilityService = ProviderAvailabilityService();

  String? _selectedService;
  String? _selectedStaffId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  bool _loadingSlots = true;

  Color get _accent => ServiceHubKind.sartarosh.accent;

  List<BookingStaffOption> get _staffOptions => widget.shop.barbers
      .map(
        (b) => BookingStaffOption(
          id: b.id,
          name: b.name,
          subtitle: b.rating.toStringAsFixed(1),
        ),
      )
      .toList();

  String get _staffLabel {
    if (_selectedStaffId == null) return '';
    if (_selectedStaffId == _anyStaffId) return 'Har qanday bo\'sh usta';
    final match = widget.shop.barbers.where((b) => b.id == _selectedStaffId);
    return match.isEmpty ? 'Har qanday bo\'sh usta' : match.first.name;
  }

  double get _selectedPrice => _selectedService == null
      ? 0
      : (widget.shop.prices[_selectedService] ??
          BarberShop.defaultPriceForService(_selectedService!));

  String _serviceDuration(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('soqol')) return '15-20 daqiqa';
    if (lower.contains('bola')) return '20-30 daqiqa';
    return '30-45 daqiqa';
  }

  bool get _canBook =>
      _selectedService != null &&
      _selectedStaffId != null &&
      _selectedTimeSlot != null &&
      !_loadingSlots;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingSlots = true;
      _selectedTimeSlot = null;
    });

    final availability = await _availabilityService.fetch(
      providerId: widget.shop.providerId,
      date: _selectedDate,
    );

    if (!mounted) return;
    setState(() {
      _timeSlots = availability.slots.isNotEmpty
          ? availability.slots
          : ProviderAvailability.defaultSlots;
      _bookedSlots = availability.booked;
      _loadingSlots = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            BookingSliverAppBar(color: _accent, icon: LucideIcons.scissors),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.shop.name,
                      rating: widget.shop.rating,
                      phone: widget.shop.phoneNumber,
                      accent: _accent,
                      extra: Text(
                        widget.shop.address,
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmatni tanlang'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: widget.shop.prices,
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: _accent,
                      format: currencyFormat,
                      subtitleOf: _serviceDuration,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Mutaxassisni tanlang'),
                    const SizedBox(height: 12),
                    SelectableStaffRow(
                      staff: _staffOptions,
                      selectedId: _selectedStaffId,
                      onSelect: (id) => setState(() => _selectedStaffId = id),
                      accent: _accent,
                      anyOptionLabel: 'Har qanday bo\'sh usta',
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Sana'),
                    const SizedBox(height: 12),
                    HorizontalDatePicker(
                      selectedDate: _selectedDate,
                      accentColor: _accent,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                        _loadAvailability();
                      },
                      daysCount: 14,
                      startDaysOffset: 1,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Vaqt'),
                    const SizedBox(height: 12),
                    if (_loadingSlots)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      )
                    else ...[
                      if (_bookedSlots.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${_bookedSlots.length} ta vaqt band',
                            style: TextStyle(
                              fontSize: 12,
                              color: GlassTokens.secondaryText(context),
                            ),
                          ),
                        ),
                      TimeSlotGrid(
                        timeSlots: _timeSlots,
                        selectedTimeSlot: _selectedTimeSlot,
                        accentColor: _accent,
                        onTimeSelected: (slot) =>
                            setState(() => _selectedTimeSlot = slot),
                        crossAxisCount: 5,
                        disabledTimeSlots: _bookedSlots,
                      ),
                    ],
                    const SizedBox(height: 32),
                    BookingActionBar(
                      accent: _accent,
                      primaryLabel: _canBook
                          ? 'Bron qilish — ${currencyFormat.format(_selectedPrice)}'
                          : 'Bron qilish',
                      onPrimary: _canBook ? _confirmBooking : null,
                      secondaryLabel: 'Qo\'ng\'iroq qilish',
                      secondaryIcon: LucideIcons.phone,
                      onSecondary: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.shop.phoneNumber} raqamiga bog\'lanilmoqda...',
                            ),
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

  Future<void> _confirmBooking() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted || !_canBook) return;

    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);
    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Bronni tasdiqlang',
      details: [
        MapEntry('Sartaroshxona', widget.shop.name),
        MapEntry('Mutaxassis', _staffLabel),
        MapEntry('Xizmat', _selectedService!),
        MapEntry(
          'Vaqt',
          '${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot',
        ),
      ],
      totalLabel: 'Jami',
      totalValue: currencyFormat.format(_selectedPrice),
      accent: _accent,
    );

    if (!confirmed || !mounted) return;

    final parts = _selectedTimeSlot!.split(':');
    final hour = int.tryParse(parts[0]) ?? 10;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.sartarosh,
      serviceName: '${widget.shop.name} — $_selectedService',
      providerName: widget.shop.name,
      variant: _selectedService!,
      address: widget.shop.address,
      notes: 'Mutaxassis: $_staffLabel',
      date: dateTime,
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.shop.providerId,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Muvaffaqiyatli band qilindi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buyurtma yuborib bo\'lmadi. Qayta urinib ko\'ring.'),
        ),
      );
    }
  }
}
