import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';
import '../widgets/ai_assistant_banner.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/daily_utilities_widget.dart';
import '../screens/todo_screen.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/finance_manager_screen.dart';
import '../screens/all_categories_screen.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../providers/auth_provider.dart';
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
            const AIAssistantBanner(),
            const SizedBox(height: 22),
            const ProviderPortalEntry(),
          ],
        ),
      ),
    );
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
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  if (!auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoScreen()));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.wallet,
                label: 'Mening moliyam',
                color: Colors.greenAccent,
                bgImage: 'assets/images/my_finance.png',
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  if (!auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceManagerScreen()));
                  }
                },
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
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  if (!auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.layoutGrid,
                label: 'Barcha xizmatlar',
                color: Colors.purpleAccent,
                bgImage: 'assets/images/all_services.png',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCategoriesScreen())),
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
        height: 100,
        decoration: BoxDecoration(
          color: bgImage != null 
              ? Colors.black
              : (isDark ? Color.lerp(const Color(0xFF1E293B), color, 0.15) : Color.lerp(Colors.white, color, 0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.3)),
          image: bgImage != null ? DecorationImage(
            image: AssetImage(bgImage!),
            fit: BoxFit.cover,
            // colorFilter ni olib tashladik, shunda rasm tiniq chiqadi
          ) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Align(
            alignment: Alignment.bottomCenter, // Yozuvlarni pastga surdik
            child: Stack(
              children: [
                // Qora border (stroke)
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 15, 
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3.0
                      ..color = Colors.black,
                  ),
                ),
                // Oq matn (ichki qism)
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 15, 
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
