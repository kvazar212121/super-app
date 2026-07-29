import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../models/alarm.dart';
import '../../services/api_service.dart';
import '../../services/notification_helper.dart';

/// Budilnik qo'shish yoki tahrirlash ekrani.
class AlarmEditScreen extends StatefulWidget {
  final Alarm? existing;
  const AlarmEditScreen({super.key, this.existing});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  final _api = ApiService();

  late TimeOfDay _time;
  late TextEditingController _labelCtrl;
  final Set<int> _days = {}; // ISO weekday 1..7
  String _missionType = 'math';
  bool _snoozeEnabled = true;
  int _snoozeMinutes = 5;
  bool _saving = false;

  // Vazifa sozlamalari
  String _mathDifficulty = 'medium';
  int _mathCount = 1;
  String _photoTargetUz = 'Kran (yuvinish joyi)';
  String _photoTargetEn = 'bathroom sink or faucet';
  final _speechPhraseCtrl = TextEditingController();

  static const List<String> _weekdayLabels = [
    'Du',
    'Se',
    'Ch',
    'Pa',
    'Ju',
    'Sh',
    'Ya',
  ];

  // Rasm vazifasi uchun tayyor nishonlar (uz -> AI uchun en)
  static const Map<String, String> _photoPresets = {
    'Kran (yuvinish joyi)': 'bathroom sink or faucet',
    'Tish cho\'tkasi': 'a toothbrush',
    'Choynak': 'a kettle',
    'Muzlatgich': 'a refrigerator',
    'Deraza': 'a window',
    'Oshxona plitasi': 'a kitchen stove',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _time = TimeOfDay(hour: e.hour, minute: e.minute);
      _labelCtrl = TextEditingController(text: e.label);
      _days.addAll(e.repeatDayList);
      _missionType = e.missionType;
      _snoozeEnabled = e.snoozeEnabled;
      _snoozeMinutes = e.snoozeMinutes;
      _mathDifficulty = (e.missionConfig['difficulty'] as String?) ?? 'medium';
      _mathCount = (e.missionConfig['count'] as int?) ?? 1;
      if (e.missionType == 'photo') {
        _photoTargetUz =
            (e.missionConfig['target_uz'] as String?) ?? _photoTargetUz;
        _photoTargetEn =
            (e.missionConfig['target_en'] as String?) ?? _photoTargetEn;
      }
      if (e.missionType == 'speech') {
        _speechPhraseCtrl.text =
            (e.missionConfig['phrase_uz'] as String?) ?? '';
      }
    } else {
      _time = TimeOfDay.now();
      _labelCtrl = TextEditingController(text: 'Budilnik');
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _speechPhraseCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildMissionConfig() {
    switch (_missionType) {
      case 'photo':
        return {'target_uz': _photoTargetUz, 'target_en': _photoTargetEn};
      case 'speech':
        final p = _speechPhraseCtrl.text.trim();
        return p.isEmpty ? {'random': true} : {'phrase_uz': p};
      case 'math':
      default:
        return {'difficulty': _mathDifficulty, 'count': _mathCount};
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = {
      'label': _labelCtrl.text.trim().isEmpty
          ? 'Budilnik'
          : _labelCtrl.text.trim(),
      'hour': _time.hour,
      'minute': _time.minute,
      'repeat_days': (_days.toList()..sort()).join(','),
      'ringtone': 'default',
      'mission_type': _missionType,
      'mission_config': _buildMissionConfig(),
      'snooze_enabled': _snoozeEnabled,
      'snooze_minutes': _snoozeMinutes,
      'is_enabled': true,
    };

    try {
      final Map<String, dynamic> res = widget.existing == null
          ? await _api.createAlarm(payload)
          : await _api.updateAlarm(widget.existing!.id, payload);
      final alarm = Alarm.fromJson(res);
      await NotificationHelper().scheduleAlarm(alarm);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Saqlashda xatolik'.tr}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Yangi budilnik'.tr
              : 'Budilnikni tahrirlash'.tr,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vaqt
          Center(
            child: InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: 'Nomi'.tr,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Takror kunlari'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final selected = _days.contains(weekday);
              return ChoiceChip(
                label: Text(_weekdayLabels[i].tr),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _days.add(weekday);
                  } else {
                    _days.remove(weekday);
                  }
                }),
              );
            }),
          ),
          Text(
            _days.isEmpty
                ? 'Bir martalik (keyingi mos vaqtda)'.tr
                : 'Har hafta belgilangan kunlarda'.tr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Text(
            'O\'chirish vazifasi'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'math',
                label: Text('Misol'.tr),
                icon: const Icon(Icons.calculate),
              ),
              ButtonSegment(
                value: 'photo',
                label: Text('Rasm'.tr),
                icon: const Icon(Icons.camera_alt),
              ),
              ButtonSegment(
                value: 'speech',
                label: Text('Nutq'.tr),
                icon: const Icon(Icons.mic),
              ),
            ],
            selected: {_missionType},
            onSelectionChanged: (s) => setState(() => _missionType = s.first),
          ),
          const SizedBox(height: 12),
          _buildMissionConfigUi(),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text('Snooze (kechiktirish)'.tr),
            value: _snoozeEnabled,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _snoozeEnabled = v),
          ),
          if (_snoozeEnabled)
            Row(
              children: [
                Text('Snooze davomiyligi: '.tr),
                DropdownButton<int>(
                  value: _snoozeMinutes,
                  items: const [3, 5, 10, 15]
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m ${'daqiqa'.tr}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _snoozeMinutes = v ?? 5),
                ),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Saqlash'.tr, style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionConfigUi() {
    switch (_missionType) {
      case 'photo':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nimani rasmga olish kerak:'.tr,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _photoPresets.keys.map((uz) {
                return ChoiceChip(
                  label: Text(uz.tr),
                  selected: _photoTargetUz == uz,
                  onSelected: (_) => setState(() {
                    _photoTargetUz = uz;
                    _photoTargetEn = _photoPresets[uz]!;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              'AI rasmda shu narsa borligini tekshiradi.'.tr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      case 'speech':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _speechPhraseCtrl,
              decoration: InputDecoration(
                labelText:
                    'O\'qiladigan matn (bo\'sh qoldirsangiz tasodifiy)'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              'Ovoz chiqarib o\'qigan matningizni ilova tekshiradi.'.tr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      case 'math':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Qiyinlik: '.tr),
                DropdownButton<String>(
                  value: _mathDifficulty,
                  items: [
                    DropdownMenuItem(value: 'easy', child: Text('Oson'.tr)),
                    DropdownMenuItem(value: 'medium', child: Text('O\'rta'.tr)),
                    DropdownMenuItem(value: 'hard', child: Text('Qiyin'.tr)),
                  ],
                  onChanged: (v) =>
                      setState(() => _mathDifficulty = v ?? 'medium'),
                ),
              ],
            ),
            Row(
              children: [
                Text('Nechta misol: '.tr),
                DropdownButton<int>(
                  value: _mathCount,
                  items: const [1, 2, 3, 5]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('$c ${'ta'.tr}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _mathCount = v ?? 1),
                ),
              ],
            ),
          ],
        );
    }
  }
}
