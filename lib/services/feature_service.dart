import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Ilova bo'limlari holati (admin panelдан boshqariladi).
/// Yopiq bo'lim ilovaда "tez orada ishga tushadi" xabari bilan ko'rinadi.
class FeatureService {
  static final FeatureService _instance = FeatureService._internal();
  factory FeatureService() => _instance;
  FeatureService._internal();

  Map<String, dynamic> _features = {};
  Map<String, dynamic> _categories = {};
  bool loaded = false;
  bool isUserPremium = false;
  double premiumPrice = 0;

  static const String defaultMessage = "Bu bo'lim tez orada ishga tushadi ⏳";

  /// Backenddan bo'lim va xizmat holatlarini yuklaydi (xato bo'lsa hammasi ochiq).
  Future<void> load() async {
    try {
      _features = await ApiService().getFeatureFlags();
    } catch (e) {
      debugPrint('FeatureService features load xato: $e');
    }
    try {
      _categories = await ApiService().getCategoryFlags();
    } catch (e) {
      debugPrint('FeatureService categories load xato: $e');
    }
    await refreshPremium();
    loaded = true;
  }

  /// Foydalanuvchining premium holatini (va narxni) yangilaydi.
  Future<void> refreshPremium() async {
    try {
      final s = await ApiService().getPremiumStatus();
      isUserPremium = s['is_premium'] == true;
      premiumPrice = (s['price'] is num) ? (s['price'] as num).toDouble() : 0;
    } catch (_) {
      // auth yo'q yoki xato — premium emas deb hisoblanadi
    }
  }

  /// Bu bo'lim premium (pullik) talab qiladimi.
  bool isPremiumFeature(String key) {
    final f = _features[key];
    return f is Map && f['premium'] == true;
  }

  /// Xizmat kategoriyasi yoqilganmi (backend key bo'yicha).
  bool isCategoryEnabled(String catKey) {
    final c = _categories[catKey];
    if (c is Map && c['enabled'] != null) {
      return c['enabled'] == true;
    }
    return true;
  }

  String categoryMessage(String catKey) {
    final c = _categories[catKey];
    if (c is Map) {
      final m = c['message'];
      if (m is String && m.trim().isNotEmpty) return m;
    }
    return defaultMessage;
  }

  /// Bo'lim yoqilganmi (ma'lumot yo'q bo'lsa — ochiq deb hisoblanadi).
  bool isEnabled(String key) {
    final f = _features[key];
    if (f is Map && f['enabled'] != null) {
      return f['enabled'] == true;
    }
    return true;
  }

  /// Yopiq bo'lim uchun chiqadigan xabar.
  String message(String key) {
    final f = _features[key];
    if (f is Map) {
      final m = f['message'];
      if (m is String && m.trim().isNotEmpty) return m;
    }
    return defaultMessage;
  }
}
