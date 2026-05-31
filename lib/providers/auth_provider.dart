import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/demo_auth_service.dart';

/// Auth holati — login/register/logout va token boshqarish.
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
  bool get isOfflineDemo => !AppConfig.useBackend;

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
    if (!AppConfig.useBackend) {
      final user = await DemoAuthService.loadSession();
      if (user == null) return false;
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    try {
      await _api.loadTokens();
      if (!_api.hasToken) return false;
      final userData = await _api.getMe();
      _user = userData;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      await _api.clearTokens();
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String surname,
    required String phone,
    required String password,
    String? pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!AppConfig.useBackend) {
      await Future.delayed(const Duration(milliseconds: 350));
      final user = DemoAuthService.register(
        name: name.trim(),
        surname: surname.trim(),
        phone: phone,
        pin: pin,
      );
      await DemoAuthService.saveSession(user);
      _user = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final data = await _api.register(
        name: name,
        surname: surname,
        phone: phone,
        password: password,
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

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!AppConfig.useBackend) {
      await Future.delayed(const Duration(milliseconds: 350));
      final user = await DemoAuthService.tryLogin(phone, password);
      if (user == null) {
        _error = 'Telefon yoki parol/PIN noto\'g\'ri';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await DemoAuthService.saveSession(user);
      _user = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final data = await _api.login(phone: phone, password: password);
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

  Future<void> logout() async {
    if (!AppConfig.useBackend) {
      await DemoAuthService.clearSession();
    } else {
      await _api.clearTokens();
    }
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  void updateUserData(Map<String, dynamic> newData) {
    _user = newData;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Server bilan aloqa yo\'q. Internet yoki serverni tekshiring.';
      }
    }
    return 'Xatolik yuz berdi. Qayta urinib ko\'ring.';
  }
}
