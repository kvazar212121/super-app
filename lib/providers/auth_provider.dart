import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

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

  AuthProvider() {
    // Token muddati tugaganda logout
    _api.onTokenExpired = () {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
    };
  }

  /// Ilova boshlanganda saqlangan tokenni tekshirish
  Future<bool> tryAutoLogin() async {
    try {
      await _api.loadTokens();
      if (!_api.hasToken) return false;

      // Token bilan foydalanuvchi ma'lumotlarini olishga urinish
      final userData = await _api.getMe();
      _user = userData;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      // Token eskirgan yoki yaroqsiz
      await _api.clearTokens();
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return false;
    }
  }

  /// Ro'yxatdan o'tish
  Future<bool> register({
    required String name,
    required String surname,
    required String phone,
    required String password,
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

  /// Login
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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

  /// Logout
  Future<void> logout() async {
    await _api.clearTokens();
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Profil ma'lumotlarini yangilash (auth providerda ham)
  void updateUserData(Map<String, dynamic> newData) {
    _user = newData;
    notifyListeners();
  }

  /// Xato xabarini tozalash
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Xatolik xabarini olish
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
