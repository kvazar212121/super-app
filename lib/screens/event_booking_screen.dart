import '../utils/call_helper.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event_planning.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class EventBookingScreen extends StatefulWidget {
  final EventPlanning service;
  final EventType? initialEventType;
  final OrganizerServiceType? initialOrganizerType;

  const EventBookingScreen({
    super.key,
    required this.service,
    this.initialEventType,
    this.initialOrganizerType,
  });

  @override
  State<EventBookingScreen> createState() => _EventBookingScreenState();
}

class _EventBookingScreenState extends State<EventBookingScreen> {
  EventType? _selectedEventType;
  String? _selectedPriceOption;
  String? _selectedVenue;
  final _guestCountController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedTimeSlot;

  late List<String> _timeSlots;

  @override
  void initState() {
    super.initState();
    _selectedEventType = widget.initialEventType;
    if (widget.initialOrganizerType != null) {
      final match = widget.service.prices.keys.where((k) {
        final label = widget.initialOrganizerType!.label.toLowerCase();
        return k.toLowerCase().contains(label.split(' ').first);
      });
      if (match.isNotEmpty) {
        _selectedPriceOption = match.first;
      }
    }
    _timeSlots = widget.service.timeSlots.isNotEmpty
        ? widget.service.timeSlots
        : [
            '10:00', '11:00', '12:00', '14:00', '15:00', '16:00',
            '17:00', '18:00', '19:00', '20:00',
          ];
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFEC4899);
    final currencyFormat =
        NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            BookingSliverAppBar(color: accentColor, icon: LucideIcons.partyPopper),
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
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 16, color: accentColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.service.serviceArea!,
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.service.teamSize > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Jamoa: ${widget.service.teamSize} kishi · ${widget.service.capabilitiesLabel}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SectionTitle('Tadbir turi'),
                    const SizedBox(height: 12),
                    SelectableIconGrid(
                      items: widget.service.eventTypes,
                      selected: _selectedEventType,
                      iconOf: (t) => t.icon,
                      labelOf: (t) => t.label,
                      onSelect: (t) => setState(() => _selectedEventType = t),
                      accent: accentColor,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Xizmat / narx'),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: widget.service.prices,
                      selected: _selectedPriceOption,
                      onSelect: (o) => setState(() => _selectedPriceOption = o),
                      accent: accentColor,
                      format: currencyFormat,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Mehmonlar soni'),
                    const SizedBox(height: 12),
                    BookingInputField(
                      controller: _guestCountController,
                      hint: 'Taxminiy mehmonlar soni',
                      icon: LucideIcons.users,
                      accent: accentColor,
                      keyboardType: TextInputType.number,
                      suffixText: 'kishi',
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Tadbir joyi'),
                    const SizedBox(height: 12),
                    _buildVenueSelector(accentColor),
                    const SizedBox(height: 24),
                    const SectionTitle('Aniq manzil (qishloq / hovli / maydon)'),
                    const SizedBox(height: 12),
                    BookingTextArea(
                      controller: _addressController,
                      hint: 'Viloyat, tuman, qishloq, ko\'cha yoki maydon nomi...',
                      icon: LucideIcons.mapPin,
                      accent: accentColor,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Qo\'shimcha ma\'lumot'),
                    const SizedBox(height: 12),
                    BookingTextArea(
                      controller: _descriptionController,
                      hint: 'Sahna o\'lchami, dastur, maxsus talablar...',
                      icon: LucideIcons.messageSquare,
                      accent: accentColor,
                    ),
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
                    Builder(builder: (context) {
                      final addressOk = _addressController.text.trim().length >= 5;
                      final canBook = _selectedEventType != null &&
                          _selectedPriceOption != null &&
                          _selectedTimeSlot != null &&
                          _selectedVenue != null &&
                          addressOk;
                      final totalPrice = _selectedPriceOption != null
                          ? widget.service.prices[_selectedPriceOption]
                          : null;
                      return BookingActionBar(
                        accent: accentColor,
                        primaryLabel: canBook
                            ? "Buyurtma berish — ${currencyFormat.format(totalPrice)}"
                            : 'Buyurtma berish',
                        onPrimary: canBook ? () => _confirmBooking(currencyFormat) : null,
                        secondaryLabel: 'Guruh bilan bog\'lanish',
                        secondaryIcon: LucideIcons.phone,
                        onSecondary: () {
                          CallHelper.makeDirectCall(context, 0, widget.service.name);
                        },
                      );
                    }),
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

  Widget _buildVenueSelector(Color color) {
    return Column(
      children: widget.service.venueLabels.map((venue) {
        final isSelected = _selectedVenue == venue;
        return GestureDetector(
          onTap: () => setState(() => _selectedVenue = venue),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  venue.toLowerCase().contains('qishloq') || venue.toLowerCase().contains('maydon')
                      ? LucideIcons.trees
                      : LucideIcons.mapPin,
                  color: isSelected ? color : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    venue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kBookingInk,
                    ),
                  ),
                ),
                if (isSelected) Icon(LucideIcons.check, color: color, size: 20),
              ],
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
            DetailRow(label: 'Guruh', value: widget.service.name),
            DetailRow(label: 'Tadbir turi', value: _selectedEventType!.label),
            DetailRow(label: 'Xizmat', value: _selectedPriceOption!),
            if (_guestCountController.text.isNotEmpty)
              DetailRow(
                label: 'Mehmonlar',
                value: '${_guestCountController.text} kishi',
              ),
            if (_selectedVenue != null) DetailRow(label: 'Joy turi', value: _selectedVenue!),
            DetailRow(label: 'Manzil', value: _addressController.text.trim()),
            if (_descriptionController.text.isNotEmpty)
              DetailRow(label: 'Izoh', value: _descriptionController.text),
            DetailRow(
              label: 'Vaqt',
              value: '${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot',
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
                    color: Color(0xFFEC4899),
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
                  final hour = int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 10;
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
                    category: ServiceHubKind.tadbirlar,
                    serviceName:
                        '${widget.service.name} — ${_selectedEventType!.label}',
                    providerName: widget.service.name,
                    providerId: widget.service.providerId > 0
                        ? widget.service.providerId
                        : null,
                    variant: _selectedPriceOption!,
                    address:
                        '${_selectedVenue ?? ''}: ${_addressController.text.trim()}',
                    notes:
                        'Mehmonlar: ${_guestCountController.text.trim()} kishi\n${_descriptionController.text.trim()}',
                    date: dateTime,
                    price: totalPrice ?? 500000.0,
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
