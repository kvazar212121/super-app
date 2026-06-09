import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/services_grid_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/daily_utilities_widget.dart';
import '../screens/todo_screen.dart';
import '../screens/shopping_list_screen.dart';

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
            const SearchBarWidget(),
            const SizedBox(height: 22),
            const DailyUtilitiesWidget(),
            const SizedBox(height: 22),
            _buildDailiesRow(context),
            const SizedBox(height: 22),
            const ActiveOrderBanner(),
            const ServicesGridWidget(),
            const SizedBox(height: 4),
            const ProviderPortalEntry(),
            const SizedBox(height: 28),
            const HomePromoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailiesRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DailyBtn(
            icon: LucideIcons.checkSquare,
            label: 'Rejalar',
            color: Colors.blueAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DailyBtn(
            icon: LucideIcons.shoppingBag,
            label: 'Savdo',
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
          ),
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
    // Import needed for GlassTokens
    // It's already imported via daily_utilities_widget or we can just use Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }
}
