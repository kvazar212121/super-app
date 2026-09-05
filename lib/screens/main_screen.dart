import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/call_service.dart';
import '../l10n/locale_controller.dart';
import '../widgets/glass/glass_bottom_bar.dart';
import '../widgets/glass/mesh_background.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'all_categories_screen.dart';
import 'calls/call_history_screen.dart';
import 'chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController = PageController(initialPage: _selectedIndex);
  AppProvider? _appProvider;

  List<GlassNavItem> get _navItems => [
    GlassNavItem(
      icon: LucideIcons.home,
      activeIcon: Icons.home_rounded,
      label: 'Asosiy'.tr,
    ),
    GlassNavItem(
      icon: LucideIcons.layoutGrid,
      activeIcon: Icons.grid_view_rounded,
      label: 'Xizmatlar'.tr,
    ),
    GlassNavItem(
      icon: LucideIcons.sparkles,
      activeIcon: LucideIcons.sparkles,
      label: 'AiHub'.tr,
    ),
    GlassNavItem(
      icon: LucideIcons.messageSquare,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Xabarlar'.tr,
    ),
    GlassNavItem(
      icon: LucideIcons.clipboardList,
      activeIcon: Icons.assignment_rounded,
      label: 'Buyurtmalar'.tr,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appProvider = context.read<AppProvider>();
      _appProvider!.addListener(_onAppChanged);
      _appProvider!.fetchInitialData();

      CallService().connectWebSocket();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _appProvider?.removeListener(_onAppChanged);
    super.dispose();
  }

  void _onAppChanged() {
    if (!mounted || _appProvider == null) return;
    final msg = _appProvider!.consumeStatusToast();
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Ko\'rish'.tr,
          // Buyurtmalar endi alohida tab emas — to'g'ridan-to'g'ri ochamiz.
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
          ),
        ),
      ),
    );
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const AllCategoriesScreen(),
    const ChatScreen(),
    const CallHistoryScreen(),
    // Profil endi header'da (yuqori o'ng) — bu joyда buyurtmalar tabi.
    const OrdersScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MeshBackground(isDark: isDark),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            children: _screens,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            bottom: true,
            top: false,
            left: false,
            right: false,
            child: GlassBottomBar(
              currentIndex: _selectedIndex,
              onTap: (i) {
                // Bosilganini his qildiradi (haptic)
                HapticFeedback.selectionClick();
                // AiHub markaziy orbi — chatni TO'LIQ EKRAN sifatida ochadi
                if (i == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                  return;
                }
                setState(() => _selectedIndex = i);
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
              items: _navItems,
              centerIndex: 2, // AiHub — markaziy jonli orb
              // Orbni bosib turganda — ovoz rejimi (AiHub darrov tinglaydi).
              onCenterLongPress: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatScreen(startVoice: true),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
