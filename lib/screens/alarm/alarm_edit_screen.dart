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
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
        title: Text(
          widget.existing == null
              ? 'Yangi budilnik'.tr
              : 'Budilnikni tahrirlash'.tr,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Vaqt ko'rsatkichi
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF102A43),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Color(0xFF0F172A),
                        ),
                        timePickerTheme: const TimePickerThemeData(
                          backgroundColor: Colors.white,
                          hourMinuteColor: Color(0xFFF1F5F9),
                          hourMinuteTextColor: Color(0xFF0F172A),
                          dayPeriodColor: Color(0xFFF1F5F9),
                          dayPeriodTextColor: Color(0xFF0F172A),
                          dialBackgroundColor: Color(0xFFF8FAFC),
                          dialHandColor: Color(0xFF102A43),
                          dialTextColor: Color(0xFF0F172A),
                          entryModeIconColor: Color(0xFF102A43),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Budilnik nomi input
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Nomi'.tr,
              labelStyle: const TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Takror kunlari sarlavhasi
          Text(
            'Takror kunlari'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Kunlar chip qatori
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final selected = _days.contains(weekday);

              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _days.remove(weekday);
                  } else {
                    _days.add(weekday);
                  }
                }),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]) : null,
                    color: selected ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? const Color(0xFF102A43) : const Color(0xFFCBD5E1),
                      width: selected ? 1.5 : 1.0,
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _weekdayLabels[i].tr,
                    style: TextStyle(
                      color: selected ? Colors.white : textSecondary,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _days.isEmpty
                ? 'Bir martalik (keyingi mos vaqtda)'.tr
                : 'Har hafta belgilangan kunlarda'.tr,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // O'chirish vazifasi sarlavhasi
          Text(
            'O\'chirish vazifasi'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Vazifa turini tanlash segment paneli
          Row(
            children: [
              Expanded(child: _buildMissionSegment('math', 'Misol'.tr, Icons.calculate)),
              const SizedBox(width: 8),
              Expanded(child: _buildMissionSegment('photo', 'Rasm'.tr, Icons.camera_alt)),
              const SizedBox(width: 8),
              Expanded(child: _buildMissionSegment('speech', 'Nutq'.tr, Icons.mic)),
            ],
          ),
          const SizedBox(height: 16),

          _buildMissionConfigUi(),
          const SizedBox(height: 24),

          // Snooze yoqish/o'chirish
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Snooze (kechiktirish)'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  value: _snoozeEnabled,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF102A43),
                  onChanged: (v) => setState(() => _snoozeEnabled = v),
                ),
                if (_snoozeEnabled) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Snooze davomiyligi:'.tr,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _snoozeMinutes,
                          dropdownColor: Colors.white,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Saqlash tugmasi
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Saqlash'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMissionSegment(String type, String label, IconData icon) {
    final selected = _missionType == type;
    const textSecondary = Color(0xFF64748B);

    return GestureDetector(
      onTap: () => setState(() => _missionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]) : null,
          color: selected ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF102A43) : const Color(0xFFCBD5E1),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textSecondary,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionConfigUi() {
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    switch (_missionType) {
      case 'photo':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nimani rasmga olish kerak:'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _photoPresets.keys.map((uz) {
                  final selected = _photoTargetUz == uz;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _photoTargetUz = uz;
                      _photoTargetEn = _photoPresets[uz]!;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]) : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? const Color(0xFF102A43) : const Color(0xFFCBD5E1),
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        uz.tr,
                        style: TextStyle(
                          color: selected ? Colors.white : textPrimary,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'AI rasmda shu narsa borligini tekshiradi.'.tr,
                style: const TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        );
      case 'speech':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _speechPhraseCtrl,
                style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText:
                      'O\'qiladigan matn (bo\'sh qoldirsangiz tasodifiy)'.tr,
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'Ovoz chiqarib o\'qigan matningizni ilova tekshiradi.'.tr,
                style: const TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        );
      case 'math':
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qiyinlik:'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _mathDifficulty,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nechta misol:'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _mathCount,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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
          ),
        );
    }
  }
}
