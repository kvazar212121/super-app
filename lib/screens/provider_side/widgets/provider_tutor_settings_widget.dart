import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/tutor_service.dart';
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

/// Yakka repetitor — fanlar, dars formati, xizmatlar, vaqt.
class ProviderTutorSettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderTutorSettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<ProviderTutorSettingsWidget> createState() =>
      _ProviderTutorSettingsWidgetState();
}

class _ProviderTutorSettingsWidgetState extends State<ProviderTutorSettingsWidget> {
  final _portal = ProviderPortalService();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};
  final List<_ServiceRow> _services = [];
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);
  final Set<String> _subjects = {};
  final Set<String> _lessonModeKeys = {};
  final _experienceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  static const _subjectOptions = [
    'Matematika',
    'Ingliz tili',
    'Fizika',
    'Rus tili',
    'Kimyo',
    'Biologiya',
    'Test tayyorlov',
  ];

  static const _slots = [
    '09:00', '10:00', '11:00', '12:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
  ];

  @override
  void dispose() {
    for (final s in _services) {
      s.dispose();
    }
    _experienceCtrl.dispose();
    _areaCtrl.dispose();
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

    final names = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
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

    _subjects
      ..clear()
      ..addAll(
        (meta['subjects'] as List<dynamic>? ?? []).map((e) => e.toString()),
      );
    _lessonModeKeys
      ..clear()
      ..addAll(
        (meta['lesson_modes'] as List<dynamic>? ?? []).map((e) => e.toString()),
      );

    _experienceCtrl.text = '${meta['experience_years'] ?? ''}';
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

      final meta = Map<String, dynamic>.from(_baseMeta)
        ..['type'] = 'tutor'
        ..['tutor_role'] = 'solo'
        ..['specialty'] = 'Repetitor'
        ..['subjects'] = _subjects.toList()
        ..['lesson_modes'] = _lessonModeKeys.toList()
        ..['experience_years'] = int.tryParse(_experienceCtrl.text.trim()) ?? 0
        ..['service_area'] = _areaCtrl.text.trim()
        ..['services'] = services
        ..['prices'] = prices
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
          'Repetitor profili',
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
        const SizedBox(height: 12),
        TextField(
          controller: _experienceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Tajriba (yil)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Text('Fanlar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _subjectOptions.map((s) {
            final selected = _subjects.contains(s);
            return FilterChip(
              label: Text(s),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _subjects.add(s);
                } else {
                  _subjects.remove(s);
                }
              }),
              selectedColor: Colors.black12,
              checkmarkColor: Colors.black,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Dars formati', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LessonMode.values.map((m) {
            final selected = _lessonModeKeys.contains(m.key);
            return FilterChip(
              label: Text(m.label),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _lessonModeKeys.add(m.key);
                } else {
                  _lessonModeKeys.remove(m.key);
                }
              }),
              selectedColor: Colors.black12,
              checkmarkColor: Colors.black,
            );
          }).toList(),
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
        const SizedBox(height: 32),
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
    );
  }
}
