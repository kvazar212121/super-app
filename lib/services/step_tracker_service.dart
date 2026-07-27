import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Kunlik qadamlarni telefon pedometeridan sanaydi va serverga sinxronlaydi.
///
/// Android'ning `TYPE_STEP_COUNTER` sensori bootdan beri kumulyativ qiymat beradi.
/// Kunlik qadam = joriy_kumulyativ − kun boshidagi baza. Baza `SharedPreferences`da
/// saqlanadi va yangi kun boshlanganda (yoki qurilma reboot bo'lganda) tiklanadi.
class StepTrackerService extends ChangeNotifier {
  static final StepTrackerService _instance = StepTrackerService._internal();
  factory StepTrackerService() => _instance;
  StepTrackerService._internal();

  static const _baselineKey = 'step_baseline_value';
  static const _baselineDateKey = 'step_baseline_date';
  static const _todayStepsKey = 'step_today_cached';

  StreamSubscription<StepCount>? _sub;
  int _todaySteps = 0;
  bool _available = false;
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  int get todaySteps => _todaySteps;
  bool get available => _available;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Ilova ishga tushganda chaqiriladi. Ruxsat so'raydi va oqimni tinglaydi.
  Future<void> init() async {
    // Oldin keshdan bugungi qadamni tiklaymiz (UI darhol ko'rsatishi uchun)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_baselineDateKey) == _dateKey(DateTime.now())) {
        _todaySteps = prefs.getInt(_todayStepsKey) ?? 0;
      }
    } catch (_) {}

    // Faqat mobil (Android/iOS)
    if (kIsWeb) return;

    try {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        _available = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      // permission_handler ba'zi platformada activityRecognition'ni bilmasligi mumkin
    }

    try {
      _sub?.cancel();
      _sub = Pedometer.stepCountStream.listen(
        _onStep,
        onError: (_) {
          _available = false;
          notifyListeners();
        },
        cancelOnError: false,
      );
      _available = true;
    } catch (_) {
      _available = false;
    }
    notifyListeners();
  }

  Future<void> _onStep(StepCount event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dateKey(DateTime.now());
      final cumulative = event.steps;

      int baseline = prefs.getInt(_baselineKey) ?? -1;
      final baseDate = prefs.getString(_baselineDateKey);

      if (baseDate != today || baseline < 0 || cumulative < baseline) {
        // Yangi kun yoki reboot (kumulyativ kamaydi) — bazani tiklaymiz
        baseline = cumulative;
        await prefs.setInt(_baselineKey, baseline);
        await prefs.setString(_baselineDateKey, today);
      }

      final steps = (cumulative - baseline).clamp(0, 200000);
      _todaySteps = steps;
      await prefs.setInt(_todayStepsKey, steps);
      _available = true;
      notifyListeners();

      // Serverga sinxron (30 soniyada bir marta yoki 25 qadam o'zgarishda)
      final now = DateTime.now();
      if (now.difference(_lastSync).inSeconds >= 30) {
        _lastSync = now;
        _syncToServer(steps);
      }
    } catch (_) {}
  }

  Future<void> _syncToServer(int steps) async {
    if (!ApiService().hasToken) return;
    try {
      await ApiService().syncSteps(_dateKey(DateTime.now()), steps);
    } catch (_) {}
  }

  /// Ekran ochilganda majburiy sinxron (kutmasdan).
  Future<void> syncNow() async {
    await _syncToServer(_todaySteps);
  }

  /// Foydalanuvchi "Yoqish" tugmasini bosganda — ruxsatni so'raydi (agar butunlay
  /// rad etilgan bo'lsa ilova sozlamalarini ochadi) va oqimni qayta ishga tushiradi.
  /// Eslatma: emulatorда qadam sensori bo'lmagani uchun qadam baribir 0 qoladi —
  /// bu faqat haqiqiy telefonда ishlaydi.
  Future<void> enable() async {
    if (kIsWeb) return;
    try {
      final status = await Permission.activityRecognition.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
    } catch (_) {}
    await init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
