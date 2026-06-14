import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/courier_service.dart';
import '../../../services/provider_availability_service.dart';
import '../../../services/provider_portal_service.dart';

class _ServiceRow {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

/// Kuryer — yetkazish turlari, narxlar, vazn, vaqt slotlari.
class ProviderCourierSettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderCourierSettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<ProviderCourierSettingsWidget> createState() =>
      _ProviderCourierSettingsWidgetState();
}

class _ProviderCourierSettingsWidgetState extends State<ProviderCourierSettingsWidget> {
  final _portal = ProviderPortalService();
  final _maxWeightCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _isExpress = true;
  Map<String, dynamic> _baseMeta = {};
  final List<_ServiceRow> _services = [];
  final Set<DeliveryType> _deliveryTypes = {};
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);

  static const _slots = [
    '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
  ];

  @override
  void dispose() {
    _maxWeightCtrl.dispose();
    for (final s in _services) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _portal.getMe(widget.categoryKey);
      final meta = Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ??
            data['metadata_json'] as Map<String, dynamic>? ??
            {},
      );
      _applyMeta(meta);
    } catch (_) {
      _applyMeta({});
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyMeta(Map<String, dynamic> meta) {
    _baseMeta = Map<String, dynamic>.from(meta);
    for (final s in _services) {
      s.dispose();
    }
    _services.clear();
    _deliveryTypes.clear();

    final typeKeys = (meta['delivery_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    for (final key in typeKeys) {
      final t = DeliveryType.fromKey(key);
      if (t != null) _deliveryTypes.add(t);
    }
    if (_deliveryTypes.isEmpty) {
      _deliveryTypes.addAll([DeliveryType.document, DeliveryType.package, DeliveryType.food]);
    }

    final names = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final prices = Map<String, dynamic>.from(meta['prices'] as Map<String, dynamic>? ?? {});

    if (names.isEmpty) {
      for (final entry in prices.entries) {
        _addService(entry.key, '${entry.value}');
      }
    }
    if (_services.isEmpty) {
      _addService('Shahar ichi (5km)', '25000');
      _addService('Shahar tashqari', '80000');
      _addService('Express (+50%)', '12500');
    } else {
      for (final name in names) {
        _addService(name, '${prices[name] ?? ''}');
      }
    }

    _maxWeightCtrl.text = '${meta['max_weight'] ?? 15}';
    _isExpress = meta['is_express'] != false;
    _timeSlots = (meta['time_slots'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        List.of(_slots);
  }

  void _addService(String name, String price) {
    _services.add(_ServiceRow()
      ..nameCtrl.text = name
      ..priceCtrl.text = price);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prices = <String, int>{};
      for (final row in _services) {
        final name = row.nameCtrl.text.trim();
        if (name.isEmpty) continue;
        prices[name] = int.tryParse(row.priceCtrl.text.replaceAll(' ', '')) ?? 0;
      }

      final meta = Map<String, dynamic>.from(_baseMeta)
        ..['type'] = 'courier'
        ..['courier_role'] = 'solo'
        ..['delivery_types'] = _deliveryTypes.map((t) => t.key).toList()
        ..['prices'] = prices
        ..['max_weight'] = int.tryParse(_maxWeightCtrl.text) ?? 15
        ..['is_express'] = _isExpress
        ..['time_slots'] = _timeSlots;

      await _portal.updateMetadata(widget.categoryKey, meta);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sozlamalar saqlandi')),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saqlashda xatolik')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kuryer xizmatlari',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Yetkazish turlari, narxlar va maksimal vazn', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 20),
        Text('Yetkazish turlari', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DeliveryType.values.map((type) {
            final selected = _deliveryTypes.contains(type);
            return FilterChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _deliveryTypes.add(type);
                  } else if (_deliveryTypes.length > 1) {
                    _deliveryTypes.remove(type);
                  }
                });
              },
              selectedColor: Colors.black12,
              checkmarkColor: Colors.black,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ..._services.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: row.nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tarif ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Narx', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: _services.length > 1
                      ? () => setState(() {
                            _services[i].dispose();
                            _services.removeAt(i);
                          })
                      : null,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _addService('', '')),
          icon: const Icon(Icons.add),
          label: const Text('Tarif qo\'shish'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _maxWeightCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Maksimal vazn (kg)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Express yetkazish'),
          subtitle: const Text('Tezkor yetkazish imkoniyati'),
          value: _isExpress,
          onChanged: (v) => setState(() => _isExpress = v),
          activeThumbColor: widget.accent,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _slots.map((slot) {
            final selected = _timeSlots.contains(slot);
            return FilterChip(
              label: Text(slot),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _timeSlots = [..._timeSlots, slot]..sort();
                  } else {
                    _timeSlots.remove(slot);
                  }
                });
              },
              selectedColor: Colors.black12,
              checkmarkColor: Colors.black,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Saqlash'),
          ),
        ),
      ],
    );
  }
}
