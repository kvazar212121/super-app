import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/orders_filter_widget.dart';
import '../widgets/orders_list_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/guest_blocker_widget.dart';
import '../l10n/locale_controller.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final auth = context.watch<AuthProvider>();

    return GlassScaffold(
      embeddedInShell: true,
      title: 'Buyurtmalarim'.tr,
      body: auth.isAuthenticated
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: OrdersFilterWidget(
                    currentFilter: _filter,
                    onFilterChanged: (f) => setState(() => _filter = f),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.fetchOrders(),
                    color: const Color(0xFF6366F1),
                    child: OrdersListWidget(filter: _filter),
                  ),
                ),
              ],
            )
          : GuestBlockerWidget(
              title: 'Buyurtmalarni ko\'rish uchun'.tr,
              subtitle: 'Ro\'yxatdan o\'ting yoki tizimga kiring'.tr,
              icon: Icons.list_alt,
            ),
    );
  }
}
