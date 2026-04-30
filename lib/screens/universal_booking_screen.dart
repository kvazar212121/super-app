import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';

/// Yagona-sahifa universal bron formasi.
/// Har bir xizmat hubidan ochiladi, [kind] bo'yicha variantlarni ko'rsatadi.
class UniversalBookingScreen extends StatefulWidget {
  final ServiceHubKind kind;

  const UniversalBookingScreen({super.key, required this.kind});

  @override
  State<UniversalBookingScreen> createState() => _UniversalBookingScreenState();
}

class _UniversalBookingScreenState extends State<UniversalBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int _variantIndex = 0;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  ServiceHubKind get kind => widget.kind;

  ({String label, double basePrice}) get _variant =>
      kind.variants[_variantIndex];

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final order = ServiceOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: kind,
      serviceName: '${kind.title} — ${_variant.label}',
      providerName: 'Avto-tayinlandi',
      variant: _variant.label,
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      date: dateTime,
      price: _variant.basePrice,
      status: OrderStatus.pending,
    );

    context.read<AppProvider>().addOrder(order);

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${kind.title} bo‘yicha buyurtma qabul qilindi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = kind.accent;
    return Scaffold(
      appBar: AppBar(
        title: Text('${kind.title} — bron'),
        backgroundColor: accent.withValues(alpha: 0.1),
        foregroundColor: accent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _SectionTitle('Xizmat turi'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(kind.variants.length, (i) {
                final v = kind.variants[i];
                final selected = i == _variantIndex;
                return ChoiceChip(
                  label: Text(v.label),
                  selected: selected,
                  selectedColor: accent.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: selected ? accent : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (_) => setState(() => _variantIndex = i),
                );
              }),
            ),
            const SizedBox(height: 22),
            _SectionTitle('Manzil'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Masalan: Toshkent, Chilonzor 5-mavze, 12-uy',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 4) ? 'Manzilni kiriting' : null,
            ),
            const SizedBox(height: 22),
            _SectionTitle('Sana va vaqt'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_month_outlined,
                    label: '${_date.day}.${_date.month}.${_date.year}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule,
                    label: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionTitle('Qo‘shimcha izoh'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Masalan: 3-qavat, lift ishlamayapti',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            _PriceCard(
              accent: accent,
              variant: _variant.label,
              price: _variant.basePrice,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Buyurtma berish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final Color accent;
  final String variant;
  final double price;

  const _PriceCard({
    required this.accent,
    required this.variant,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text(
                  'Boshlang‘ich narx',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            '${price.toStringAsFixed(0)} so‘m',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
