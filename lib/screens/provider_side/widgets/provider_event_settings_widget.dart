import 'package:flutter/material.dart';
import '../../../services/hub_data_service.dart';
import 'package:flutter/services.dart';
import '../../../models/event_planning.dart';
import '../../../services/provider_availability_service.dart';
import '../../../services/provider_portal_service.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

class _ServiceRow {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

/// Tadbir tashkil etuvchi guruh sozlamalari.
class ProviderEventSettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderEventSettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<ProviderEventSettingsWidget> createState() =>
      _ProviderEventSettingsWidgetState();
}

class _ProviderEventSettingsWidgetState
    extends State<ProviderEventSettingsWidget> {
  final _portal = ProviderPortalService();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};
  final List<_ServiceRow> _services = [];
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);
  final Set<String> _organizerTypes = {};
  final Set<String> _eventTypes = {};
  final Set<String> _venueTypes = {};
  final _areaCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();

  static const _slots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  @override
  void dispose() {
    for (final s in _services) {
      s.dispose();
    }
    _areaCtrl.dispose();
    _teamCtrl.dispose();
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
    final prices = Map<String, dynamic>.from(
      meta['prices'] as Map<String, dynamic>? ?? {},
    );

    if (names.isEmpty) {
      _addService('', '');
    } else {
      for (final name in names) {
        _addService(name, '${prices[name] ?? ''}');
      }
    }

    _timeSlots =
        (meta['time_slots'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        List.of(_slots);

    _organizerTypes
      ..clear()
      ..addAll(
        (meta['organizer_types'] as List<dynamic>? ??
                ['stage_setup', 'full_organization'])
            .map((e) => e.toString()),
      );
    _eventTypes
      ..clear()
      ..addAll(
        (meta['event_types'] as List<dynamic>? ?? ['wedding', 'birthday']).map(
          (e) => e.toString(),
        ),
      );
    _venueTypes
      ..clear()
      ..addAll(
        (meta['venue_types'] as List<dynamic>? ??
                ['village_yard', 'open_field'])
            .map((e) => e.toString()),
      );
    _areaCtrl.text = meta['service_area']?.toString() ?? '';
    _teamCtrl.text = '${meta['team_size'] ?? 3}';
  }

  void _addService(String name, String price) {
    _services.add(
      _ServiceRow()
        ..nameCtrl.text = name
        ..priceCtrl.text = price,
    );
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
        prices[name] =
            int.tryParse(row.priceCtrl.text.replaceAll(' ', '')) ?? 0;
      }

      final latestData = await _portal.getMe(widget.categoryKey);
      final latestMeta = Map<String, dynamic>.from(
        latestData['metadata'] as Map<String, dynamic>? ??
            latestData['metadata_json'] as Map<String, dynamic>? ??
            {},
      );
      final meta = Map<String, dynamic>.from(latestMeta)
        ..['type'] = 'event_organizer'
        ..['service_area'] = _areaCtrl.text.trim()
        ..['team_size'] = int.tryParse(_teamCtrl.text.trim()) ?? 3
        ..['organizer_types'] = _organizerTypes.toList()
        ..['event_types'] = _eventTypes.toList()
        ..['venue_types'] = _venueTypes.toList()
        ..['services'] = services
        ..['prices'] = prices
        ..['time_slots'] = _timeSlots;

      await _portal.updateMetadata(widget.categoryKey, meta);
      HubDataService().clearCache();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sozlamalar saqlandi'.tr)));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        // FriendlyError: 'Saqlashda xatolik' o'rniga aniq sabab
        // (Internet yo'q / Sekin / Server) + Qayta tugma.
        showFriendlyErrorSnack(context, e);
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
          'Tadbir guruhi',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _areaCtrl,
          decoration: InputDecoration(
            labelText: 'Xizmat hududi'.tr,
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _teamCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jamoa hajmi (kishi)'.tr,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text('Xizmat turlari'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrganizerServiceType.values.map((t) {
            final selected = _organizerTypes.contains(t.key);
            return FilterChip(
              label: Text(t.label.tr),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _organizerTypes.add(t.key);
                } else if (_organizerTypes.length > 1) {
                  _organizerTypes.remove(t.key);
                }
              }),
              selectedColor: Colors.black12,
              checkmarkColor: Colors.black,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Joy turlari', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                EventVenueType.villageYard,
                EventVenueType.openField,
                EventVenueType.garden,
                EventVenueType.hall,
                EventVenueType.restaurant,
              ].map((t) {
                final selected = _venueTypes.contains(t.key);
                return FilterChip(
                  label: Text(t.label.tr),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _venueTypes.add(t.key);
                    } else if (_venueTypes.length > 1) {
                      _venueTypes.remove(t.key);
                    }
                  }),
                  selectedColor: Colors.black12,
                  checkmarkColor: Colors.black,
                );
              }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Xizmatlar va narxlar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
                    decoration: InputDecoration(
                      labelText: 'Narx'.tr,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
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
          label: Text('Xizmat qo\'shish'.tr),
        ),
        const SizedBox(height: 24),
        Text('Mumkin vaqtlar', style: Theme.of(context).textTheme.titleMedium),
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
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Saqlash'.tr),
          ),
        ),
      ],
    );
  }
}
