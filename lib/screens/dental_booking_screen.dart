import '../utils/call_helper.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dental_clinic.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/provider_availability_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';

class DentalBookingScreen extends StatefulWidget {
  final DentalClinic clinic;
  final String? preselectedService;

  const DentalBookingScreen({
    super.key,
    required this.clinic,
    this.preselectedService,
  });

  @override
  State<DentalBookingScreen> createState() => _DentalBookingScreenState();
}

class _DentalBookingScreenState extends State<DentalBookingScreen> {
  final _availability = ProviderAvailabilityService();
  final _patientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedService;
  DentalDentist? _selectedDentist;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  bool _loadingSlots = true;

  static const _accent = Color(0xFF0EA5E9);

  double get _price => _selectedService == null
      ? 0
      : (widget.clinic.prices[_selectedService] ?? 100000);

  bool get _canBook =>
      _selectedService != null &&
      _selectedTimeSlot != null &&
      _patientCtrl.text.trim().length >= 2 &&
      !_loadingSlots;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService;
    if (widget.clinic.dentists.isNotEmpty) {
      _selectedDentist = widget.clinic.dentists.first;
    }
    _patientCtrl.addListener(() => setState(() {}));
    _loadAvailability();
  }

  @override
  void dispose() {
    _patientCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loadingSlots = true);
    if (widget.clinic.providerId <= 0) {
      _timeSlots = widget.clinic.timeSlots.isNotEmpty
          ? widget.clinic.timeSlots
          : ProviderAvailability.defaultSlots;
    } else {
      final avail = await _availability.fetch(
        providerId: widget.clinic.providerId,
        date: _selectedDate,
      );
      _timeSlots = avail.slots.isNotEmpty
          ? avail.slots
          : (widget.clinic.timeSlots.isNotEmpty
              ? widget.clinic.timeSlots
              : ProviderAvailability.defaultSlots);
    }
    if (mounted) {
      setState(() {
        _loadingSlots = false;
        if (_selectedTimeSlot != null && !_timeSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
      });
    }
  }

  Future<void> _confirm() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;

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
      category: ServiceHubKind.stomatologiya,
      serviceName: '${widget.clinic.name} — $_selectedService',
      providerName: widget.clinic.name,
      variant: _selectedService!,
      address: widget.clinic.address,
      notes:
          'Bemor: ${_patientCtrl.text.trim()}${_selectedDentist != null ? '\nShifokor: ${_selectedDentist!.name}' : ''}${_notesCtrl.text.trim().isNotEmpty ? '\n${_notesCtrl.text.trim()}' : ''}',
      date: dateTime,
      price: _price,
      status: OrderStatus.pending,
      providerId: widget.clinic.providerId > 0 ? widget.clinic.providerId : null,
    );

    context.read<AppProvider>().addOrder(order);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Qabul vaqti band qilindi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

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
              icon: LucideIcons.smile,
              rawJson: widget.clinic.rawJson,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.clinic.name,
                      rating: widget.clinic.rating,
                      phone: widget.clinic.phoneNumber,
                      accent: _accent,
                      onCallPressed: () {
                        CallHelper.makeDirectCall(context, widget.clinic.ownerUserId, widget.clinic.name);
                      },
                      contactLabel: "Klinika bilan bog'lanish",
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 16, color: _accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.clinic.address,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmat'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: widget.clinic.prices,
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: _accent,
                      format: currency,
                    ),
                    if (widget.clinic.dentists.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionTitle('Stomatolog'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.clinic.dentists.map((d) {
                          final selected = _selectedDentist?.name == d.name;
                          return FilterChip(
                            label: Text('${d.name} (${d.specialty})'),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedDentist = d),
                            selectedColor: _accent,
                            checkmarkColor: _accent,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SectionTitle('Bemor ismi'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _patientCtrl,
                      hint: 'Ism familiya',
                      icon: LucideIcons.user,
                      accent: _accent,
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
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else
                      TimeSlotGrid(
                        timeSlots: _timeSlots,
                        selectedTimeSlot: _selectedTimeSlot,
                        accentColor: _accent,
                        onTimeSelected: (slot) => setState(() => _selectedTimeSlot = slot),
                        crossAxisCount: 4,
                      ),
                    const SizedBox(height: 32),
                    BookingActionBar(
                      accent: _accent,
                      primaryLabel: _canBook
                          ? 'Band qilish — ${currency.format(_price)}'
                          : 'Band qilish',
                      onPrimary: _canBook ? _confirm : null,
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
}
