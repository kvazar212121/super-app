import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/disinfection_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class DisinfectionDispatchScreen extends StatefulWidget {
  final DisinfectionService service;

  const DisinfectionDispatchScreen({super.key, required this.service});

  @override
  State<DisinfectionDispatchScreen> createState() =>
      _DisinfectionDispatchScreenState();
}

class _DisinfectionDispatchScreenState
    extends State<DisinfectionDispatchScreen> {
  AreaType? _selectedAreaType;
  final _addressCtrl = TextEditingController();
  final _areaSizeCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final Color _accent = const Color(0xFFB8921F); // Emerald

  bool get _canSubmit =>
      _selectedAreaType != null &&
      _addressCtrl.text.trim().length >= 5 &&
      _areaSizeCtrl.text.trim().isNotEmpty &&
      double.tryParse(_areaSizeCtrl.text.trim()) != null;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _areaSizeCtrl.dispose();
    _problemCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDispatch() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final address = _addressCtrl.text.trim();
    final areaSize = _areaSizeCtrl.text.trim();
    final problem = _problemCtrl.text.trim();

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Dezinfeksiyaga chaqirishni tasdiqlang',
      details: [
        MapEntry('Xizmat ko\'rsatuvchi', widget.service.name),
        MapEntry('Obyekt turi', _selectedAreaType!.label),
        MapEntry('Maydon', '$areaSize m²'),
        MapEntry(
          'Taxminiy sana',
          DateFormat('dd.MM.yyyy').format(_selectedDate),
        ),
        MapEntry('Manzil', address),
        if (problem.isNotEmpty) MapEntry('Muammo', problem),
      ],
      totalLabel: 'Hisob-kitob',
      totalValue: 'Kelishiladi',
      accent: _accent,
      confirmLabel: 'Obyektga chaqirish',
    );
    if (!confirmed || !mounted) return;

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.dezinfeksiya,
      serviceName: '${widget.service.name} — ${_selectedAreaType!.label}',
      providerName: widget.service.name,
      variant: 'Obyektga chaqiruv',
      address: address,
      notes: 'Maydon: $areaSize m²\nMuammo: $problem',
      date: _selectedDate,
      price: 0, // Real price is calculated after inspection or phone call
      status: OrderStatus.pending,
      providerId: int.tryParse(widget.service.id),
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dezinfeksiya xizmati chaqirildi! ${widget.service.name} tez orada aloqaga chiqadi.',
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
    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Obyektga chaqirish'.tr),
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
                        LucideIcons.shieldCheck,
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
                            'Dezinfeksiya xizmati',
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
              SelectableIconGrid<AreaType>(
                items: widget.service.areaTypes,
                selected: _selectedAreaType,
                iconOf: (t) => t.icon,
                labelOf: (t) => t.label,
                onSelect: (t) => setState(() => _selectedAreaType = t),
                accent: _accent,
              ),
              const SizedBox(height: 24),
              const SectionTitle('Maydon hajmi (m²)'),
              const SizedBox(height: 12),
              BookingInputField(
                controller: _areaSizeCtrl,
                hint: 'Masalan: 120',
                icon: LucideIcons.ruler,
                accent: _accent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: 'm²',
                onChanged: (_) => setState(() {}),
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
              const SectionTitle('Muammoni kiritish (ixtiyoriy)'),
              const SizedBox(height: 12),
              BookingTextArea(
                controller: _problemCtrl,
                hint: "Tarakan, hasharotlar, viruslar...",
                icon: LucideIcons.bug,
                accent: _accent,
              ),
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
                    foregroundColor: Colors.white,
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
