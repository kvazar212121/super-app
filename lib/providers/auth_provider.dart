import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/phone_utils.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Auth holati — OTP orqali login/register.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;

  String get displayName {
    if (!_isAuthenticated || _user == null) return 'Mehmon';
    final name = (_user!['name'] as String?)?.trim() ?? '';
    return name.isEmpty ? 'Foydalanuvchi' : name;
  }

  AuthProvider() {
    _api.onTokenExpired = () {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
    };
  }

  Future<bool> tryAutoLogin() async {
    try {
      await _api.loadTokens();
      if (!_api.hasToken) return false;
      final userData = await _api.getMe();
      _user = userData;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      // 401 — token yaroqsiz va refresh ham ishlamadi (interceptor allaqachon
      // refresh qilib ko'rgan). Faqat shu holatda tokenlarni tozalash kerak.
      if (e.response?.statusCode == 401) {
        await _api.clearTokens();
        _isAuthenticated = false;
        _user = null;
        notifyListeners();
        return false;
      }
      // Tarmoq xatoligi (internet yo'q, server o'chiq) — tokenlar saqlanadi,
      // foydalanuvchi kirgan hisoblanadi. Keyingi ulanishda ishlaydi.
      if (_api.hasToken) {
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      // Kutilmagan xatolik — agar token bor bo'lsa, kirgan deb hisoblaymiz
      if (_api.hasToken) {
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendOtp({
    required String phone,
    String purpose = 'auth',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.sendOtp(
        phone: normalizeUzPhone(phone),
        purpose: purpose,
      );
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp({
    required String phone,
    required String code,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.verifyOtp(phone: phone, code: code);
      if (data['user_exists'] == true && data['user'] != null) {
        _user = Map<String, dynamic>.from(data['user'] as Map);
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> register({
    required String name,
    required String surname,
    required String phone,
    required String password,
    required String verificationToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(
        name: name,
        surname: surname,
        phone: phone,
        password: password,
        verificationToken: verificationToken,
      );
      _user = data['user'];
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eski parol login — faqat maxsus holatlar uchun (admin).
  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.login(phone: phone, password: password);
      final userData = await _api.getMe();
      _user = userData;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.deleteMe();
      await logout();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          return detail.first['msg']?.toString() ?? 'Xatolik yuz berdi';
        }
      }
      return e.message ?? 'Tarmoq xatoligi';
    }
    return e.toString();
  }
}
