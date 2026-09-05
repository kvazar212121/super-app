import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/appliance_repair.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class ApplianceDispatchScreen extends StatefulWidget {
  final ApplianceRepair service;

  const ApplianceDispatchScreen({super.key, required this.service});

  @override
  State<ApplianceDispatchScreen> createState() =>
      _ApplianceDispatchScreenState();
}

class _ApplianceDispatchScreenState extends State<ApplianceDispatchScreen> {
  ApplianceType? _selectedApplianceType;
  final _addressCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();

  final Color _accent = LuxTokens.textMuted;

  bool get _canSubmit =>
      _selectedApplianceType != null &&
      _addressCtrl.text.trim().length >= 5 &&
      _problemCtrl.text.trim().length >= 3;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _problemCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDispatch() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final address = _addressCtrl.text.trim();
    final problem = _problemCtrl.text.trim();

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Uyga chaqirishni tasdiqlang',
      details: [
        MapEntry('Mutaxassis', widget.service.name),
        MapEntry('Texnika turi', _selectedApplianceType!.label),
        MapEntry('Manzil', address),
        MapEntry('Muammo', problem),
      ],
      totalLabel: 'Tashxis narxi',
      totalValue: 'Kelishiladi',
      accent: _accent,
      confirmLabel: 'Chaqirish',
    );
    if (!confirmed || !mounted) return;

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.texnikaUstasi,
      serviceName: '${widget.service.name} — ${_selectedApplianceType!.label}',
      providerName: widget.service.name,
      variant: 'Uyga chaqiruv',
      address: address,
      notes: 'Muammo: $problem',
      date: DateTime.now(), // Real time is not specified
      price: 0, // Real price is negotiated
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
            'Texnika ustasi chaqirildi! ${widget.service.name} tez orada aloqaga chiqadi.',
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
          title: Text('Ustani uyga chaqirish'.tr),
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
                      child: Icon(LucideIcons.wrench, color: _accent, size: 24),
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
                            'Texnika ustasi',
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
              const SectionTitle('Texnika turini tanlang'),
              const SizedBox(height: 12),
              SelectableIconGrid<ApplianceType>(
                items: widget.service.applianceTypes,
                selected: _selectedApplianceType,
                iconOf: (t) => t.icon,
                labelOf: (t) => t.label,
                onSelect: (t) => setState(() => _selectedApplianceType = t),
                accent: _accent,
              ),
              const SizedBox(height: 24),
              const SectionTitle('Qayerga keladi?'),
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
              const SectionTitle('Muammoni qisqacha yozing'),
              const SizedBox(height: 12),
              BookingTextArea(
                controller: _problemCtrl,
                hint: "Muzlatgich sovitmayapti...",
                icon: LucideIcons.messageSquare,
                accent: _accent,
                onChanged: (_) => setState(() {}),
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
                    'Ustani chaqirish',
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
