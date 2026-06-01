import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Tozalash — xizmatlar, narxlar, vaqt slotlari; jamoa uchun jamoa hajmi.
class ProviderCleaningSettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderCleaningSettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<ProviderCleaningSettingsWidget> createState() =>
      _ProviderCleaningSettingsWidgetState();
}

class _ProviderCleaningSettingsWidgetState extends State<ProviderCleaningSettingsWidget> {
  final _portal = ProviderPortalService();
  final _teamSizeCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};
  final List<_ServiceRow> _services = [];
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);
  bool _isTeam = false;

  static const _slots = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '14:00', '15:00', '16:00', '17:00', '18:00',
  ];

  @override
  void dispose() {
    _teamSizeCtrl.dispose();
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
    _isTeam = meta['cleaner_role'] == 'team';
    _teamSizeCtrl.text = '${meta['team_size'] ?? ''}';

    for (final s in _services) {
      s.dispose();
    }
    _services.clear();

    final serviceNames =
        (meta['services'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final prices = Map<String, dynamic>.from(meta['prices'] as Map<String, dynamic>? ?? {});

    if (serviceNames.isEmpty) {
      _addService('', '');
    } else {
      for (final name in serviceNames) {
        _addService(name, '${prices[name] ?? ''}');
      }
    }

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
      final services = <String>[];
      final prices = <String, int>{};
      for (final row in _services) {
        final name = row.nameCtrl.text.trim();
        if (name.isEmpty) continue;
        services.add(name);
        prices[name] = int.tryParse(row.priceCtrl.text.replaceAll(' ', '')) ?? 0;
      }

      final meta = Map<String, dynamic>.from(_baseMeta)
        ..['type'] = 'master'
        ..['specialty'] = 'Tozalash'
        ..['services'] = services
        ..['prices'] = prices
        ..['time_slots'] = _timeSlots;

      if (_isTeam) {
        meta['team_size'] = int.tryParse(_teamSizeCtrl.text.trim()) ?? 2;
      }

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
          'Tozalash xizmatlari',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _isTeam
              ? 'Jamoa sifatida xizmatlar va narxlarni belgilang'
              : 'Yakka tozalovchi sifatida xizmatlar va narxlarni belgilang',
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (_isTeam) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _teamSizeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Jamoa a\'zolari soni',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 20),
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
                      hintText: 'Masalan: 2 xonali kvartira',
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
        Text(
          'Ish vaqtlari',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
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
              selectedColor: widget.accent.withValues(alpha: 0.2),
              checkmarkColor: widget.accent,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: widget.accent,
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
    );
  }
}
