import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/calls/call_screen.dart';
import 'services/call_service.dart';
import 'services/notification_helper.dart';
import 'services/callkit_service.dart';

import 'package:flutter/services.dart';
import 'services/call_history_service.dart';

/// Global navigator key — har qanday joydan CallScreen ochish uchun
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge mode for transparent system navigation and status bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await NotificationHelper().init();
  await CallHistoryService().init();

  // CallKit tizim darajasidagi qo'ng'iroq UI ni ishga tushirish
  await CallKitService().init();

  void safePushCallScreen({required int id, required String name, Map<String, dynamic>? data}) {
    void doPush() {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              isIncoming: true,
              incomingData: data ?? {
                'sender_id': id,
                'sender_name': name,
              },
            ),
          ),
        );
      } else {
        debugPrint('safePushCallScreen: context null, 100ms dan so\'ng qayta uriniladi...');
        Future.delayed(const Duration(milliseconds: 100), doPush);
      }
    }
    doPush();
  }

  // CallKit accept/decline eventlarini CallService ga ulash
  CallKitService().onCallAccepted = (callerId, callerName) {
    final id = int.tryParse(callerId) ?? 0;
    final name = (callerName != 'Noma\'lum') ? callerName : CallService().remoteUserName;
    CallService().answerCall(id, name);

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
      debugPrint('Bloklangan foydalanuvchi qo\'ng\'iroq qildi: $senderId. Avtomatik rad etiladi.');
      CallService().rejectCall();
      return;
    }
  };

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
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'HubServis',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
