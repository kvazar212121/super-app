import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/orders_filter_widget.dart';
import '../widgets/orders_list_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/guest_blocker_widget.dart';
import '../l10n/locale_controller.dart';
import 'my_jobs_screen.dart';

class OrdersScreen extends StatefulWidget {
  /// [embedded] — MainScreen pastki menyu tabi ichida (o'z foni MainScreen'dan,
  /// orqaga tugma yo'q). false bo'lsa — alohida route (Profil bannneridan),
  /// o'z MeshBackground foni + orqaga tugmasi bilan.
  final bool embedded;

  const OrdersScreen({super.key, this.embedded = false});

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
      // Tab ichida — embeddedInShell (fon MainScreen'dan). Alohida route
      // sifatida (Profil banneri) — o'z MeshBackground foni + orqaga tugmasi.
      embeddedInShell: widget.embedded,
      showBackButton: !widget.embedded,
      title: 'Buyurtmalarim'.tr,
      body: auth.isAuthenticated
          // Ikki bo'lim: oddiy buyurtmalar va o'zi bergan ish e'lonlari
          // (e'longa ustalar taklif beradi, mijoz birini tanlaydi).
          ? DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: const Color(0xFF6366F1),
                    indicatorColor: const Color(0xFF6366F1),
                    tabs: [
                      Tab(text: 'Buyurtmalar'.tr),
                      Tab(text: 'E\'lonlarim'.tr),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: OrdersFilterWidget(
                                currentFilter: _filter,
                                onFilterChanged: (f) =>
                                    setState(() => _filter = f),
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
                        ),
                        const MyJobsScreen(embedded: true),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : GuestBlockerWidget(
              title: 'Buyurtmalarni ko\'rish uchun'.tr,
              subtitle: 'Ro\'yxatdan o\'ting yoki tizimga kiring'.tr,
              icon: Icons.list_alt,
            ),
    );
  }
}
