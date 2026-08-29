import '../utils/call_helper.dart';
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
import '../widgets/save_provider_button.dart';
import 'package:super_app/l10n/locale_controller.dart';

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
  String _selectedBookingMode = 'fixed';

  final _serviceKey = GlobalKey();
  final _staffKey = GlobalKey();
  final _timeKey = GlobalKey();

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
          providerId: b.providerId,
        ),
      )
      .toList();

  String get _staffLabel {
    if (_selectedStaffId == null) return '';
    if (_selectedStaffId == _anyStaffId) return 'Har qanday bo\'sh usta'.tr;
    final match = widget.shop.barbers.where((b) => b.id == _selectedStaffId);
    return match.isEmpty ? 'Har qanday bo\'sh usta'.tr : match.first.name;
  }

  double get _selectedPrice => _selectedService == null
      ? 0
      : (widget.shop.prices[_selectedService] ??
            BarberShop.defaultPriceForService(_selectedService!));

  String _serviceDuration(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('soqol')) return '15-20 daqiqa'.tr;
    if (lower.contains('bola')) return '20-30 daqiqa'.tr;
    return '30-45 daqiqa'.tr;
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

    int fetchProviderId = widget.shop.providerId;
    if (_selectedStaffId != null && _selectedStaffId != _anyStaffId) {
      final match = widget.shop.barbers.where((b) => b.id == _selectedStaffId);
      if (match.isNotEmpty && match.first.providerId > 0) {
        fetchProviderId = match.first.providerId;
      }
    }

    final availability = await _availabilityService.fetch(
      providerId: fetchProviderId,
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
    final currencyFormat = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m'.tr,
      decimalDigits: 0,
    );

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: true,
          child: CustomScrollView(
            slivers: [
              BookingSliverAppBar(
                color: _accent,
                icon: LucideIcons.scissors,
                rawJson: widget.shop.rawJson,
              ),
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
                        onCallPressed: () {
                          CallHelper.makeDirectCall(
                            context,
                            widget.shop.ownerUserId,
                            widget.shop.name,
                            asOrder: true,
                          );
                        },
                        contactLabel: "Sartaroshxona bilan bog'lanish".tr,
                      ),
                      const SizedBox(height: 24),
                      SectionTitle('Xizmatni tanlang'.tr, key: _serviceKey),
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
                      SectionTitle('Mutaxassisni tanlang'.tr, key: _staffKey),
                      const SizedBox(height: 12),
                      SelectableStaffRow(
                        staff: _staffOptions,
                        selectedId: _selectedStaffId,
                        onSelect: (id) {
                          setState(() => _selectedStaffId = id);
                          _loadAvailability();
                        },
                        accent: _accent,
                        anyOptionLabel: 'Har qanday bo\'sh usta'.tr,
                      ),
                      const SizedBox(height: 24),
                      SectionTitle('Sana'.tr),
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
                      SectionTitle('Vaqt'.tr, key: _timeKey),
                      const SizedBox(height: 12),
                      if (_loadingSlots)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        if (_bookedSlots.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${_bookedSlots.length} ${'ta vaqt band'.tr}',
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
                      const SizedBox(height: 24),
                      // ──── Navbat rejimi tanlash ────
                      SectionTitle('Navbat rejimi'.tr),
                      const SizedBox(height: 12),
                      _buildQueueModeSelector(),
                      const SizedBox(height: 32),
                      BookingActionBar(
                        accent: _accent,
                        primaryLabel: _canBook
                            ? '${'Bron qilish'.tr} — ${currencyFormat.format(_selectedPrice)}'
                            : 'Bron qilish'.tr,
                        onPrimary: _canBook ? _confirmBooking : null,
                        onPrimaryDisabled: () {
                          String msg =
                              'Iltimos, kerakli ma\'lumotlarni kiriting'.tr;
                          GlobalKey? targetKey;
                          if (_selectedService == null) {
                            msg = 'Iltimos, xizmat turini tanlang'.tr;
                            targetKey = _serviceKey;
                          } else if (_selectedStaffId == null) {
                            msg = 'Iltimos, mutaxassisni tanlang'.tr;
                            targetKey = _staffKey;
                          } else if (_selectedTimeSlot == null) {
                            msg = 'Iltimos, bo\'sh vaqtni tanlang'.tr;
                            targetKey = _timeKey;
                          }

                          if (targetKey != null &&
                              targetKey.currentContext != null) {
                            Scrollable.ensureVisible(
                              targetKey.currentContext!,
                              alignment: 0.5,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      SaveProviderButton(
                        id: widget.shop.id,
                        categoryKey: ServiceHubKind.sartarosh.name,
                        name: widget.shop.name,
                        address: widget.shop.address,
                        rating: widget.shop.rating,
                        type: 'barber_shop',
                        rawJson:
                            widget.shop.rawJson ?? const <String, dynamic>{},
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

  Widget _buildQueueModeSelector() {
    final modes = [
      {
        'key': 'fixed',
        'icon': LucideIcons.clock,
        'title': 'Aniq vaqt'.tr,
        'desc': 'Belgilangan vaqtda qabul qilinadi'.tr,
      },
      {
        'key': 'flexible',
        'icon': LucideIcons.zap,
        'title': 'Tezkor navbat'.tr,
        'desc':
            'Usta bo\'shashiga qarab vaqtingiz oldinga surilishi mumkin'.tr,
      },
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: modes.map((m) {
          final key = m['key'] as String;
          final isSelected = _selectedBookingMode == key;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: key == 'fixed' ? 6 : 0,
                left: key == 'flexible' ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _accent : kBookingCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _accent : kBookingBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _accent,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedBookingMode = key),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(0xFFF2F2F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              m['icon'] as IconData,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B6B68),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m['title'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0A0A0B),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              LucideIcons.circleCheck,
                              size: 20,
                              color: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['desc'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF6B6B68),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted || !_canBook) return;

    final currencyFormat = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m'.tr,
      decimalDigits: 0,
    );
    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Bronni tasdiqlang'.tr,
      details: [
        MapEntry('Sartaroshxona'.tr, widget.shop.name),
        MapEntry('Mutaxassis'.tr, _staffLabel),
        MapEntry('Xizmat'.tr, _selectedService!),
        MapEntry(
          'Vaqt'.tr,
          '${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot',
        ),
        MapEntry(
          'Navbat rejimi'.tr,
          _selectedBookingMode == 'flexible'
              ? 'Tezkor navbat ⚡'.tr
              : 'Aniq vaqt 🕐'.tr,
        ),
      ],
      totalLabel: 'Jami'.tr,
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

    int orderProviderId = widget.shop.providerId;
    if (_selectedStaffId != null && _selectedStaffId != _anyStaffId) {
      final match = widget.shop.barbers.where((b) => b.id == _selectedStaffId);
      if (match.isNotEmpty && match.first.providerId > 0) {
        orderProviderId = match.first.providerId;
      }
    }

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
      providerId: orderProviderId,
      bookingMode: _selectedBookingMode,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Muvaffaqiyatli band qilindi!'.tr),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Buyurtma yuborib bo\'lmadi. Xato:'.tr} $e'),
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
