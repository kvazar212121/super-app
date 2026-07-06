/// Majburlovchi budilnik modeli — backend `alarms` jadvaliga mos.
class Alarm {
  final int id;
  final String label;
  final int hour;
  final int minute;
  final String repeatDays; // ISO weekday CSV: "1,2,3,4,5" (1=Dushanba). Bo'sh = bir martalik.
  final String ringtone;
  final String missionType; // math | photo | speech
  final Map<String, dynamic> missionConfig;
  final bool snoozeEnabled;
  final int snoozeMinutes;
  final bool isEnabled;

  const Alarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.repeatDays = '',
    this.ringtone = 'default',
    this.missionType = 'math',
    this.missionConfig = const {},
    this.snoozeEnabled = true,
    this.snoozeMinutes = 5,
    this.isEnabled = true,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as int,
      label: (json['label'] ?? 'Budilnik') as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      repeatDays: (json['repeat_days'] ?? '') as String,
      ringtone: (json['ringtone'] ?? 'default') as String,
      missionType: (json['mission_type'] ?? 'math') as String,
      missionConfig: Map<String, dynamic>.from(json['mission_config'] ?? const {}),
      snoozeEnabled: (json['snooze_enabled'] ?? true) as bool,
      snoozeMinutes: (json['snooze_minutes'] ?? 5) as int,
      isEnabled: (json['is_enabled'] ?? true) as bool,
    );
  }

  /// Backendga yuboriladigan JSON (create/update uchun).
  Map<String, dynamic> toPayload() => {
        'label': label,
        'hour': hour,
        'minute': minute,
        'repeat_days': repeatDays,
        'ringtone': ringtone,
        'mission_type': missionType,
        'mission_config': missionConfig,
        'snooze_enabled': snoozeEnabled,
        'snooze_minutes': snoozeMinutes,
        'is_enabled': isEnabled,
      };

  /// Takror kunlar ro'yxati (ISO weekday raqamlari).
  List<int> get repeatDayList => repeatDays
      .split(',')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .where((d) => d >= 1 && d <= 7)
      .toList();

  bool get isOneTime => repeatDayList.isEmpty;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Alarm copyWith({
    String? label,
    int? hour,
    int? minute,
    String? repeatDays,
    String? ringtone,
    String? missionType,
    Map<String, dynamic>? missionConfig,
    bool? snoozeEnabled,
    int? snoozeMinutes,
    bool? isEnabled,
  }) {
    return Alarm(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      ringtone: ringtone ?? this.ringtone,
      missionType: missionType ?? this.missionType,
      missionConfig: missionConfig ?? this.missionConfig,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
