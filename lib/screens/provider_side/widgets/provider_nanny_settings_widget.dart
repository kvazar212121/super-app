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

/// Enaga — xizmatlar, yosh guruhlari, vaqt slotlari.
class ProviderNannySettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderNannySettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<ProviderNannySettingsWidget> createState() => _ProviderNannySettingsWidgetState();
}

class _ProviderNannySettingsWidgetState extends State<ProviderNannySettingsWidget> {
  final _portal = ProviderPortalService();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};
  final List<_ServiceRow> _services = [];
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);
  final Set<String> _ageGroups = {};
  final Set<String> _languages = {};
  final _experienceCtrl = TextEditingController();

  static const _slots = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
  ];
  static const _ageOptions = ['0-1', '1-3', '3-7', '7-12'];

  @override
  void dispose() {
    for (final s in _services) {
      s.dispose();
    }
    _experienceCtrl.dispose();
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

    final names = (meta['services'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final prices = Map<String, dynamic>.from(meta['prices'] as Map<String, dynamic>? ?? {});

    if (names.isEmpty) {
      _addService('', '');
    } else {
      for (final name in names) {
        _addService(name, '${prices[name] ?? ''}');
      }
    }

    _timeSlots = (meta['time_slots'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        List.of(_slots);

    _ageGroups
      ..clear()
      ..addAll(
        (meta['age_groups'] as List<dynamic>? ?? ['1-3', '3-7']).map((e) => e.toString()),
      );
    _languages
      ..clear()
      ..addAll(
        (meta['languages'] as List<dynamic>? ?? ['uz']).map((e) => e.toString()),
      );
    _experienceCtrl.text = '${meta['experience_years'] ?? ''}';
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
        ..['type'] = 'nanny'
        ..['specialty'] = 'Enaga'
        ..['services'] = services
        ..['prices'] = prices
        ..['time_slots'] = _timeSlots
        ..['age_groups'] = _ageGroups.toList()
        ..['languages'] = _languages.toList()
        ..['experience_years'] = int.tryParse(_experienceCtrl.text.trim()) ?? 0;

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

    final verification = _baseMeta['verification_status']?.toString() ?? 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (verification != 'verified')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Profilingiz administrator tasdiqlaguncha mijozlarga ko\'rinmaydi.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        Text(
          'Enaga xizmatlari',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _experienceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Tajriba (yil)'),
        ),
        const SizedBox(height: 16),
        const Text('Yosh guruhlari', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: _ageOptions.map((a) {
            return FilterChip(
              label: Text('$a yosh'),
              selected: _ageGroups.contains(a),
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _ageGroups.add(a);
                  } else if (_ageGroups.length > 1) {
                    _ageGroups.remove(a);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ..._services.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: row.nameCtrl,
                    decoration: InputDecoration(labelText: 'Xizmat ${i + 1}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Narx'),
                  ),
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
        const SizedBox(height: 16),
        const Text('Ish vaqtlari', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    _timeSlots.add(slot);
                    _timeSlots.sort();
                  } else if (_timeSlots.length > 1) {
                    _timeSlots.remove(slot);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: widget.accent),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Saqlash'),
          ),
        ),
      ],
    );
  }
}
