import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/courier_service.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/auth_guard.dart';
import '../widgets/booking_common_widgets.dart';
import '../widgets/glass/mesh_background.dart';

class CourierDispatchScreen extends StatefulWidget {
  final CourierService service;

  const CourierDispatchScreen({super.key, required this.service});

  @override
  State<CourierDispatchScreen> createState() => _CourierDispatchScreenState();
}

class _CourierDispatchScreenState extends State<CourierDispatchScreen> {
  DeliveryType? _selectedDeliveryType;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  final Color _accent = const Color(0xFF6366F1); // Indigo

  bool get _canSubmit =>
      _selectedDeliveryType != null &&
      _fromController.text.trim().length >= 5 &&
      _toController.text.trim().length >= 5;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmDispatch() async {
    if (!await ensureAuthenticated(context)) return;
    if (!_canSubmit || !mounted) return;

    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final weight = _weightController.text.trim();
    final notes = _notesController.text.trim();

    final details = [
      MapEntry('Kuryer', widget.service.name),
      MapEntry('Qayerdan', from),
      MapEntry('Qayerga', to),
      MapEntry('Yuk turi', _selectedDeliveryType!.label),
      if (weight.isNotEmpty) MapEntry('Taxminiy vazn', '$weight kg'),
      if (notes.isNotEmpty) MapEntry('Izoh', notes),
    ];

    final confirmed = await showBookingConfirmSheet(
      context,
      title: 'Kuryerni yollash',
      details: details,
      totalLabel: 'Xizmat narxi',
      totalValue: 'Masofaga qarab kelishiladi',
      accent: _accent,
      confirmLabel: 'Buyurtma berish',
    );
    if (!confirmed || !mounted) return;

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: ServiceHubKind.kuryerlik,
      serviceName: '${widget.service.name} — ${_selectedDeliveryType!.label}',
      providerName: widget.service.name,
      variant: 'Kuryer chaqiruv',
      address: 'Kimdan: $from -> Kimga: $to',
      notes: 'Vazn: ${weight.isEmpty ? "No'malum" : "$weight kg"}\nIzoh: $notes',
      date: DateTime.now(), // ASAP
      price: 0, // Negotiable
      status: OrderStatus.pending,
      providerId: int.tryParse(widget.service.id),
    );

    try {
      await context.read<AppProvider>().addOrder(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buyurtma yuborildi! Kuryer tez orada siz bilan bog\'lanadi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyurtmani yuborib bo\'lmadi')),
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
          title: const Text('Kuryer chaqirish'),
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
                      child: Icon(LucideIcons.package, color: _accent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(widget.service.vehicleType.label, style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Nima yuboryapsiz?'),
              const SizedBox(height: 12),
              SelectableIconGrid<DeliveryType>(
                items: widget.service.deliveryTypes,
                selected: _selectedDeliveryType,
                iconOf: (t) => t.icon,
                labelOf: (t) => t.label,
                onSelect: (t) => setState(() => _selectedDeliveryType = t),
                accent: _accent,
              ),
              const SizedBox(height: 24),
              const SectionTitle('Qayerdan olib ketiladi?'),
              const SizedBox(height: 12),
              BookingInputField(
                controller: _fromController,
                hint: 'Masalan: Yunusobod 15-kvartal, 14-uy',
                icon: LucideIcons.mapPin,
                accent: _accent,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Qayerga eltib beriladi?'),
              const SizedBox(height: 12),
              BookingInputField(
                controller: _toController,
                hint: 'Masalan: Chilonzor 1-kvartal, 34-uy',
                icon: LucideIcons.navigation,
                accent: _accent,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Vazni (taxminiy)'),
                        const SizedBox(height: 12),
                        BookingInputField(
                          controller: _weightController,
                          hint: 'Mas: 5',
                          icon: LucideIcons.scale,
                          accent: _accent,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: 'kg',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle('Izoh va tafsilotlar'),
              const SizedBox(height: 12),
              BookingTextArea(
                controller: _notesController,
                hint: "Podyezd kodi 123, qabul qiluvchi telefon raqami...",
                icon: LucideIcons.messageSquare,
                accent: _accent,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Xizmat narxi kuryer yetib kelgach, bosib o\'tiladigan masofaga qarab belgilanadi.',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _canSubmit ? _confirmDispatch : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Buyurtma berish', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
