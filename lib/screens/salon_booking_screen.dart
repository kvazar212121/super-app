import '../utils/call_helper.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/beauty_salon.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import '../theme/glass_tokens.dart';
import '../services/provider_availability_service.dart';
import 'package:super_app/l10n/locale_controller.dart';

class SalonBookingScreen extends StatefulWidget {
  final BeautySalon salon;

  const SalonBookingScreen({super.key, required this.salon});

  @override
  State<SalonBookingScreen> createState() => _SalonBookingScreenState();
}

class _SalonBookingScreenState extends State<SalonBookingScreen> {
  String? _selectedService;
  SalonStaff? _selectedStaff;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  final _serviceKey = GlobalKey();
  final _staffKey = GlobalKey();
  final _timeKey = GlobalKey();

  bool _loadingSlots = true;
  List<String> _timeSlots = ProviderAvailability.defaultSlots;
  List<String> _bookedSlots = [];
  final _availabilityService = ProviderAvailabilityService();

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

    int fetchProviderId = widget.salon.providerId;
    if (_selectedStaff != null && _selectedStaff!.providerId > 0) {
      fetchProviderId = _selectedStaff!.providerId;
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
    final accentColor = const Color(0xFFE91E63); // Pink for Salon
    final currencyFormat = NumberFormat.currency(
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
              color: accentColor,
              icon: LucideIcons.sparkles,
              rawJson: widget.salon.rawJson,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceProfileHeader(
                      name: widget.salon.name,
                      rating: widget.salon.rating,
                      phone: widget.salon.phoneNumber,
                      accent: accentColor,
                      extra: Text(
                        widget.salon.address,
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                          fontSize: 14,
                        ),
                      ),
                      onCallPressed: () {
                        CallHelper.makeDirectCall(
                          context,
                          widget.salon.ownerUserId,
                          widget.salon.name,
                        );
                      },
                      contactLabel: "Salon bilan bog'lanish",
                    ),
                    const SizedBox(height: 24),
                    SectionTitle("Xizmatni tanlang", key: _serviceKey),
                    const SizedBox(height: 12),
                    PriceOptionList(
                      prices: widget.salon.prices,
                      selected: _selectedService,
                      onSelect: (s) => setState(() => _selectedService = s),
                      accent: accentColor,
                      format: currencyFormat,
                    ),
                    const SizedBox(height: 24),
                    SectionTitle("Mutaxassisni tanlang", key: _staffKey),
                    const SizedBox(height: 12),
                    _buildStaffList(accentColor),
                    const SizedBox(height: 24),
                    const SectionTitle("Sana"),
                    const SizedBox(height: 12),
                    HorizontalDatePicker(
                      selectedDate: _selectedDate,
                      accentColor: accentColor,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                        _loadAvailability();
                      },
                      daysCount: 14,
                      startDaysOffset: 1,
                    ),
                    const SizedBox(height: 24),
                    SectionTitle("Vaqt", key: _timeKey),
                    const SizedBox(height: 12),
                    _loadingSlots
                        ? const Center(child: CircularProgressIndicator())
                        : TimeSlotGrid(
                            timeSlots: _timeSlots,
                            selectedTimeSlot: _selectedTimeSlot,
                            accentColor: accentColor,
                            disabledTimeSlots: _bookedSlots,
                            onTimeSelected: (slot) =>
                                setState(() => _selectedTimeSlot = slot),
                            crossAxisCount: 5,
                          ),
                    const SizedBox(height: 32),
                    Builder(
                      builder: (context) {
                        final canBook =
                            _selectedService != null &&
                            _selectedStaff != null &&
                            _selectedTimeSlot != null;
                        return BookingActionBar(
                          accent: accentColor,
                          primaryLabel: "Band qilish",
                          onPrimary: canBook ? _confirmBooking : null,
                          onPrimaryDisabled: () {
                            String msg =
                                'Iltimos, kerakli ma\'lumotlarni kiriting';
                            GlobalKey? targetKey;
                            if (_selectedService == null) {
                              msg = 'Iltimos, xizmat turini tanlang';
                              targetKey = _serviceKey;
                            } else if (_selectedStaff == null) {
                              msg = 'Iltimos, mutaxassisni tanlang';
                              targetKey = _staffKey;
                            } else if (_selectedTimeSlot == null) {
                              msg = 'Iltimos, bo\'sh vaqtni tanlang';
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

  Widget _buildStaffList(Color color) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.salon.staff.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final st = widget.salon.staff[index];
          final isSelected = _selectedStaff?.id == st.id;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedStaff = st);
              _loadAvailability();
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isSelected ? color : Colors.pink[50],
                  child: Icon(
                    LucideIcons.user,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  st.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? color
                        : GlassTokens.primaryText(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmBooking() async {
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
              "Band qilishni tasdiqlang",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DetailRow(label: "Salon", value: widget.salon.name),
            DetailRow(label: "Mutaxassis", value: _selectedStaff!.name),
            DetailRow(label: "Xizmat", value: _selectedService!),
            DetailRow(
              label: "Vaqt",
              value:
                  "${DateFormat('dd.MM.yyyy').format(_selectedDate)} $_selectedTimeSlot",
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final hour =
                      int.tryParse(_selectedTimeSlot!.split(':')[0]) ?? 10;
                  final minute =
                      int.tryParse(_selectedTimeSlot!.split(':')[1]) ?? 0;
                  final dateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                    minute,
                  );

                  int orderProviderId = widget.salon.providerId;
                  if (_selectedStaff != null &&
                      _selectedStaff!.providerId > 0) {
                    orderProviderId = _selectedStaff!.providerId;
                  }

                  final order = ServiceOrder(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    category: ServiceHubKind.salon,
                    serviceName: '${widget.salon.name} — $_selectedService',
                    providerName: widget.salon.name,
                    variant: _selectedService!,
                    address: widget.salon.address,
                    notes: 'Mutaxassis: ${_selectedStaff!.name}',
                    date: dateTime,
                    price: widget.salon.prices[_selectedService] ?? 80000.0,
                    status: OrderStatus.pending,
                    providerId: orderProviderId,
                  );

                  context.read<AppProvider>().addOrder(order);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Muvaffaqiyatli band qilindi!".tr),
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
                  "Tasdiqlash",
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
