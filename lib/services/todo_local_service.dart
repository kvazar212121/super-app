import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local offline persistence service for "Mening Rejalarim" (Life OS Hub).
/// Stores tasks, water intake, habits, pill reminders, and voice notes locally.
class TodoLocalService {
  static final TodoLocalService _instance = TodoLocalService._internal();
  factory TodoLocalService() => _instance;
  TodoLocalService._internal();

  static const String _kTasksKey = 'todo_local_tasks_v2';
  static const String _kWaterKey = 'todo_local_water_v2';
  static const String _kHabitsKey = 'todo_local_habits_v2';
  static const String _kPillsKey = 'todo_local_pills_v2';
  static const String _kVoiceNotesKey = 'todo_local_voice_notes_v2';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // ==========================================
  // 1. TASKS (VAZIFALAR)
  // ==========================================
  Future<List<Map<String, dynamic>>> getTasksForDate(DateTime date) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kTasksKey);
    if (raw == null) return _defaultTasks(date);
    final List<dynamic> list = jsonDecode(raw);
    final dateStr = formatDate(date);
    return list
        .where((item) => item['date'] == dateStr)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> addTask(Map<String, dynamic> task) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kTasksKey);
    List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.add(task);
    await prefs.setString(_kTasksKey, jsonEncode(list));
  }

  Future<void> toggleTask(String taskId, bool isDone) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kTasksKey);
    if (raw == null) return;
    List<dynamic> list = jsonDecode(raw);
    for (var item in list) {
      if (item['id'] == taskId) {
        item['is_done'] = isDone;
      }
    }
    await prefs.setString(_kTasksKey, jsonEncode(list));
  }

  Future<void> deleteTask(String taskId) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kTasksKey);
    if (raw == null) return;
    List<dynamic> list = jsonDecode(raw);
    list.removeWhere((item) => item['id'] == taskId);
    await prefs.setString(_kTasksKey, jsonEncode(list));
  }

  List<Map<String, dynamic>> _defaultTasks(DateTime date) {
    final dateStr = formatDate(date);
    return [
      {
        'id': 'task_1',
        'date': dateStr,
        'title': 'Bozordan masalliqlar sotib olish',
        'time': '10:30',
        'is_done': true,
        'category': 'xarid',
      },
      {
        'id': 'task_2',
        'date': dateStr,
        'title': 'Usta bilan uchrashish (Konditsioner ta\'miri)',
        'time': '14:00',
        'is_done': false,
        'category': 'xizmat',
      },
      {
        'id': 'task_3',
        'date': dateStr,
        'title': 'Eski e\'lonlarni yangilash',
        'time': '18:00',
        'is_done': false,
        'category': 'ish',
      },
    ];
  }

  // ==========================================
  // 2. WATER TRACKER (SUV BALANSI)
  // ==========================================
  Future<Map<String, dynamic>> getWaterForDate(DateTime date) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kWaterKey);
    final dateStr = formatDate(date);
    if (raw != null) {
      final Map<String, dynamic> all = jsonDecode(raw);
      if (all.containsKey(dateStr)) {
        return Map<String, dynamic>.from(all[dateStr]);
      }
    }
    return {
      'date': dateStr,
      'target_ml': 2200,
      'current_ml': 1200,
      'history': [
        {'time': '08:15', 'amount': 300},
        {'time': '11:00', 'amount': 400},
        {'time': '13:30', 'amount': 500},
      ],
    };
  }

  Future<void> addWaterIntake(DateTime date, int amountMl) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kWaterKey);
    Map<String, dynamic> all = raw != null ? jsonDecode(raw) : {};
    final dateStr = formatDate(date);
    
    Map<String, dynamic> current = all[dateStr] != null
        ? Map<String, dynamic>.from(all[dateStr])
        : {
            'date': dateStr,
            'target_ml': 2200,
            'current_ml': 0,
            'history': [],
          };

    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    int currentMl = (current['current_ml'] as int) + amountMl;
    List<dynamic> history = List.from(current['history'] ?? []);
    history.add({'time': timeStr, 'amount': amountMl});

    current['current_ml'] = currentMl;
    current['history'] = history;
    all[dateStr] = current;

    await prefs.setString(_kWaterKey, jsonEncode(all));
  }

  // ==========================================
  // 3. HABIT TRACKER (ODATLAR)
  // ==========================================
  Future<List<Map<String, dynamic>>> getHabitsForDate(DateTime date) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kHabitsKey);
    if (raw == null) return _defaultHabits();
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> toggleHabitForDate(String habitId, DateTime date) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kHabitsKey);
    List<dynamic> list = raw != null ? jsonDecode(raw) : _defaultHabits();
    final dateStr = formatDate(date);

    for (var habit in list) {
      if (habit['id'] == habitId) {
        List<dynamic> completedDates = List.from(habit['completed_dates'] ?? []);
        if (completedDates.contains(dateStr)) {
          completedDates.remove(dateStr);
          habit['streak'] = ((habit['streak'] as int) - 1).clamp(0, 999);
        } else {
          completedDates.add(dateStr);
          habit['streak'] = (habit['streak'] as int) + 1;
        }
        habit['completed_dates'] = completedDates;
      }
    }
    await prefs.setString(_kHabitsKey, jsonEncode(list));
  }

  Future<void> addHabit(String title, String iconName) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kHabitsKey);
    List<dynamic> list = raw != null ? jsonDecode(raw) : _defaultHabits();
    list.add({
      'id': 'habit_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'icon': iconName,
      'streak': 1,
      'completed_dates': [formatDate(DateTime.now())],
    });
    await prefs.setString(_kHabitsKey, jsonEncode(list));
  }

  List<Map<String, dynamic>> _defaultHabits() {
    final today = formatDate(DateTime.now());
    return [
      {
        'id': 'h1',
        'title': 'Ertalabki 15 min zaryadka',
        'icon': 'activity',
        'streak': 5,
        'completed_dates': [today],
      },
      {
        'id': 'h2',
        'title': '20 bet kitob o\'qish',
        'icon': 'book',
        'streak': 12,
        'completed_dates': [today],
      },
      {
        'id': 'h3',
        'title': '10,000 qadam yurish',
        'icon': 'footprints',
        'streak': 3,
        'completed_dates': [],
      },
    ];
  }

  // ==========================================
  // 4. PILL REMINDER (DORI-DARMON)
  // ==========================================
  Future<List<Map<String, dynamic>>> getPillsForDate(DateTime date) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kPillsKey);
    if (raw == null) return _defaultPills();
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> togglePillTaken(String pillId, String timeSlot, DateTime date) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kPillsKey);
    List<dynamic> list = raw != null ? jsonDecode(raw) : _defaultPills();
    final dateStr = formatDate(date);
    final key = "${dateStr}_$timeSlot";

    for (var pill in list) {
      if (pill['id'] == pillId) {
        List<dynamic> takenLogs = List.from(pill['taken_logs'] ?? []);
        if (takenLogs.contains(key)) {
          takenLogs.remove(key);
        } else {
          takenLogs.add(key);
        }
        pill['taken_logs'] = takenLogs;
      }
    }
    await prefs.setString(_kPillsKey, jsonEncode(list));
  }

  Future<void> addPill(String title, String dosage, List<String> times) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kPillsKey);
    List<dynamic> list = raw != null ? jsonDecode(raw) : _defaultPills();
    list.add({
      'id': 'pill_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'dosage': dosage,
      'times': times,
      'taken_logs': [],
    });
    await prefs.setString(_kPillsKey, jsonEncode(list));
  }

  List<Map<String, dynamic>> _defaultPills() {
    final today = formatDate(DateTime.now());
    return [
      {
        'id': 'p1',
        'title': 'C Vitamini 1000mg',
        'dosage': '1 kapsula (ovqatdan so\'ng)',
        'times': ['08:00', '20:00'],
        'taken_logs': ['${today}_08:00'],
      },
      {
        'id': 'p2',
        'title': 'Omega-3 Balik yog\'i',
        'dosage': '1 kapsula (tushlikda)',
        'times': ['13:00'],
        'taken_logs': ['${today}_13:00'],
      },
    ];
  }

  // ==========================================
  // 5. VOICE NOTES (OVOZLI QAYDLAR)
  // ==========================================
  Future<List<Map<String, dynamic>>> getVoiceNotes() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kVoiceNotesKey);
    if (raw == null) return _defaultVoiceNotes();
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addVoiceNote(String title, String transcribedText, int durationSec) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_kVoiceNotesKey);
    List<dynamic> list = raw != null ? jsonDecode(raw) : _defaultVoiceNotes();
    final now = DateTime.now();
    list.insert(0, {
      'id': 'vn_${now.millisecondsSinceEpoch}',
      'date': formatDate(now),
      'time': "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      'title': title,
      'transcription': transcribedText,
      'duration_sec': durationSec,
    });
    await prefs.setString(_kVoiceNotesKey, jsonEncode(list));
  }

  List<Map<String, dynamic>> _defaultVoiceNotes() {
    final today = formatDate(DateTime.now());
    return [
      {
        'id': 'vn1',
        'date': today,
        'time': '09:45',
        'title': 'Usta uchun eslatma',
        'transcription': 'Santexnik usta bilan soat 14:00 da kelishdik. Uyga kelganda quvurlarni almashtiradi.',
        'duration_sec': 12,
      },
      {
        'id': 'vn2',
        'date': today,
        'time': '12:15',
        'title': 'Xarid ro\'yxati ovozli qaydi',
        'transcription': 'Kechki ovqat uchun: 1 kg guruch, sabzi, mol go\'shti va zira olish kerak.',
        'duration_sec': 8,
      },
    ];
  }
}
