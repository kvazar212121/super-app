import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Server yo'q paytda login/register uchun demo foydalanuvchilar.
class DemoAuthService {
  static const _sessionKey = 'offline_demo_user';
  static const _registeredKey = 'offline_registered_users';
  static const demoPassword = '1234';
  static const demoOtp = '1234';

  static const List<Map<String, dynamic>> users = [
    {
      'name': 'Kudratulloh',
      'surname': 'Rahimov',
      'phone': '+998901112233',
      'balance': 250000.0,
      'cashback': 18500.0,
      'is_premium': true,
    },
    {
      'name': 'Abdulloh',
      'surname': 'Karimov',
      'phone': '+998901234567',
      'balance': 150000.0,
      'cashback': 12500.0,
      'is_premium': true,
    },
    {
      'name': 'Nilufar',
      'surname': 'Rustamova',
      'phone': '+998912345678',
      'balance': 85000.0,
      'cashback': 7200.0,
      'is_premium': false,
    },
    {
      'name': 'Sardor',
      'surname': 'Aliyev',
      'phone': '+998933456789',
      'balance': 230000.0,
      'cashback': 18900.0,
      'is_premium': true,
    },
  ];

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) return '+998$digits';
    if (digits.length == 12 && digits.startsWith('998')) return '+$digits';
    return phone.trim();
  }

  static Future<List<Map<String, dynamic>>> _allUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_registeredKey);
    final registered = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        registered.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    return [...users, ...registered];
  }

  static Future<void> _saveRegistered(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_registeredKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        list.addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    list.removeWhere(
      (u) => normalizePhone(u['phone'] as String) == normalizePhone(user['phone'] as String),
    );
    list.add(user);
    await prefs.setString(_registeredKey, jsonEncode(list));
  }

  static Future<Map<String, dynamic>?> tryLogin(String phone, String secret) async {
    final normalized = normalizePhone(phone);
    final all = await _allUsers();
    for (final user in all) {
      if (normalizePhone(user['phone'] as String) != normalized) continue;
      final pin = user['pin'] as String?;
      if (pin != null && pin.isNotEmpty && secret == pin) {
        return Map<String, dynamic>.from(user);
      }
      if (secret == demoPassword) {
        return Map<String, dynamic>.from(user);
      }
    }
    return null;
  }

  static bool verifyOtp(String code) => code.trim() == demoOtp;

  static Map<String, dynamic> register({
    required String name,
    required String surname,
    required String phone,
    String? pin,
  }) {
    return {
      'name': name,
      'surname': surname,
      'phone': normalizePhone(phone),
      'balance': 50000.0,
      'cashback': 0.0,
      'is_premium': false,
      if (pin != null && pin.isNotEmpty) 'pin': pin,
    };
  }

  static Future<void> saveSession(Map<String, dynamic> user) async {
    await _saveRegistered(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
