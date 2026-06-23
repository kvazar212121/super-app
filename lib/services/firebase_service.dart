import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'callkit_service.dart';

/// Firebase Orqa fon (Background) xabarlarini tutib oluvchi funksiya
/// DIQQAT: Bu funksiya asosiy ilovadan tashqarida (boshqa izolyatsiyada) ishlaydi.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("FCM Background xabar qabul qilindi: ${message.messageId}");

  // Agar xabar qo'ng'iroq (call) turida bo'lsa, CallKit'ni chaqiramiz
  if (message.data['type'] == 'incoming_call') {
    final callerId = message.data['caller_id']?.toString() ?? '0';
    final callerName = message.data['caller_name']?.toString() ?? 'Noma\\'lum';
    
    // CallKitService orqali qora ekranda qo'ng'iroqni ko'rsatish
    await CallKitService().showIncomingCall(
      callerId: int.tryParse(callerId) ?? 0, 
      callerName: callerName,
    );
  }
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._();
  factory FirebaseService() => _instance;
  FirebaseService._();

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      
      // Orqa fondagi xabarlarni tinglash
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Bildirishnomalar uchun ruxsat so'rash
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: Foydalanuvchi ruxsat berdi');
      }

      // Tokenni olish (Buni backend ga yuborishingiz kerak)
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token: $token");
      
      // Ilova ochiq turganda (Foreground) kelgan xabarlarni tutish
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground xabar qabul qilindi: ${message.messageId}');

        if (message.data['type'] == 'incoming_call') {
          final callerId = message.data['caller_id']?.toString() ?? '0';
          final callerName = message.data['caller_name']?.toString() ?? 'Noma\\'lum';
          
          CallKitService().showIncomingCall(
            callerId: int.tryParse(callerId) ?? 0,
            callerName: callerName,
          );
        }
      });
    } catch (e) {
      debugPrint("FCM Initialize error: $e");
    }
  }
}
