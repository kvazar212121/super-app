import 'package:flutter/material.dart';
import '../../../services/hub_data_service.dart';
import 'package:flutter/services.dart';
import '../../../models/massage_hijoma.dart';
import '../../../services/provider_availability_service.dart';
import '../../../services/provider_portal_service.dart';

import '../../../services/settings_save_controller.dart';

class _ServiceRow {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class ProviderMassageSettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;
  final bool showSaveButton;
  final SettingsSaveController? saveController;

  const ProviderMassageSettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
    this.showSaveButton = true,
    this.saveController,
  });

  @override
  State<ProviderMassageSettingsWidget> createState() =>
      _ProviderMassageSettingsWidgetState();
}

class _ProviderMassageSettingsWidgetState
    extends State<ProviderMassageSettingsWidget> {
  final _portal = ProviderPortalService();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};
  final _areaCtrl = TextEditingController();
  String _gender = 'both';

  static const _slots = [
    '09:00', '10:00', '11:00', '12:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
  ];

  @override
  void dispose() {
    widget.saveController?.deregister(_saveExternal);
    for (final s in _services) {
      s.dispose();
    }
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
    widget.saveController?.register(_saveExternal);
  }

  Future<bool> _saveExternal() async {
    try {
      await _save();
      return true;
    } catch (_) {
      return false;
    }
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

    final names = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final prices = Map<String, dynamic>.from(meta['prices'] as Map<String, dynamic>? ?? {});

    if (names.isEmpty) {
      _addService('', '');
    } else {
      for (final name in names) {
        if (name.contains("Uyga chiqish qo'shimcha")) continue;
        _addService(name, '${prices[name] ?? ''}');
      }
    }

    _timeSlots = (meta['time_slots'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        List.of(_slots);
    _gender = meta['gender']?.toString() ?? 'both';
    _areaCtrl.text = meta['service_area']?.toString() ?? '';
  }

  void _addService(String name, String price) {
    _services.add(_ServiceRow()
      ..nameCtrl.text = name
      ..priceCtrl.text = price);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final services = <String>[];
      final prices = <String, int>{};
      for (final row in _services) {
        final name = row.nameCtrl.text.trim();
        if (name.isEmpty) continue;
        services.add(name);
        prices[name] = int.tryParse(row.priceCtrl.text.replaceAll(' ', '')) ?? 0;
      }

      final latestData = await _portal.getMe(widget.categoryKey);
      final latestMeta = Map<String, dynamic>.from(
        latestData['metadata'] as Map<String, dynamic>? ??
        latestData['metadata_json'] as Map<String, dynamic>? ??
        {},
      );
      final meta = Map<String, dynamic>.from(latestMeta)
        ..['type'] = 'massage'
        ..['service_area'] = _areaCtrl.text.trim()
        ..['visit_modes'] = ['at_center']
        ..['gender'] = _gender
        ..['services'] = services
        ..['prices'] = prices
        ..['time_slots'] = _timeSlots;

      await _portal.updateMetadata(widget.categoryKey, meta);
      HubDataService().clearCache();
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
          'Massaj va hijoma',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _areaCtrl,
          decoration: const InputDecoration(
            labelText: 'Xizmat hududi',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text('Xizmatlar va narxlar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
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
                      labelText: 'Xizmat ${i + 1}',
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
                    decoration: const InputDecoration(
                      labelText: 'Narx',
                      border: OutlineInputBorder(),
                    ),
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
          label: const Text('Xizmat qo\'shish'),
        ),
        const SizedBox(height: 24),
        Text('Bo\'sh vaqtlar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        if (widget.showSaveButton) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Saqlash'),
            ),
          ),
        ],
      ],
    );
  }
}
