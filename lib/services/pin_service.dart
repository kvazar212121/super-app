import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 4 raqamli PIN kodini qurilmada xavfsiz saqlaydi va boshqaradi.
/// PIN faqat lokal — backendga yuborilmaydi. OTP login bilan bog'liq emas.
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _keyPin = 'hs_app_pin';
  static const _keyEnabled = 'hs_pin_enabled';

  /// PIN yoqilganmi?
  Future<bool> get isEnabled async {
    final val = await _secure.read(key: _keyEnabled);
    return val == 'true';
  }

  /// PIN o'rnatilganmi (qiymat mavjudmi)?
  Future<bool> get hasPin async {
    final pin = await _secure.read(key: _keyPin);
    return pin != null && pin.isNotEmpty;
  }

  /// Yangi PIN ni saqlash
  Future<void> setPin(String pin) async {
    await _secure.write(key: _keyPin, value: pin);
  }

  /// PIN ni yoqish / o'chirish
  Future<void> setEnabled(bool enabled) async {
    await _secure.write(key: _keyEnabled, value: enabled.toString());
  }

  /// PIN ni tekshirish — to'g'ri bo'lsa `true`
  Future<bool> verifyPin(String pin) async {
    final stored = await _secure.read(key: _keyPin);
    return stored != null && stored == pin;
  }

  /// PIN va yoqilish holatini butunlay o'chirish (logout holatida)
  Future<void> clearPin() async {
    await _secure.delete(key: _keyPin);
    await _secure.delete(key: _keyEnabled);
  }
}
