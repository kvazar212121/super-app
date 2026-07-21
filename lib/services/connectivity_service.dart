import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

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
  /// Wi-Fi ulangan-u internet yo'q holatni ham ushlaydi.
  ///
  /// MUHIM: tekshiruv ILOVANING O'Z serveriga (hubservis.uz) qilinadi —
  /// chunki qo'ng'iroq/API aynan shu serverga ulanadi. Cloudflare (one.one.one.one)
  /// ba'zi tarmoqlarda (masalan UZ mobil) bloklangan/sekin bo'lishi mumkin, bu esa
  /// internet BOR bo'lsa ham qo'ng'iroqni noto'g'ri bloklaydi.
  /// Tekshiruv aniq javob bermasa — tarmoq bor bo'lsa BLOKLAMAYMIZ.
  Future<bool> hasInternet() async {
    List<ConnectivityResult> results;
    try {
      results = await _connectivity.checkConnectivity();
    } catch (_) {
      return true; // aniqlab bo'lmadi — bloklamaymiz
    }
    // Umuman tarmoq interfeysi yo'q — aniq oflayn.
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }
    // Tarmoq bor — ilovaning o'z hostiga yetib borishni tez tekshiramiz.
    try {
      final host = Uri.parse(AppConfig.apiBaseUrl).host; // hubservis.uz
      final lookup = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (e) {
      // DNS/timeout xatosi — lekin tarmoq interfeysi BOR. Bloklamaymiz
      // (qo'ng'iroq urinib ko'rsin; noto'g'ri "Internet yo'q" chiqmasin).
      debugPrint('hasInternet host tekshiruvi o\'tmadi, tarmoqqa tayanamiz: $e');
      return true;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
