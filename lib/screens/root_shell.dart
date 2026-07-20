import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../config/provider_category_config.dart';
import '../app_navigator.dart';
import 'main_screen.dart';
import 'provider_side/unified_provider_dashboard_screen.dart';

/// Aktiv rejimga qarab shell tanlaydi:
///  - user rejim  → MainScreen (oddiy foydalanuvchi)
///  - provider rejim → UnifiedProviderDashboardScreen (soha egasi paneli)
///
/// Rejim AppProvider'da SharedPreferences bilan saqlanadi — ilova qayta
/// ochilganda oxirgi rejim tiklanadi (soha egasi bo'lsa panelida qoladi).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  @override
  void initState() {
    super.initState();
    // Saqlangan rejimni tiklaymiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().loadActiveMode();
      // Ilova ildizi tayyor — sovuq startda kutilayotgan qo'ng'iroq ekranini
      // endi xavfsiz ko'rsatsak bo'ladi (splash tomonidan o'chirilmaydi).
      appReady = true;
      onAppReady?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    // Provider rejimi + saqlangan kategoriya kaliti config'da mavjud bo'lsa —
    // soha egasi paneli. `user.isProvider` bayrog'iga TAYANMAYMIZ: kalit faqat
    // haqiqiy `/mine` provideri uchun `switchToProvider` orqali o'rnatiladi,
    // profil bayrog'i esa backendda kechikishi/false bo'lishi mumkin.
    if (app.isProviderMode && app.activeProviderKey != null) {
      final config = ProviderCategoryConfig.byCategoryKey(
        app.activeProviderKey!,
      );
      if (config != null) {
        return UnifiedProviderDashboardScreen(config: config);
      }
    }
    return const MainScreen();
  }
}
