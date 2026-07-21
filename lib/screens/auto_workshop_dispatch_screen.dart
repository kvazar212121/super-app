import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/auto_workshop.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';

class AutoWorkshopDispatchScreen extends StatefulWidget {
  final AutoWorkshop workshop;

  const AutoWorkshopDispatchScreen({super.key, required this.workshop});

  @override
  State<AutoWorkshopDispatchScreen> createState() =>
      _AutoWorkshopDispatchScreenState();
}

class _AutoWorkshopDispatchScreenState
    extends State<AutoWorkshopDispatchScreen> {
  String? _selectedService;
  final _carCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final Color _accent = const Color(0xFF2563EB);

  double get _selectedPrice => _selectedService == null
      ? 0
      : (widget.workshop.prices[_selectedService] ?? 0);

  bool get _canSubmit => _selectedService != null;

  @override
  void dispose() {
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
    final car = _carCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final details = [
      MapEntry('Ustaxona', widget.workshop.name),
      MapEntry('Xizmat turi', _selectedService!),
      if (car.isNotEmpty) MapEntry('Mashina', car),
      MapEntry('Taxminiy sana', DateFormat('dd.MM.yyyy').format(_selectedDate)),
      if (notes.isNotEmpty) MapEntry('Muammo / Izoh', notes),
    ];

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Qabulga yozilishni tasdiqlang',
      details: details,
      totalLabel: 'Taxminiy narx',
      totalValue: currency.format(_selectedPrice),
      accent: _accent,
      confirmLabel: 'Yozilish',
    );
    if (!confirmed || !mounted) return;

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.avtoYordam,
      serviceName: '${widget.workshop.name} — $_selectedService',
      providerName: widget.workshop.name,
      variant: 'Ustaxona qabuliga',
      address: widget.workshop.address,
      notes: [
        if (car.isNotEmpty) 'Mashina: $car',
        if (notes.isNotEmpty) notes,
      ].join('. '),
      date: _selectedDate,
      price: _selectedPrice,
      status: OrderStatus.pending,
      providerId: widget.workshop.providerId > 0
          ? widget.workshop.providerId
          : null,
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'So\'rov yuborildi! ${widget.workshop.name} siz bilan tez orada aloqaga chiqadi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('So\'rov yuborib bo\'lmadi')),
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
          title: Text('Qabulga yozilish'.tr),
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
                      backgroundColor: _accent.withValues(alpha: 0.1),
                      child: Icon(LucideIcons.home, color: _accent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workshop.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.workshop.address,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
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
              if (widget.workshop.services.isEmpty)
                Text('Maxsus xizmatlar topilmadi.'.tr)
              else
                ...widget.workshop.services.map((service) {
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
                          if (widget.workshop.prices[service] != null &&
                              widget.workshop.prices[service]! > 0)
                            Text(
                              currency.format(widget.workshop.prices[service]),
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
              const SectionTitle('Mashina modeli (ixtiyoriy)'),
              const SizedBox(height: 12),
              BookingInputField(
                controller: _carCtrl,
                hint: 'Masalan: Cobalt, Malibu...',
                icon: LucideIcons.car,
                accent: _accent,
              ),
              const SizedBox(height: 24),
              const SectionTitle('Muammo / Izoh (ixtiyoriy)'),
              const SizedBox(height: 12),
              BookingTextArea(
                controller: _notesCtrl,
                hint: "Muammoni qisqacha yozib qoldiring...",
                icon: LucideIcons.messageSquare,
                accent: _accent,
              ),
              const SizedBox(height: 24),
              const SectionTitle('Taxminan qachon borasiz?'),
              const SizedBox(height: 12),
              HorizontalDatePicker(
                selectedDate: _selectedDate,
                accentColor: _accent,
                onDateSelected: (date) => setState(() => _selectedDate = date),
                daysCount: 14,
                startDaysOffset: 0,
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
                  child: const Text(
                    'Qabulga yozilish',
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
