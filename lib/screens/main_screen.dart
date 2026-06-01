import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass/glass_bottom_bar.dart';
import '../widgets/glass/mesh_background.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  AppProvider? _appProvider;

  static const _navItems = [
    GlassNavItem(icon: LucideIcons.home, label: 'Asosiy'),
    GlassNavItem(icon: LucideIcons.search, label: 'Qidiruv'),
    GlassNavItem(icon: LucideIcons.briefcase, label: 'Buyurtmalar'),
    GlassNavItem(icon: LucideIcons.user, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appProvider = context.read<AppProvider>();
      _appProvider!.addListener(_onAppChanged);
      _appProvider!.fetchInitialData();
    });
  }

  @override
  void dispose() {
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
          label: 'Ko\'rish',
          onPressed: () => setState(() => _selectedIndex = 2),
        ),
      ),
    );
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;

    return Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: _screens[_selectedIndex],
          bottomNavigationBar: GlassBottomBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: _navItems,
          ),
        ),
      ],
    );
  }
}
