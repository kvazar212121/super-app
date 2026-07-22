import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_helper.dart';

/// Aqlli ovqat-monitoring: kuniga 3 marta (nonushta/tushlik/kechki) telefon
/// eslatma beradi va foydalanuvchi nima yeganini yozib/rasmga olib qo'yadi.
///
/// Foydalanuvchi xohlasa BUTUNLAY o'chirib qo'yishi mumkin (toggle).
/// "Belgilangan" (yozgan yoki "yemadim" degan) ovqat shu kuni qayta so'ralmaydi.
class MealReminderService extends ChangeNotifier {
  static final MealReminderService _instance = MealReminderService._internal();
  factory MealReminderService() => _instance;
  MealReminderService._internal();

  static const _enabledKey = 'meal_reminders_enabled';
  static const _handledPrefix = 'meal_handled_';

  /// Ovqatlar va standart vaqtlari.
  static const List<Map<String, dynamic>> meals = [
    {'type': 'breakfast', 'label': 'Nonushta', 'hour': 8, 'minute': 0},
    {'type': 'lunch', 'label': 'Tushlik', 'hour': 13, 'minute': 0},
    {'type': 'dinner', 'label': 'Kechki ovqat', 'hour': 19, 'minute': 0},
  ];

  bool _enabled = true;
  bool get enabled => _enabled;

  static String labelFor(String type) {
    final m = meals.firstWhere(
      (e) => e['type'] == type,
      orElse: () => const {'label': 'Ovqat'},
    );
    return m['label'] as String;
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _handledKey(String type) =>
      '$_handledPrefix${_dateStr(DateTime.now())}_$type';

  /// Ilova ishga tushganda — toggle holatini o'qiydi va yoqiq bo'lsa rejalaydi.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true; // standart: YOQIQ
      if (_enabled) {
        await _scheduleAll();
      }
    } catch (e) {
      debugPrint('MealReminderService init xato: $e');
    }
  }

  /// Toggle — yoqish/o'chirish. O'chirilса barcha eslatmalar bekor qilinadi.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
      if (value) {
        await _scheduleAll();
      } else {
        await _cancelAll();
      }
    } catch (e) {
      debugPrint('MealReminderService setEnabled xato: $e');
    }
  }

  Future<void> _scheduleAll() async {
    for (var i = 0; i < meals.length; i++) {
      final m = meals[i];
      await NotificationHelper().scheduleDailyMeal(
        NotificationHelper.mealIdBase + i,
        '${m['label']} vaqti',
        'Ovqat qildingizmi? Nima yeganingizni belgilab qo\'ying.',
        hour: m['hour'] as int,
        minute: m['minute'] as int,
        mealType: m['type'] as String,
      );
    }
  }

  Future<void> _cancelAll() async {
    for (var i = 0; i < meals.length; i++) {
      await NotificationHelper().cancelNotification(
        NotificationHelper.mealIdBase + i,
      );
    }
  }

  /// Shu ovqat bugun BELGILANDI deb qo'yamiz (yozildi yoki "yemadim" tanlandi) —
  /// qayta so'ralmaydi.
  Future<void> markHandled(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_handledKey(type), true);
    } catch (_) {}
  }

  Future<bool> _isHandled(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_handledKey(type)) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Panel (Kaloriya/Fitnes) ochilganda: vaqti O'TGAN-u hali BELGILANMAGAN
  /// ovqatlardan eng oxirgisini qaytaradi (yoki null). Modal shu asosda chiqadi.
  Future<String?> pendingMealNow() async {
    if (!_enabled) return null;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    String? pending;
    for (final m in meals) {
      final mealMin = (m['hour'] as int) * 60 + (m['minute'] as int);
      if (nowMin >= mealMin && !(await _isHandled(m['type'] as String))) {
        pending = m['type'] as String;
      }
    }
    return pending;
  }
}
