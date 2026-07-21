import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Internet holatini kuzatuvchi singleton xizmat.
///
/// Nima uchun kerak:
///  - Ilova oflayn ochilsa, internet talab qiladigan joylarda QIZIL
///    "Internetga ulaning" banneri ko'rsatiladi (RootShell ustida, global).
///  - Chaqiruv boshlashdan oldin tekshiriladi — internet yo'q bo'lsa
///    chaqiruv umuman amalga oshmaydi ("Internet yo'q" xabari).
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true; // optimistik boshlanadi, init() aniqlashtiradi
  bool get isOnline => _isOnline;

  /// Kuzatishni boshlash (RootShell'da bir marta chaqiriladi).
  Future<void> init() async {
    if (_sub != null) return; // takror init bo'lmasin
    try {
      _apply(await _connectivity.checkConnectivity());
      _sub = _connectivity.onConnectivityChanged.listen(_apply);
    } catch (e) {
      debugPrint('ConnectivityService init xato: $e');
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final online =
        results.isNotEmpty && !results.contains(ConnectivityResult.none) ||
        results.any(
          (r) => r != ConnectivityResult.none,
        );
    if (online != _isOnline) {
      _isOnline = online;
      debugPrint('Connectivity: ${online ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  /// HAQIQIY internet borligini tekshirish (chaqiruv oldidan).
  /// Wi-Fi ulangan-u internet yo'q holatni ham ushlaydi (DNS so'rov).
  Future<bool> hasInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
      // Tarmoq bor — endi haqiqiy internetni tez DNS bilan tekshiramiz.
      final lookup = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (e) {
      debugPrint('hasInternet tekshiruv xatosi: $e');
      // Aniqlab bo'lmadi — tarmoq holatiga tayanamiz (bloklab qo'ymaslik uchun)
      return _isOnline;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
