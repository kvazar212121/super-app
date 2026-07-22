import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'models/alarm.dart';
import 'screens/alarm/alarm_ring_screen.dart';
import 'l10n/locale_controller.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/calls/call_screen.dart';
import 'services/call_service.dart';
import 'services/notification_helper.dart';
import 'services/callkit_service.dart';
import 'services/meal_reminder_service.dart';
import 'screens/calorie/meal_check_dialog.dart';

import 'package:flutter/services.dart';
import 'services/call_history_service.dart';
import 'services/weather_service.dart';
import 'services/firebase_service.dart';
import 'services/feature_service.dart';

import 'providers/saved_places_provider.dart';
import 'app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge mode for transparent system navigation and status bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await NotificationHelper().init();
  await CallHistoryService().init();

  // Budilnik jiringlaganda (bildirishnoma bosilганда yoki to'liq-ekranda) jiringlash ekranini ochamiz
  void openAlarmRing(String jsonPayload) {
    void doPush() {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        try {
          final alarm = Alarm.fromJson(
            Map<String, dynamic>.from(jsonDecode(jsonPayload) as Map),
          );
          Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => AlarmRingScreen(alarm: alarm)),
          );
        } catch (e) {
          debugPrint('openAlarmRing parse error: $e');
        }
      } else {
        Future.delayed(const Duration(milliseconds: 200), doPush);
      }
    }

    doPush();
  }

  NotificationHelper().onAlarmPayload = openAlarmRing;

  // Ilova o'chiq holatdan budilnik orqali ochilgan bo'lsa — darhol jiringlash ekranini ochamiz
  final pending = NotificationHelper().pendingAlarmPayload;
  if (pending != null) {
    NotificationHelper().pendingAlarmPayload = null;
    openAlarmRing(pending);
  }

  // OVQAT eslatmasi bosilganda — "nima yedingiz?" modalini ochamiz.
  void openMealCheck(String mealType) {
    void doShow() {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        MealCheckDialog.show(ctx, mealType);
      } else {
        Future.delayed(const Duration(milliseconds: 250), doShow);
      }
    }

    doShow();
  }

  NotificationHelper().onMealPayload = openMealCheck;
  // Ovqat eslatmalarini (yoqiq bo'lsa) rejalaymiz.
  MealReminderService().init();

  // CallKit tizim darajasidagi qo'ng'iroq UI ni ishga tushirish
  await CallKitService().init();

  // Firebase Orqa fon qo'ng'iroqlarini boshqarishni ishga tushirish
  try {
    await FirebaseService().init();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  // Sovuq startda (ilova yopiq edi) RootShell hali tayyor bo'lmasa — qo'ng'iroq
  // ma'lumotini shu yerda saqlab turamiz va tayyor bo'lgach ko'rsatamiz.
  Map<String, dynamic>? pendingCallData;
  int? pendingCallId;
  String? pendingCallName;

  void safePushCallScreen({
    required int id,
    required String name,
    Map<String, dynamic>? data,
  }) {
    // App hali ishga tushmoqda (splash) bo'lsa — CallScreen'ni push qilsak,
    // splash RootShell'ga o'tganda uni o'chirib yuboradi (gaplashuv oynasi
    // yo'qoladi). Shuning uchun RootShell tayyor bo'lguncha SAQLAB turamiz.
    if (!appReady) {
      pendingCallId = id;
      pendingCallName = name;
      pendingCallData = data;
      return;
    }

    void doPush() {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              isIncoming: true,
              incomingData: data ?? {'sender_id': id, 'sender_name': name},
            ),
          ),
        );
      } else {
        debugPrint(
          'safePushCallScreen: context null, 100ms dan so\'ng qayta uriniladi...',
        );
        Future.delayed(const Duration(milliseconds: 100), doPush);
      }
    }

    doPush();
  }

  // ZAKAZ qo'ng'irog'i (to_role=provider) kelganda — qabul qiluvchini MAJBURAN
  // soha egasi paneliga o'tkazamiz. Shunda telefonni ko'targanda provider
  // tomonida turadi va "Zakaz qo'ng'irog'i" ko'rinadi (aylanib o'tishni to'sadi).
  void maybeForceProviderMode() {
    if (!CallService().isProviderTargetedCall) return;
    final key = CallService().callCategoryKey;
    if (key == null || key.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      Future.delayed(const Duration(milliseconds: 100), maybeForceProviderMode);
      return;
    }
    try {
      ctx.read<AppProvider>().switchToProvider(key);
    } catch (e) {
      debugPrint('maybeForceProviderMode xato: $e');
    }
  }

  // RootShell tayyor bo'lganda — sovuq startda saqlangan qo'ng'iroq ekranini
  // endi ko'rsatamiz (splash tomonidan o'chirilmaydi).
  onAppReady = () {
    // 1) onCallAccepted saqlab qo'ygan kutilayotgan qo'ng'iroq (odatiy yo'l).
    if (pendingCallId != null) {
      final id = pendingCallId!;
      final name = pendingCallName ?? CallService().remoteUserName;
      final data = pendingCallData;
      pendingCallId = null;
      pendingCallName = null;
      pendingCallData = null;
      // Zakaz qo'ng'irog'i bo'lsa — avval provider tomoniga o'tkazamiz.
      maybeForceProviderMode();
      safePushCallScreen(id: id, name: name, data: data);
      return;
    }
    // 2) SOVUQ START tiklash: ba'zi qurilmalarda accept eventi ilova ishga
    //    tushmasdan kelib yo'qoladi. Faol (qabul qilingan) qo'ng'iroq bo'lsa —
    //    uni tiklaymiz (metadatani extra'dan olib, force-switch + CallScreen).
    if (!CallService().inCall) {
      CallKitService().getActiveCallExtra().then((extra) {
        if (extra == null || CallService().inCall) return;
        final id = int.tryParse(extra['callerId']?.toString() ?? '') ?? 0;
        if (id == 0) return;
        final name = extra['callerName']?.toString() ?? 'Noma\'lum';
        CallService().primeIncomingCall(
          callerId: id,
          callerName: name,
          categoryKey: extra['category']?.toString(),
          toRole: extra['to_role']?.toString(),
          intent: extra['intent']?.toString(),
          callId: extra['call_id']?.toString(),
        );
        CallService().answerCall(id, name);
        maybeForceProviderMode();
        safePushCallScreen(id: id, name: name);
      });
    }

    // Sovuq startda ovqat eslatmasi orqali ochilgan bo'lsa — modalni endi ko'rsatamiz.
    final pm = NotificationHelper().pendingMealPayload;
    if (pm != null) {
      NotificationHelper().pendingMealPayload = null;
      openMealCheck(pm);
    }
  };

  // CallKit accept/decline eventlarini CallService ga ulash
  CallKitService().onCallAccepted = (callerId, callerName, extra) {
    final id = int.tryParse(callerId) ?? 0;
    final name = (callerName != 'Noma\'lum')
        ? callerName
        : CallService().remoteUserName;
    // Sovuq startda WS `call_init` kelmagan — zakaz metadatasini (to_role,
    // category, call_id) CallKit `extra`dan olamiz. Shunda force-switch va
    // kelishuv oqimi ilova YOPIQ bo'lgandan javob berilganda ham ishlaydi.
    CallService().primeIncomingCall(
      callerId: id,
      callerName: name,
      categoryKey: extra['category']?.toString(),
      toRole: extra['to_role']?.toString(),
      intent: extra['intent']?.toString(),
      callId: extra['call_id']?.toString(),
    );
    CallService().answerCall(id, name);

    // Zakaz qo'ng'irog'i bo'lsa — CallScreen ochilishidan oldin provider tomoniga o't.
    maybeForceProviderMode();
    safePushCallScreen(id: id, name: name);
  };

  CallKitService().onCallDeclined = (callerId) {
    CallService().rejectCall();
  };

  CallKitService().onCallTimeout = (callerId) {
    CallService().rejectCall();
  };

  // Kiruvchi qo'ng'iroq callback — faqat bloklanganlarni tekshiradi.
  // Avtomatik ravishda ilova ichida CallScreen ochilmaydi.
  // Foydalanuvchi CallKit bildirishnomasidan qabul qilgandagina ochiladi.
  CallService().onIncomingCall = (data) {
    final senderId = data['sender_id'] as int? ?? 0;
    if (CallHistoryService().isUserBlocked(senderId)) {
      debugPrint(
        'Bloklangan foydalanuvchi qo\'ng\'iroq qildi: $senderId. Avtomatik rad etiladi.',
      );
      CallService().rejectCall();
      return;
    }
    // Ilova ochiq (foreground) — jiringlash paytidayoq provider tomoniga o'tkazamiz,
    // shunda telefon ko'tarilganda soha egasi paneli tayyor turadi.
    maybeForceProviderMode();
  };

  // Ob-havo ma'lumotlarini orqa fonda avtomatik yuklashni boshlash (App ochilishini kutib turmasligi uchun await qilinmaydi)
  WeatherService().prefetchWeather();

  // Bo'lim (feature) holatlarini orqa fonda yuklash (admin yopgan bo'limlar uchun)
  FeatureService().load();

  // Ilova tilini (uz/ru) yuklash
  await LocaleController.instance.load();

  initializeDateFormatting('uz_UZ', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(
          create: (_) => SavedPlacesProvider()..loadSavedPlaces(),
        ),
      ],
      child: AnimatedBuilder(
        animation: LocaleController.instance,
        builder: (context, _) => Consumer<AppProvider>(
          builder: (context, appProvider, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'HubServis',
              debugShowCheckedModeBanner: false,
              locale: LocaleController.instance.locale,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
