import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      context.read<AppProvider>().fetchInitialData();
    });
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
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
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
