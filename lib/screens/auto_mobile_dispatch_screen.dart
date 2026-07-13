import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/auto_mobile_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';

class AutoMobileDispatchScreen extends StatefulWidget {
  final AutoMobileService service;

  const AutoMobileDispatchScreen({super.key, required this.service});

  @override
  State<AutoMobileDispatchScreen> createState() =>
      _AutoMobileDispatchScreenState();
}

class _AutoMobileDispatchScreenState extends State<AutoMobileDispatchScreen> {
  String? _selectedService;
  final _locationCtrl = TextEditingController();
  final _carCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final Color _accent = const Color(0xFF2563EB);

  double get _selectedPrice => _selectedService == null
      ? 0
      : (widget.service.prices[_selectedService] ?? 0);

  bool get _canSubmit =>
      _selectedService != null && _locationCtrl.text.trim().length >= 5;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _carCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDispatch() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final currency = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );
    final location = _locationCtrl.text.trim();
    final car = _carCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final details = [
      MapEntry('Mutaxassis', widget.service.name),
      MapEntry('Xizmat turi', _selectedService!),
      MapEntry('Manzil (Lokatsiya)', location),
      if (car.isNotEmpty) MapEntry('Mashina', car),
      if (notes.isNotEmpty) MapEntry('Muammo', notes),
    ];

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Zudlik bilan chaqirish',
      details: details,
      totalLabel: 'Taxminiy narx',
      totalValue: currency.format(_selectedPrice),
      accent: _accent,
      confirmLabel: 'Chaqirish',
    );
    if (!confirmed || !mounted) return;

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.avtoYordam,
      serviceName: '${widget.service.name} — $_selectedService',
      providerName: widget.service.name,
      variant: 'Tezkor yordam',
      address: location,
      notes: [
        if (car.isNotEmpty) 'Mashina: $car',
        if (notes.isNotEmpty) notes,
      ].join('. '),
      date: DateTime.now(), // ASAP
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.service.providerId > 0
          ? widget.service.providerId
          : null,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chaqiruv qabul qilindi! ${widget.service.name} tez orada aloqaga chiqadi va yetib keladi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chaqiruv yuborib bo\'lmadi')),
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Joyiga chaqirish'.tr),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _accent.withOpacity(0.1),
                      child: Icon(
                        widget.service.vehicleType.icon,
                        color: _accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tezkor yordam',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Xizmat turini tanlang'),
              const SizedBox(height: 12),
              if (widget.service.services.isEmpty)
                Text('Maxsus xizmatlar topilmadi.'.tr)
              else
                ...widget.service.services.map((service) {
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
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (widget.service.prices[service] != null &&
                              widget.service.prices[service]! > 0)
                            Text(
                              currency.format(widget.service.prices[service]),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const SectionTitle('Joriy manzilingiz (Lokatsiya)'),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ko\'cha, mo\'ljal yoki xaritadan tanlang...',
                  prefixIcon: const Icon(LucideIcons.mapPin),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Mashina modeli (ixtiyoriy)'),
              const SizedBox(height: 12),
              BookingInputField(
                controller: _carCtrl,
                hint: 'Masalan: Cobalt, Malibu...',
                icon: LucideIcons.car,
                accent: _accent,
              ),
              const SizedBox(height: 24),
              const SectionTitle('Muammo haqida (ixtiyoriy)'),
              const SizedBox(height: 12),
              BookingTextArea(
                controller: _notesCtrl,
                hint: "Akkumulyator o'chgan, g'ildirak yorilgan...",
                icon: LucideIcons.siren,
                accent: _accent,
              ),
              const SizedBox(height: 40),
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
                  child: const Text(
                    'Zudlik bilan chaqirish',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
