import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_availability_service.dart';
import '../../../services/provider_portal_service.dart';

/// Sartarosh / salon — xizmatlar, narxlar, ustalar.
class ProviderVenueSettingsWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;
  final String staffLabel;
  final String staffMetadataKey;

  const ProviderVenueSettingsWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
    this.staffLabel = 'Usta',
    this.staffMetadataKey = 'barbers',
  });

  @override
  State<ProviderVenueSettingsWidget> createState() =>
      _ProviderVenueSettingsWidgetState();
}

class _ServiceRow {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ProviderVenueSettingsWidgetState
    extends State<ProviderVenueSettingsWidget> {
  final _portal = ProviderPortalService();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};

  final List<_ServiceRow> _services = [];
  final List<TextEditingController> _staff = [];
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final s in _services) {
      s.dispose();
    }
    for (final c in _staff) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _portal.getMe(widget.categoryKey);
      final meta = Map<String, dynamic>.from(
        data['metadata_json'] as Map<String, dynamic>? ?? {},
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
    for (final c in _staff) {
      c.dispose();
    }
    _services.clear();
    _staff.clear();

    final services =
        (meta['services'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final prices = Map<String, dynamic>.from(
      meta['prices'] as Map<String, dynamic>? ?? {},
    );

    if (services.isEmpty) {
      _addService('', '');
    } else {
      for (final name in services) {
        _addService(name, '${prices[name] ?? ''}');
      }
    }

    final staffList = meta[widget.staffMetadataKey] as List<dynamic>? ?? [];
    if (staffList.isEmpty) {
      _staff.add(TextEditingController());
    } else {
      for (final item in staffList) {
        final name = item is Map ? item['name']?.toString() ?? '' : item.toString();
        _staff.add(TextEditingController(text: name));
      }
    }

    _timeSlots = (meta['time_slots'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        List.of(ProviderAvailability.defaultSlots);
  }

  void _addService(String name, String price) {
    final row = _ServiceRow();
    row.nameCtrl.text = name;
    row.priceCtrl.text = price;
    _services.add(row);
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

      final staff = _staff
          .map((c) => c.text.trim())
          .where((n) => n.isNotEmpty)
          .map((name) => {'name': name, 'rating': 5.0})
          .toList();

      final meta = Map<String, dynamic>.from(_baseMeta)
        ..['services'] = services
        ..['prices'] = prices
        ..[widget.staffMetadataKey] = staff
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
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Xizmatlar va narxlar',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _load),
          ],
        ),
        const SizedBox(height: 16),
        ..._services.asMap().entries.map((e) => _serviceRow(e.key, theme)),
        TextButton.icon(
          onPressed: () => setState(() => _addService('', '')),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Xizmat qo\'shish'),
        ),
        const SizedBox(height: 24),
        Text(
          widget.staffLabel,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._staff.asMap().entries.map((e) => _staffRow(e.key, theme)),
        TextButton.icon(
          onPressed: () => setState(() => _staff.add(TextEditingController())),
          icon: const Icon(LucideIcons.userPlus),
          label: Text('${widget.staffLabel} qo\'shish'),
        ),
        const SizedBox(height: 24),
        Text(
          'Ish vaqtlari',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Mijozlar faqat shu vaqtlarga yoziladi',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ProviderAvailability.defaultSlots.map((slot) {
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

  Widget _serviceRow(int index, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _services[index].nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Xizmat nomi',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _services[index].priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Narx (so\'m)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
            onPressed: _services.length <= 1
                ? null
                : () => setState(() {
                      _services[index].dispose();
                      _services.removeAt(index);
                    }),
          ),
        ],
      ),
    );
  }

  Widget _staffRow(int index, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _staff[index],
              decoration: InputDecoration(
                labelText: '${widget.staffLabel} ismi',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
            onPressed: _staff.length <= 1
                ? null
                : () => setState(() {
                      _staff[index].dispose();
                      _staff.removeAt(index);
                    }),
          ),
        ],
      ),
    );
  }
}
