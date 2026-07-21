import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../config/provider_category_config.dart';
import '../app_navigator.dart';
import '../services/call_service.dart';
import '../services/connectivity_service.dart';
import 'main_screen.dart';
import 'provider_side/unified_provider_dashboard_screen.dart';

/// Aktiv rejimga qarab shell tanlaydi:
///  - user rejim  → MainScreen (oddiy foydalanuvchi)
///  - provider rejim → UnifiedProviderDashboardScreen (soha egasi paneli)
///
/// Rejim AppProvider'da SharedPreferences bilan saqlanadi — ilova qayta
/// ochilganda oxirgi rejim tiklanadi (soha egasi bo'lsa panelida qoladi).
///
/// Qo'shimcha mas'uliyatlar (chaqiruv mantiqiga tegishli):
///  - Qo'ng'iroq WebSocket'i SHU YERDA ulanadi — oldin faqat MainScreen'da
///    ulanardi, provider panelida ochilganda WS umuman ulanmay, ilova OCHIQ
///    tursa ham chaqiruv kelmasdi (3-xato). Endi ikkala rejimda ham ulanadi.
///  - Ilova pauzadan qaytganda (resume) WS qayta tekshiriladi/ulanadi.
///  - Internet holati kuzatilib, oflaynda tepada QIZIL banner ko'rsatiladi.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Internet kuzatuvi (oflayn banner + chaqiruv bloklash uchun)
    ConnectivityService().init();
    // Saqlangan rejimni tiklaymiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().loadActiveMode();
        // Chaqiruv WS — login bo'lgan bo'lsa REJIMDAN QAT'I NAZAR ulanadi.
        if (context.read<AuthProvider>().isAuthenticated) {
          CallService().connectWebSocket();
        }
      }
      // Ilova ildizi tayyor — sovuq startda kutilayotgan qo'ng'iroq ekranini
      // endi xavfsiz ko'rsatsak bo'ladi (splash tomonidan o'chirilmaydi).
      appReady = true;
      onAppReady?.call();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ilova qaytganda WS uzilib qolgan bo'lishi mumkin — qayta ulaymiz,
    // shunda ochiq holatda chaqiruv doim keladi.
    if (state == AppLifecycleState.resumed) {
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        CallService().connectWebSocket();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    // Provider rejimi + saqlangan kategoriya kaliti config'da mavjud bo'lsa —
    // soha egasi paneli. `user.isProvider` bayrog'iga TAYANMAYMIZ: kalit faqat
    // haqiqiy `/mine` provideri uchun `switchToProvider` orqali o'rnatiladi,
    // profil bayrog'i esa backendda kechikishi/false bo'lishi mumkin.
    Widget shell;
    if (app.isProviderMode && app.activeProviderKey != null) {
      final config = ProviderCategoryConfig.byCategoryKey(
        app.activeProviderKey!,
      );
      shell = (config != null)
          ? UnifiedProviderDashboardScreen(config: config)
          : const MainScreen();
    } else {
      shell = const MainScreen();
    }

    // Oflayn bo'lsa — butun ilova ustida (qaysi ekran bo'lishidan qat'i nazar)
    // tepada QIZIL "Internetga ulaning" banneri. Onlayn qaytishi bilan yo'qoladi.
    return Stack(
      children: [
        shell,
        AnimatedBuilder(
          animation: ConnectivityService(),
          builder: (context, _) {
            if (ConnectivityService().isOnline) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  color: const Color(0xFFDC2626),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 6,
                    bottom: 8,
                    left: 12,
                    right: 12,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Internet aloqasi yo\'q — Internetga ulaning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
