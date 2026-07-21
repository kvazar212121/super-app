import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

/// Tizim darajasidagi qo'ng'iroq UI ni boshqaruvchi xizmat.
/// Android va iOS da WhatsApp uslubidagi kiruvchi qo'ng'iroq ekranini ko'rsatadi.
/// Ekran yopiq bo'lsa ham (fullscreen intent) ishlaydi.
class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  String? _currentCallId;
  final Uuid _uuid = const Uuid();

  // UI eventlari uchun callbacklar. `extra` — CallKit'ga solingan qo'shimcha
  // ma'lumot (category/to_role/intent/call_id) — sovuq startda kerak.
  Function(String callerId, String callerName, Map<String, dynamic> extra)?
  onCallAccepted;
  Function(String callerId)? onCallDeclined;
  Function(String callerId)? onCallTimeout;

  String? get currentCallId => _currentCallId;

  /// CallKit eventlarini tinglashni boshlash
  Future<void> init() async {
    try {
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
        if (event == null) return;

        final body = event.body as Map<dynamic, dynamic>? ?? {};
        final extra = body['extra'] as Map<dynamic, dynamic>? ?? {};
        final callerId = extra['callerId']?.toString() ?? '';
        final callerName = extra['callerName']?.toString() ?? 'Noma\'lum';
        final extraMap = extra.map((k, v) => MapEntry(k.toString(), v));

        debugPrint('CallKit event: ${event.event}, callerId: $callerId');

        switch (event.event) {
          case Event.actionCallAccept:
            debugPrint('CallKit: Qo\'ng\'iroq qabul qilindi');
            onCallAccepted?.call(callerId, callerName, extraMap);
            break;
          case Event.actionCallDecline:
            debugPrint('CallKit: Qo\'ng\'iroq rad etildi');
            onCallDeclined?.call(callerId);
            break;
          case Event.actionCallTimeout:
            debugPrint('CallKit: Qo\'ng\'iroq vaqti tugadi');
            onCallTimeout?.call(callerId);
            break;
          case Event.actionCallEnded:
            debugPrint('CallKit: Qo\'ng\'iroq tugatildi');
            _currentCallId = null;
            break;
          default:
            debugPrint('CallKit: Boshqa event — ${event.event}');
        }
      });

      debugPrint('CallKitService: Event listener o\'rnatildi');
    } catch (e) {
      debugPrint('CallKitService: Init xatolik — $e');
    }
  }

  /// Tizim darajasidagi kiruvchi qo'ng'iroq ekranini ko'rsatish.
  /// [categoryKey]/[toRole]/[intent]/[callId] — sovuq startda javob berilganda
  /// force-switch va kelishuv oqimi uchun `extra`ga solinadi.
  Future<void> showIncomingCall({
    required String callerName,
    required int callerId,
    String? categoryKey,
    String? toRole,
    String? intent,
    String? callId,
  }) async {
    _currentCallId = _uuid.v4();

    try {
      final params = CallKitParams(
        id: _currentCallId!,
        nameCaller: callerName,
        appName: 'HubServis',
        // TODO(security): avatar URL faqat autentifikatsiyalangan endpointdan olinishi kerak
        avatar: '',
        handle: 'Internet qo\'ng\'iroq',
        type: 0, // 0 = Audio call
        duration: 30000, // 30 soniya kutish
        textAccept: 'Qabul qilish',
        textDecline: 'Rad etish',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: 'O\'tkazib yuborilgan qo\'ng\'iroq',
          callbackText: 'Qayta qo\'ng\'iroq',
        ),
        extra: <String, dynamic>{
          'callerId': callerId.toString(),
          'callerName': callerName,
          'category': categoryKey ?? '',
          'to_role': toRole ?? '',
          'intent': intent ?? '',
          'call_id': callId ?? '',
        },
        headers: <String, dynamic>{},
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#1A1A2E',
          actionColor: '#00D26A',
          textColor: '#FFFFFF',
          isShowFullLockedScreen: true,
        ),
        ios: const IOSParams(
          iconName: 'AppIcon',
          handleType: 'generic',
          supportsVideo: false,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'voiceChat',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);
      debugPrint(
        'CallKit: Kiruvchi qo\'ng\'iroq ekrani ko\'rsatildi — $callerName',
      );
    } catch (e) {
      debugPrint('CallKit: showIncomingCall xatolik — $e');
    }
  }

  /// Chiquvchi qo'ng'iroq holatini ko'rsatish (tizim notification)
  Future<void> showOutgoingCall({
    required String callerName,
    required int callerId,
  }) async {
    _currentCallId = _uuid.v4();

    try {
      final params = CallKitParams(
        id: _currentCallId!,
        nameCaller: callerName,
        appName: 'HubServis',
        handle: 'Internet qo\'ng\'iroq',
        type: 0,
        extra: <String, dynamic>{
          'callerId': callerId.toString(),
          'callerName': callerName,
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          backgroundColor: '#1A1A2E',
          actionColor: '#00D26A',
          textColor: '#FFFFFF',
        ),
      );

      await FlutterCallkitIncoming.startCall(params);
      debugPrint('CallKit: Chiquvchi qo\'ng\'iroq boshlandi — $callerName');
    } catch (e) {
      debugPrint('CallKit: showOutgoingCall xatolik — $e');
    }
  }

  /// Barcha faol qo'ng'iroqlarni tugatish
  Future<void> endAllCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
      _currentCallId = null;
      debugPrint('CallKit: Barcha qo\'ng\'iroqlar tugatildi');
    } catch (e) {
      debugPrint('CallKit: endAllCalls xatolik — $e');
    }
  }

  /// Aniq bir qo'ng'iroqni tugatish
  Future<void> endCall() async {
    if (_currentCallId == null) return;
    try {
      await FlutterCallkitIncoming.endCall(_currentCallId!);
      _currentCallId = null;
      debugPrint('CallKit: Qo\'ng\'iroq tugatildi');
    } catch (e) {
      debugPrint('CallKit: endCall xatolik — $e');
    }
  }

  /// Android 14+ da Play Marketdan tashqari o'rnatilgan ilovaga "to'liq
  /// ekranli bildirishnoma" (full-screen intent) ruxsati AVTOMATIK berilmaydi —
  /// natijada ekran o'chiq bo'lsa chaqiruv OVOZI keladi-yu, EKRAN UYG'ONMAYDI.
  /// Bu metod ruxsat bor-yo'qligini tekshiradi (eski Androidlarda doim true).
  Future<bool> canUseFullScreenIntent() async {
    try {
      final res = await FlutterCallkitIncoming.canUseFullScreenIntent();
      return res == true;
    } catch (_) {
      return true; // API mavjud bo'lmasa (eski Android) — muammo ham yo'q
    }
  }

  /// Tizim sozlamalarida "To'liq ekranli bildirishnomalar" sahifasini ochadi —
  /// foydalanuvchi ruxsatni yoqib qo'yadi (chaqiruvda ekran yonishi uchun).
  Future<void> requestFullIntentPermission() async {
    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      debugPrint('CallKit: requestFullIntentPermission xato — $e');
    }
  }

  /// SOVUQ START tiklash: ba'zi qurilmalarda `onEvent` accept eventi ilova
  /// hali ishga tushmaganda kelib, yo'qolishi mumkin. Ilova tayyor bo'lganda
  /// bu metod FAOL (qabul qilingan) qo'ng'iroq bor-yo'qligini tekshiradi va
  /// uning `extra`sini qaytaradi — main.dart shu bilan CallScreen'ni tiklaydi.
  Future<Map<String, dynamic>?> getActiveCallExtra() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        final first = calls.first;
        if (first is Map) {
          final extra = first['extra'];
          if (extra is Map) {
            return extra.map((k, v) => MapEntry(k.toString(), v));
          }
        }
      }
    } catch (e) {
      debugPrint('CallKit: getActiveCallExtra xato — $e');
    }
    return null;
  }
}
