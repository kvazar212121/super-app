import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';
import '../widgets/top_providers_section.dart';
import '../widgets/campaign_banner.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../screens/todo_screen.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/finance_manager_screen.dart';
import '../screens/all_categories_screen.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../screens/calorie/calorie_home_screen.dart';
import '../screens/fitness/fitness_home_screen.dart';
import '../screens/alarm/alarm_home_screen.dart';
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
            const CampaignBanner(),
            _buildMainGrid(context),
            const SizedBox(height: 22),
            const ActiveOrderBanner(),
            const SizedBox(height: 22),
            const ProviderPortalEntry(),
            const SizedBox(height: 26),
            // Sahifaning ENG PASTI — top reytingli provayderlar.
            // Soha bo'yicha filtrlanadi, "Yana" bilan pastga davom etadi.
            const TopProvidersSection(),
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
    // Tuzilma (foydalanuvchi so'roviga ko'ra):
    //  • Tepada — "Barcha xizmatlar" UZUN TUGMA (butun enli, karta emas).
    //  • So'ng kartalar:
    //     1-qator: Kaloriya · Fitnes
    //     2-qator: Rejalarim · Mening moliyam
    //     3-qator: Aqlli savdo · Majburlovchi budilnik
    //  (AI Yordamchi kartasi olib tashlandi — AiHub endi pastki menyuda.)
    return Column(
      children: [
        _buildServicesButton(context),
        const SizedBox(height: 14),
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

  /// "Barcha xizmatlar" — butun enli UZUN TUGMA (karta emas). Ko'k gradient
  /// fon (rasmsiz), ingichka; chapda belgi+yozuv, o'ngda strelka.
  Widget _buildServicesButton(BuildContext context) {
    return InkWell(
      onTap: () => _openFeature(
        context,
        'services',
        () => const AllCategoriesScreen(showBackButton: true),
        needAuth: false,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 58,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.layoutGrid, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Barcha xizmatlar'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
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
        clipBehavior: Clip.antiAlias,
        // Rasm YUQORIDA (to'liq ko'rinadi, qirqilmaydi), yozuv PASTDA alohida
        // tasmada — rasm yozuv paneli ostida qolib ketmaydi.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: bgImage != null
                  // cover — rasm yuqori qismni butunlay to'ldiradi (cheti/chegarasi
                  // ko'rinmaydi). Yozuv pastда alohida bo'lgani uchun subyekt bekilmaydi.
                  ? SizedBox(
                      width: double.infinity,
                      child: Image.asset(bgImage!, fit: BoxFit.cover),
                    )
                  : Center(child: Icon(icon, color: color, size: 34)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  height: 1.1,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
