import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'provider_profile_screen.dart';
import 'map_address_picker_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

/// Usta / mobil mutaxassisni vaqtga chaqirish — mijoz manzili bilan.
class MasterDispatchScreen extends StatefulWidget {
  final Master master;
  final ServiceHubKind category;

  const MasterDispatchScreen({
    super.key,
    required this.master,
    this.category = ServiceHubKind.usta,
  });

  @override
  State<MasterDispatchScreen> createState() => _MasterDispatchScreenState();
}

class _MasterDispatchScreenState extends State<MasterDispatchScreen> {
  final _availability = ProviderAvailabilityService();
  final _addressCtrl = TextEditingController();

  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  bool _loadingSlots = true;

  Color get _accent => widget.category.accent;

  bool get _isAppointment {
    final cat = _resolveCategory().name;
    return cat == 'massajHijoma' || cat == 'salon' || cat == 'sartarosh';
  }

  double get _selectedPrice {
    if (_selectedService == null) return 0.0;
    final base = (widget.master.prices[_selectedService] ?? 100000).toDouble();
    final travel = widget.master.isTravelFeeIncluded
        ? 0.0
        : widget.master.travelFee;
    return base + travel;
  }

  bool get _canSubmit =>
      _selectedService != null &&
      _selectedTimeSlot != null &&
      _addressCtrl.text.trim().length >= 5 &&
      !_loadingSlots;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loadingSlots = true);
    if (widget.master.providerId <= 0) {
      _timeSlots = ProviderAvailability.defaultSlots;
      _bookedSlots = [];
    } else {
      final avail = await _availability.fetch(
        providerId: widget.master.providerId,
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

  ServiceHubKind _resolveCategory() {
    if (widget.master.isHomeVisit) return ServiceHubKind.sartarosh;
    final specialty = widget.master.specialty.toLowerCase();
    if (specialty.contains('elek')) return ServiceHubKind.elektrik;
    if (specialty.contains('sant')) return ServiceHubKind.santexnik;
    if (specialty.contains('toza')) return ServiceHubKind.tozalash;
    if (specialty.contains('kosmet') || specialty.contains('mobil kos')) {
      return ServiceHubKind.salon;
    }
    if (specialty.contains('avto') || specialty.contains('ko\'chir')) {
      return ServiceHubKind.avtoYordam;
    }
    // Konditsioner endi alohida kategoriya emas — texnika ustasi ichida.
    if (specialty.contains('kond')) return ServiceHubKind.texnikaUstasi;
    if (specialty.contains('enag')) return ServiceHubKind.enaga;
    if (specialty.contains('repa') || specialty.contains('repet')) {
      return ServiceHubKind.repetitor;
    }
    return widget.category;
  }

  Future<void> _confirmDispatch() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );
    final address = _addressCtrl.text.trim();
    final confirmed = await showBookingConfirmSheet(
      context,
      title: widget.master.isHomeVisit
          ? 'Bronni tasdiqlang'
          : 'Chaqiruvni tasdiqlang',
      details: [
        MapEntry('Mutaxassis', widget.master.name),
        MapEntry('Xizmat', _selectedService!),
        MapEntry('Sana', DateFormat('dd.MM.yyyy').format(_selectedDate)),
        MapEntry(
          "Yo'l kira",
          widget.master.isTravelFeeIncluded
              ? "Bepul (narx ichida)"
              : currency.format(widget.master.travelFee),
        ),
        MapEntry('Vaqt', _selectedTimeSlot!),
        MapEntry('Manzil', address),
      ],
      totalLabel: 'Jami',
      totalValue: currency.format(_selectedPrice),
      accent: _accent,
      confirmLabel: _isAppointment
          ? 'Yozilish'
          : widget.master.isCleaner ||
                widget.master.isElectrician ||
                widget.master.isPlumber ||
                widget.master.isAcTechnician ||
                widget.master.isDispatchMaster
          ? 'Chaqirish'
          : (widget.master.isHomeVisit ? 'Bron qilish' : 'Chaqirish'),
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

    final category = _resolveCategory();
    final visitNote = widget.master.isHomeVisit
        ? 'Uyga borish'
        : 'Usta chaqiruv';

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: category,
      serviceName: '${widget.master.name} — $_selectedService',
      providerName: widget.master.name,
      variant: _selectedService!,
      address: address,
      notes: '$visitNote · ${widget.master.specialty}',
      date: dateTime,
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.master.providerId > 0
          ? widget.master.providerId
          : null,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAppointment
                ? 'Qabulga yozildingiz! ${widget.master.name} sizni kutadi.'
                : widget.master.isCleaner
                ? 'Buyurtma qabul qilindi! ${widget.master.name} belgilangan vaqtda keladi.'
                : widget.master.isDispatchMaster
                ? 'Usta chaqirildi! ${widget.master.name} belgilangan vaqtda keladi.'
                : widget.master.isElectrician
                ? 'Elektrik chaqirildi! ${widget.master.name} belgilangan vaqtda keladi.'
                : widget.master.isPlumber
                ? 'Santexnik chaqirildi! ${widget.master.name} belgilangan vaqtda keladi.'
                : widget.master.isAcTechnician
                ? 'Konditsioner chaqirildi! ${widget.master.name} belgilangan vaqtda keladi.'
                : widget.master.isHomeVisit
                ? 'Bron qilindi! ${widget.master.name} belgilangan vaqtda keladi.'
                : 'Usta chaqirildi! Tez orada bog\'lanadi.',
          ),
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

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            BookingSliverAppBar(
              color: _accent,
              icon: widget.master.isCleaner
                  ? LucideIcons.brush
                  : widget.master.isElectrician
                  ? LucideIcons.zap
                  : widget.master.isPlumber
                  ? LucideIcons.droplets
                  : widget.master.isAcTechnician
                  ? LucideIcons.wind
                  : _isAppointment
                  ? LucideIcons.heartPulse
                  : LucideIcons.wrench,
              expandedHeight: 160,
              rawJson: widget.master.rawJson,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.user),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: widget.master,
                        category: _resolveCategory(),
                      ),
                    ),
                  ),
                ),
              ],
              title: Text(
                _isAppointment
                    ? 'Qabulga yozilish'
                    : widget.master.isCleaner
                    ? 'Tozalash buyurtmasi'
                    : widget.master.isDispatchMaster
                    ? 'Ustani chaqirish'
                    : widget.master.isElectrician
                    ? 'Elektrikni chaqirish'
                    : widget.master.isPlumber
                    ? 'Santexnikni chaqirish'
                    : widget.master.isAcTechnician
                    ? 'Konditsionerni chaqirish'
                    : (widget.master.isHomeVisit
                          ? 'Uyga chaqirish'
                          : 'Ustani chaqirish'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    const SectionTitle('Qayerga keladi?'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Ko\'cha, uy, orientir...',
                              prefixIcon: const Icon(LucideIcons.mapPin),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _accent, width: 1.5),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.map, color: _accent),
                            onPressed: () async {
                              final picked = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MapAddressPickerScreen(),
                                ),
                              );
                              if (picked != null && picked.isNotEmpty) {
                                _addressCtrl.text = picked;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmat turi'),
                    const SizedBox(height: 12),
                    ...widget.master.services.map((service) {
                      final selected = _selectedService == service;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedService = service),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? _accent : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? _accent : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : LuxTokens.text,
                                  ),
                                ),
                              ),
                              Text(
                                currency.format(
                                  widget.master.prices[service] ?? 0,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : LuxTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const SectionTitle('Sana'),
                    const SizedBox(height: 12),
                    HorizontalDatePicker(
                      selectedDate: _selectedDate,
                      accentColor: _accent,
                      onDateSelected: (d) {
                        setState(() => _selectedDate = d);
                        _loadAvailability();
                      },
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
                        timeSlots: _timeSlots,
                        selectedTimeSlot: _selectedTimeSlot,
                        disabledTimeSlots: _bookedSlots,
                        accentColor: _accent,
                        onTimeSelected: (s) =>
                            setState(() => _selectedTimeSlot = s),
                        crossAxisCount: 4,
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _canSubmit ? _confirmDispatch : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isAppointment
                              ? 'Qabulga yozilish'
                              : widget.master.isCleaner ||
                                    widget.master.isElectrician ||
                                    widget.master.isPlumber ||
                                    widget.master.isAcTechnician ||
                                    widget.master.isDispatchMaster
                              ? 'Chaqirish'
                              : (widget.master.isHomeVisit
                                    ? 'Bron qilish'
                                    : 'Ustani chaqirish'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: _accent,
          child: Icon(widget.category.icon, color: _accent, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.master.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.master.specialty,
                style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.master.rating} (${widget.master.reviewCount})',
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(
                master: widget.master,
                category: _resolveCategory(),
              ),
            ),
          ),
          child: Text('Profil'.tr),
        ),
      ],
    );
  }
}
