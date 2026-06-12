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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.wallet,
                label: 'Mening moliyam',
                color: Colors.greenAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceManagerScreen())),
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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DailyBtn(
                icon: LucideIcons.layoutGrid,
                label: 'Barcha xizmatlar',
                color: Colors.purpleAccent,
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

  const _DailyBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Color.lerp(const Color(0xFF1E293B), color, 0.15) : Color.lerp(Colors.white, color, 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
          ],
        ),
      ),
    );
  }
}
