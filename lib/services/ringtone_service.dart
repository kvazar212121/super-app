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

  /// Chiquvchi qo'ng'iroq uchun kutish ovozi — klassik "tuut ... tuut" ringback.
  /// ESLATMA: avval bu yerda tizim RINGTONE'i (kiruvchi melodiya) chalinardi —
  /// bu xato edi. Endi maxsus generatsiya qilingan 425Hz ringback (1s ton +
  /// 4s pauza, WhatsApp/telefon standartidagi kabi) asset'dan chalinadi.
  Future<void> playDialTone() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      await FlutterRingtonePlayer().play(
        fromAsset: 'assets/sounds/ringback.wav',
        looping: true,
        volume: 0.6,
        asAlarm: false,
      );
      debugPrint('RingtoneService: Ringback (tuut-tuut) boshlandi');
    } catch (e) {
      debugPrint('RingtoneService: Ringback xatolik — $e');
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
