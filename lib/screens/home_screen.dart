import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../screens/todo_screen.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/finance_manager_screen.dart';
import '../screens/all_categories_screen.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../screens/calorie/calorie_home_screen.dart';
import '../screens/fitness/fitness_home_screen.dart';
import '../screens/alarm/alarm_home_screen.dart';
import '../screens/chat_screen.dart';
import '../providers/auth_provider.dart';
import '../services/feature_service.dart';
import '../l10n/locale_controller.dart';
import 'premium/premium_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeaderWidget(),
            const SizedBox(height: 22),
            const HomePromoSection(),
            const SizedBox(height: 22),
            _buildMainGrid(context),
            const SizedBox(height: 22),
            const ActiveOrderBanner(),
            const SizedBox(height: 22),
            const ProviderPortalEntry(),
          ],
        ),
      ),
    );
  }

  /// Bo'lim yopiq bo'lsa "tez orada" ko'rsatadi, aks holda (kerak bo'lsa auth tekshirib) ochadi.
  Future<void> _openFeature(
    BuildContext context,
    String key,
    Widget Function() builder, {
    bool needAuth = true,
  }) async {
    if (!FeatureService().isEnabled(key)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Tez orada 🚧'.tr),
          content: Text(FeatureService().message(key)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tushunarli'.tr),
            ),
          ],
        ),
      );
      return;
    }
    final isPremiumFeature = FeatureService().isPremiumFeature(key);
    // Premium bo'lim yoki auth talab qilinsa — avval login shart
    if (isPremiumFeature || needAuth) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()),
        );
        return;
      }
    }
    // Premium bo'lim — serverdan eng so'nggi holatni tekshirib, premium bo'lmasa obuna ekraniga
    if (isPremiumFeature) {
      await FeatureService().refreshPremium();
      if (!FeatureService().isUserPremium) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  Widget _buildMainGrid(BuildContext context) {
    // Karta tartibi (foydalanuvchi so'roviga ko'ra):
    //  1-qator: Barcha xizmatlar · AI Yordamchi
    //  2-qator: Kaloriya · Fitnes
    //  3-qator: Rejalarim · Mening moliyam
    //  4-qator: Aqlli savdo · Majburlovchi budilnik
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.layoutGrid,
                label: 'Barcha xizmatlar'.tr,
                color: Colors.purpleAccent,
                bgImage: 'assets/images/all_services.jpg',
                onTap: () => _openFeature(
                  context,
                  'services',
                  () => const AllCategoriesScreen(showBackButton: true),
                  needAuth: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.bot,
                label: 'AI Yordamchi'.tr,
                color: const Color(0xFF06B6D4),
                bgImage: 'assets/images/ai.jpg',
                onTap: () => _openFeature(
                  context,
                  'ai_chat',
                  () => const ChatScreen(),
                  needAuth: false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.flame,
                label: 'Kaloriya hisoblagich'.tr,
                color: Colors.redAccent,
                bgImage: 'assets/images/calorie_counter.jpg',
                onTap: () => _openFeature(
                  context,
                  'calorie',
                  () => const CalorieHomeScreen(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.dumbbell,
                label: 'Fitnes trener'.tr,
                color: Colors.tealAccent,
                bgImage: 'assets/images/fitness_trainer.jpg',
                onTap: () => _openFeature(
                  context,
                  'fitness',
                  () => const FitnessHomeScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.calendarCheck,
                label: 'Rejalarim'.tr,
                color: Colors.blueAccent,
                bgImage: 'assets/images/my_plans.jpg',
                onTap: () =>
                    _openFeature(context, 'plans', () => const TodoScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.wallet,
                label: 'Mening moliyam'.tr,
                color: Colors.greenAccent,
                bgImage: 'assets/images/my_finance.jpg',
                onTap: () => _openFeature(
                  context,
                  'finance',
                  () => const FinanceManagerScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.shoppingBag,
                label: 'Aqlli savdo'.tr,
                color: Colors.orangeAccent,
                bgImage: 'assets/images/smart_shopping.jpg',
                onTap: () => _openFeature(
                  context,
                  'shopping',
                  () => const ShoppingListScreen(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.alarmClock,
                label: 'Majburlovchi budilnik'.tr,
                color: Colors.indigoAccent,
                bgImage: 'assets/images/majburolovchi.jpg',
                onTap: () => _openFeature(
                  context,
                  'alarm',
                  () => const AlarmHomeScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? bgImage;

  const _DailyBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.bgImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 135, // Uzunasiga cho'zildi
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip
            .antiAlias, // Rasmni burchaklardan chiqib ketmasligi uchun qirqamiz
        // Poster uslub: rasm butun kartani to'ldiradi, pastda qora gradient +
        // oq yozuv ("Barcha xizmatlar" kartalari bilan bir xil).
        child: Stack(
          fit: StackFit.expand,
          children: [
            bgImage != null
                ? Image.asset(bgImage!, fit: BoxFit.cover)
                : Container(
                    color: isDark
                        ? Color.lerp(const Color(0xFF1E293B), color, 0.15)
                        : Color.lerp(Colors.white, color, 0.1),
                    child: Icon(icon, color: color, size: 34),
                  ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.94),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Text(
                  label.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.1,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
