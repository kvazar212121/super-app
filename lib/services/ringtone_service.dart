import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Qo'ng'iroq ovozlarini boshqaruvchi singleton xizmat.
/// Kiruvchi qo'ng'iroqda ringtone, chiquvchi qo'ng'iroqda dial tone chaladi.
class RingtoneService {
  static final RingtoneService _instance = RingtoneService._internal();
  factory RingtoneService() => _instance;
  RingtoneService._internal();

  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Kiruvchi qo'ng'iroq uchun tizim ringtonini chalish
  Future<void> playRingtone() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.electronic,
        looping: true,
        volume: 1.0,
        asAlarm: false,
      );
      debugPrint('RingtoneService: Ringtone boshlandi');
    } catch (e) {
      debugPrint('RingtoneService: Ringtone xatolik — $e');
      _isPlaying = false;
    }
  }

  /// Chiquvchi qo'ng'iroq uchun kutish ovozi (dial tone)
  Future<void> playDialTone() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.electronic,
        looping: true,
        volume: 0.5, // Dial tone ovozi pastroq
        asAlarm: false,
      );
      debugPrint('RingtoneService: Dial tone boshlandi');
    } catch (e) {
      debugPrint('RingtoneService: Dial tone xatolik — $e');
      _isPlaying = false;
    }
  }

  /// Barcha ovozlarni to'xtatish
  Future<void> stop() async {
    if (!_isPlaying) return;

    try {
      await FlutterRingtonePlayer().stop();
      debugPrint('RingtoneService: Ovoz to\'xtatildi');
    } catch (e) {
      debugPrint('RingtoneService: To\'xtatish xatolik — $e');
    } finally {
      _isPlaying = false;
    }
  }
}
