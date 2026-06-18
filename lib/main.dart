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

import 'services/call_history_service.dart';

/// Global navigator key — har qanday joydan CallScreen ochish uchun
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper().init();
  await CallHistoryService().init();

  // Kiruvchi qo'ng'iroq callback — har qanday sahifada bo'lsa ham CallScreen ochadi
  CallService().onIncomingCall = (data) {
    final senderId = data['sender_id'] as int? ?? 0;
    if (CallHistoryService().isUserBlocked(senderId)) {
      debugPrint('Bloklangan foydalanuvchi qo\'ng\'iroq qildi: $senderId. Avtomatik rad etiladi.');
      CallService().rejectCall();
      return;
    }

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
