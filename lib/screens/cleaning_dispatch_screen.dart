import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/master_worker.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class CleaningDispatchScreen extends StatefulWidget {
  final Master master;
  final ServiceHubKind category;

  const CleaningDispatchScreen({
    super.key,
    required this.master,
    this.category = ServiceHubKind.tozalash,
  });

  @override
  State<CleaningDispatchScreen> createState() => _CleaningDispatchScreenState();
}

class _CleaningDispatchScreenState extends State<CleaningDispatchScreen> {
  String? _selectedAreaType;
  String? _selectedService;
  final _addressCtrl = TextEditingController();
  final _areaSizeCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _areaTypes = ['Kvartira', 'Hovli uyi', 'Ofis', 'Boshqa'];
  final Color _accent = LuxTokens.gold;

  double get _selectedPrice => _selectedService == null
      ? 0
      : (widget.master.prices[_selectedService] ?? 0);

  bool get _canSubmit =>
      _selectedAreaType != null &&
      _selectedService != null &&
      _addressCtrl.text.trim().length >= 5 &&
      _areaSizeCtrl.text.trim().isNotEmpty &&
      double.tryParse(_areaSizeCtrl.text.trim()) != null;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _areaSizeCtrl.dispose();
    _roomsCtrl.dispose();
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
    final address = _addressCtrl.text.trim();
    final areaSize = _areaSizeCtrl.text.trim();
    final rooms = _roomsCtrl.text.trim();

    final details = [
      MapEntry('Tozalash xizmati', widget.master.name),
      MapEntry('Xizmat turi', _selectedService!),
      MapEntry('Obyekt turi', _selectedAreaType!),
      MapEntry(
        'Maydon',
        '$areaSize m²${rooms.isNotEmpty ? ' ($rooms xona)' : ''}',
      ),
      MapEntry('Taxminiy sana', DateFormat('dd.MM.yyyy').format(_selectedDate)),
      MapEntry('Manzil', address),
    ];

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Tozalashga chaqirishni tasdiqlang',
      details: details,
      totalLabel: 'Hisob-kitob',
      totalValue: 'Kelishiladi',
      accent: _accent,
      confirmLabel: 'Obyektga chaqirish',
    );
    if (!confirmed || !mounted) return;

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.tozalash,
      serviceName: '${widget.master.name} — $_selectedService',
      providerName: widget.master.name,
      variant: 'Obyektga chaqiruv',
      address: address,
      notes:
          'Obyekt: $_selectedAreaType, $areaSize m²\nXonalar: ${rooms.isEmpty ? "kiritilmagan" : rooms}',
      date: _selectedDate,
      price: _selectedPrice, // Can be base price or 0
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
            'Tozalash xizmati chaqirildi! ${widget.master.name} tez orada aloqaga chiqadi.',
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Tozalashga chaqirish'.tr),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuxTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _accent.withValues(alpha: 0.1),
                      child: Icon(
                        LucideIcons.sprayCan,
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
                            widget.master.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.master.specialty,
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
              const SectionTitle('Obyekt turini tanlang'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _areaTypes.map((type) {
                  final isSelected = _selectedAreaType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _selectedAreaType = val ? type : null),
                    selectedColor: _accent.withValues(alpha: 0.2),
                    backgroundColor: LuxTokens.surface,
                    side: BorderSide(
                      color: isSelected ? _accent : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? _accent : LuxTokens.text,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Maydon hajmi (m²)'),
                        const SizedBox(height: 12),
                        BookingInputField(
                          controller: _areaSizeCtrl,
                          hint: 'Mas: 80',
                          icon: LucideIcons.ruler,
                          accent: _accent,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffixText: 'm²',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Xonalar soni'),
                        const SizedBox(height: 12),
                        BookingInputField(
                          controller: _roomsCtrl,
                          hint: 'Mas: 3',
                          icon: LucideIcons.doorOpen,
                          accent: _accent,
                          keyboardType: TextInputType.number,
                          suffixText: 'xona',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle('Manzil (Qayerga keladi?)'),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ko\'cha, uy, orientir...',
                  prefixIcon: const Icon(LucideIcons.mapPin),
                  filled: true,
                  fillColor: LuxTokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Tozalash turi'),
              const SizedBox(height: 12),
              if (widget.master.services.isEmpty)
                Text('Maxsus xizmatlar topilmadi.'.tr)
              else
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
                                color: selected ? _accent : LuxTokens.text,
                              ),
                            ),
                          ),
                          if (widget.master.prices[service] != null &&
                              widget.master.prices[service]! > 0)
                            Text(
                              currency.format(widget.master.prices[service]),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected ? _accent : LuxTokens.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const SectionTitle('Qachon kelgani ma\'qul?'),
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
                    'Obyektga chaqirish',
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
