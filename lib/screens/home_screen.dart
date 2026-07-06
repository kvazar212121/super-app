import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/daily_utilities_widget.dart';
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
  void _openFeature(BuildContext context, String key, Widget Function() builder, {bool needAuth = true}) {
    if (!FeatureService().isEnabled(key)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tez orada 🚧'),
          content: Text(FeatureService().message(key)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tushunarli')),
          ],
        ),
      );
      return;
    }
    // Premium bo'lim — foydalanuvchi premium bo'lmasa obuna ekraniga
    if (FeatureService().isPremiumFeature(key) && !FeatureService().isUserPremium) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
      return;
    }
    if (needAuth) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
        return;
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  Widget _buildMainGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.calendarCheck,
                label: 'Rejalarim',
                color: Colors.blueAccent,
                bgImage: 'assets/images/my_plans.jpg',
                onTap: () => _openFeature(context, 'plans', () => const TodoScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.wallet,
                label: 'Mening moliyam',
                color: Colors.greenAccent,
                bgImage: 'assets/images/my_finance.jpg',
                onTap: () => _openFeature(context, 'finance', () => const FinanceManagerScreen()),
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
                label: 'Aqlli savdo',
                color: Colors.orangeAccent,
                bgImage: 'assets/images/smart_shopping.jpg',
                onTap: () => _openFeature(context, 'shopping', () => const ShoppingListScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.layoutGrid,
                label: 'Barcha xizmatlar',
                color: Colors.purpleAccent,
                bgImage: 'assets/images/all_services.jpg',
                onTap: () => _openFeature(context, 'services', () => const AllCategoriesScreen(), needAuth: false),
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
                label: 'Kaloriya hisoblagich',
                color: Colors.redAccent,
                bgImage: 'assets/images/calorie_counter.jpg',
                onTap: () => _openFeature(context, 'calorie', () => const CalorieHomeScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.dumbbell,
                label: 'Fitnes trener',
                color: Colors.tealAccent,
                bgImage: 'assets/images/fitness_trainer.jpg',
                onTap: () => _openFeature(context, 'fitness', () => const FitnessHomeScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.alarmClock,
                label: 'Majburlovchi budilnik',
                color: Colors.indigoAccent,
                onTap: () => _openFeature(context, 'alarm', () => const AlarmHomeScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.bot,
                label: 'AI Yordamchi',
                color: const Color(0xFF06B6D4),
                onTap: () => _openFeature(context, 'ai_chat', () => const ChatScreen(), needAuth: false),
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
          border: Border.all(color: isDark ? color : color),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Rasmni burchaklardan chiqib ketmasligi uchun qirqamiz
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rasm joylashgan yuqori qism (Ramka)
            Expanded(
              child: bgImage != null
                  ? Image.asset(
                      bgImage!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: isDark ? Color.lerp(const Color(0xFF1E293B), color, 0.15) : Color.lerp(Colors.white, color, 0.1),
                      child: Icon(icon, color: color, size: 30),
                    ),
            ),
            // Ramkadan ajratib turuvchi chiziq
            Container(
              height: 1.5,
              color: isDark ? color : color,
            ),
            // Kichik yozuv maydoni (Oq fon va qora yozuv)
            Container(
              color: Colors.white, // Oq fon
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.black, // Qora yozuv
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
