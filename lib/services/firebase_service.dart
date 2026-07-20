import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'callkit_service.dart';
import 'api_service.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Firebase Orqa fon (Background) xabarlarini tutib oluvchi funksiya
/// DIQQAT: Bu funksiya asosiy ilovadan tashqarida (boshqa izolyatsiyada) ishlaydi.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("FCM Background xabar qabul qilindi: ${message.messageId}");

  // Agar xabar qo'ng'iroq (call) turida bo'lsa, CallKit'ni chaqiramiz
  if (message.data['type'] == 'incoming_call') {
    final callerId = message.data['caller_id']?.toString() ?? '0';
    final callerName = message.data['caller_name']?.toString() ?? "Noma'lum";

    // CallKitService orqali qora ekranda qo'ng'iroqni ko'rsatish.
    // Zakaz metadatasini ham uzatamiz (sovuq startda force-switch + kelishuv uchun).
    await CallKitService().showIncomingCall(
      callerId: int.tryParse(callerId) ?? 0,
      callerName: callerName,
      categoryKey: message.data['category']?.toString(),
      toRole: message.data['to_role']?.toString(),
      intent: message.data['intent']?.toString(),
      callId: message.data['call_id']?.toString(),
    );
  }
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._();
  factory FirebaseService() => _instance;
  FirebaseService._();

  /// Joriy FCM token — backendga saqlanadi (ilova yopiq bo'lsa ham push kelishi uchun).
  String? fcmToken;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();

      // Orqa fondagi xabarlarni tinglash
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Bildirishnomalar uchun ruxsat so'rash
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: Foydalanuvchi ruxsat berdi');
      }

      // Tokenni olish va serverga saqlash (login bo'lgan bo'lsa)
      fcmToken = await FirebaseMessaging.instance.getToken();
      // Token qiymati LOG'ga chiqarilmaydi (maxfiy). Faqat debug'da holat.
      if (kDebugMode) debugPrint("FCM Token olindi: ${fcmToken != null}");
      await syncToken();

      // Token yangilanganda (Firebase vaqti-vaqti bilan yangilaydi) — qayta saqlaymiz
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        fcmToken = t;
        syncToken();
      });

      // Ilova ochiq turganda (Foreground) kelgan xabarlarni tutish
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground xabar qabul qilindi: ${message.messageId}');

        if (message.data['type'] == 'incoming_call') {
          final callerId = message.data['caller_id']?.toString() ?? '0';
          final callerName =
              message.data['caller_name']?.toString() ?? "Noma'lum";

          CallKitService().showIncomingCall(
            callerId: int.tryParse(callerId) ?? 0,
            callerName: callerName,
            categoryKey: message.data['category']?.toString(),
            toRole: message.data['to_role']?.toString(),
            intent: message.data['intent']?.toString(),
            callId: message.data['call_id']?.toString(),
          );
        }
      });
    } catch (e) {
      debugPrint("FCM Initialize error: $e");
    }
  }

  /// FCM token'ni serverga saqlaydi (faqat foydalanuvchi login bo'lgan bo'lsa).
  /// Login muvaffaqiyatli bo'lgach ham chaqirish kerak (auth_provider).
  Future<void> syncToken() async {
    final t = fcmToken;
    if (t == null || !ApiService().hasToken) return;
    try {
      await ApiService().registerFcmToken(t, platform: 'android');
      if (kDebugMode) debugPrint('FCM token serverga saqlandi');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token saqlashda xato: $e');
    }
  }
}
