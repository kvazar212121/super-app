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
    // Oraliqlar bir maromda: bo'limlar orasi 24, ichkarisi 10-12.
    // Yon chekka 18 (oldin 20) — kartalar biroz kengroq nafas oladi.
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeaderWidget(),
            const SizedBox(height: 18),
            const HomePromoSection(),
            const SizedBox(height: 18),
            const CampaignBanner(),
            _buildMainGrid(context),
            const SizedBox(height: 24),
            const ActiveOrderBanner(),
            const SizedBox(height: 24),
            const ProviderPortalEntry(),
            const SizedBox(height: 28),
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
    // Tuzilma:
    //  • "Barcha xizmatlar" — butun enli asosiy tugma
    //  • 6 ta karta: 3 USTUN × 2 QATOR
    //     1-qator: Kaloriya · Fitnes · Rejalarim
    //     2-qator: Moliyam · Aqlli savdo · Budilnik
    //
    // NEGA GridView emas: bu ekran allaqachon SingleChildScrollView ichida.
    // Ichma-ich skroll murakkablik tug'diradi, Row esa oddiy va tez.
    final kartalar = <Widget>[
      _DailyBtn(
        icon: LucideIcons.flame,
        label: 'Kaloriya'.tr,
        color: const Color(0xFFEF4444),
        bgImage: 'assets/images/calorie_counter.jpg',
        onTap: () =>
            _openFeature(context, 'calorie', () => const CalorieHomeScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.dumbbell,
        label: 'Fitnes'.tr,
        color: const Color(0xFF14B8A6),
        bgImage: 'assets/images/fitness_trainer.jpg',
        onTap: () =>
            _openFeature(context, 'fitness', () => const FitnessHomeScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.calendarCheck,
        label: 'Rejalarim'.tr,
        color: const Color(0xFF3B82F6),
        bgImage: 'assets/images/my_plans.jpg',
        onTap: () => _openFeature(context, 'plans', () => const TodoScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.wallet,
        label: 'Moliyam'.tr,
        color: const Color(0xFF22C55E),
        bgImage: 'assets/images/my_finance.jpg',
        onTap: () => _openFeature(
          context,
          'finance',
          () => const FinanceManagerScreen(),
        ),
      ),
      _DailyBtn(
        icon: LucideIcons.shoppingBag,
        label: 'Aqlli savdo'.tr,
        color: const Color(0xFFF97316),
        bgImage: 'assets/images/smart_shopping.jpg',
        onTap: () =>
            _openFeature(context, 'shopping', () => const ShoppingListScreen()),
      ),
      _DailyBtn(
        icon: LucideIcons.alarmClock,
        label: 'Budilnik'.tr,
        color: const Color(0xFF6366F1),
        bgImage: 'assets/images/majburolovchi.jpg',
        onTap: () =>
            _openFeature(context, 'alarm', () => const AlarmHomeScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServicesButton(context),
        const SizedBox(height: 22),
        _SectionTitle(title: 'Kundalik'.tr),
        const SizedBox(height: 12),
        // Har 3 tadan qatorga bo'lamiz. Kartalar soni o'zgarsa
        // (masalan 7 ta bo'lsa) oxirgi qator to'lmasdan qoladi va
        // kartalar cho'zilib ketmasligi uchun bo'sh joy qo'shiladi.
        for (int i = 0; i < kartalar.length; i += 3) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (int j = i; j < i + 3; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(
                  child: j < kartalar.length
                      ? kartalar[j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// "Barcha xizmatlar" — ekranning ASOSIY harakati, shuning uchun
  /// eng ko'zga tashlanadigan element: to'yingan gradient, rangli soya,
  /// yarim tiniq belgi doirasi va o'ngda yo'naltiruvchi strelka.
  Widget _buildServicesButton(BuildContext context) {
    return InkWell(
      onTap: () => _openFeature(
        context,
        'services',
        () => const AllCategoriesScreen(showBackButton: true),
        needAuth: false,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 66,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            // Rangli soya — tugma fondan "suzib" turgandek ko'rinadi.
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.42),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Belgi uchun yarim tiniq oq doira — gradient ustida ajralib turadi
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                LucideIcons.layoutGrid,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Barcha xizmatlar'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Foydalanuvchiga tugma ortida NIMA borligini aytadi.
                    'Usta, tozalash, salon va boshqalar'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi — chapda rangli vertikal chiziq + qalin yozuv.
/// Ekranni mantiqiy bo'laklarga ajratadi, ko'z osongina topadi.
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

/// Kundalik bo'lim kartasi.
///
/// DIZAYN QARORI: rasm butun kartani to'ldiradi, yozuv esa pastdagi
/// TO'Q RANGLI TASMA ustida turadi. Nega gradient emas:
///   • Bo'lim rasmlari OQ fonli (3D render). Shaffof qora gradient
///     oq fon ustida iflos kulrang dog' bo'lib ko'rinardi.
///   • To'q tasma esa qat'iy chegara beradi — toza va bir xil chiqadi,
///     rasm qanday bo'lishidan qat'i nazar.
///
/// Tasma rangi bo'limning o'z rangidan olinadi (to'qlashtirilgan), shuning
/// uchun har karta o'z shaxsiyatini saqlaydi, lekin yaxlit ko'rinadi.
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
    // Bo'lim rangini to'qlashtiramiz — oq matn ustida kontrast yetarli bo'lsin.
    final hsl = HSLColor.fromColor(color);
    final tasmaRang = hsl
        .withLightness((hsl.lightness * 0.55).clamp(0.18, 0.34))
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 0.75))
        .toColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        // 3 ustunda karta eni ~110px. 1:1.12 nisbat kvadratga yaqin,
        // ko'zga muvozanatli ko'rinadi.
        height: 124,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            // Ikki qavatli soya: yumshoq keng + aniq yaqin.
            // Kartani fondan "ko'tarib" turadi.
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.13),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1-qatlam: rasm butun kartani to'ldiradi
            if (bgImage != null)
              Image.asset(bgImage!, fit: BoxFit.cover)
            else
              Container(
                color: color.withValues(alpha: 0.12),
                child: Center(child: Icon(icon, color: color, size: 32)),
              ),

            // 2-qatlam: yuqori chapda rangli ikon nishoni
            Positioned(
              top: 7,
              left: 7,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 13),
              ),
            ),

            // 3-qatlam: pastda to'q rangli tasma + nomi
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      tasmaRang.withValues(alpha: 0.90),
                      tasmaRang,
                    ],
                  ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    height: 1.1,
                    letterSpacing: -0.2,
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
