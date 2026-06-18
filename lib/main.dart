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

import 'services/call_history_service.dart';

/// Global navigator key — har qanday joydan CallScreen ochish uchun
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper().init();
  await CallHistoryService().init();

  // CallKit tizim darajasidagi qo'ng'iroq UI ni ishga tushirish
  await CallKitService().init();

  // CallKit accept/decline eventlarini CallService ga ulash
  CallKitService().onCallAccepted = (callerId) {
    final id = int.tryParse(callerId) ?? 0;
    final name = CallService().remoteUserName;
    CallService().answerCall(id, name);

    // CallScreen ni ochish
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => CallScreen(
            isIncoming: true,
            incomingData: {
              'sender_id': id,
              'sender_name': name,
            },
          ),
        ),
      );
    }
  };

  CallKitService().onCallDeclined = (callerId) {
    CallService().rejectCall();
  };

  CallKitService().onCallTimeout = (callerId) {
    CallService().rejectCall();
  };

  // Kiruvchi qo'ng'iroq callback — har qanday sahifada bo'lsa ham CallScreen ochadi
  CallService().onIncomingCall = (data) {
    final senderId = data['sender_id'] as int? ?? 0;
    if (CallHistoryService().isUserBlocked(senderId)) {
      debugPrint('Bloklangan foydalanuvchi qo\'ng\'iroq qildi: $senderId. Avtomatik rad etiladi.');
      CallService().rejectCall();
      return;
    }

    // CallKit tizim ekranidan qabul qilinganda CallScreen ochiladi (yuqorida sozlangan).
    // Bu yerda faqat ilovaning o'zi ochiq bo'lganda in-app CallScreen ochish uchun ishlatiladi.
    // CallKit allaqachon CallService._handleSignalingMessage da chaqirilgan.
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => CallScreen(isIncoming: true, incomingData: data),
        ),
      );
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
            themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
