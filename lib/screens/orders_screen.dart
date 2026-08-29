import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/orders_filter_widget.dart';
import '../widgets/orders_list_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../providers/auth_provider.dart';
import '../services/feature_service.dart';
import '../widgets/guest_blocker_widget.dart';
import '../l10n/locale_controller.dart';
import 'marketplace/my_listings_screen.dart';
import 'my_jobs_screen.dart';
import '../widgets/gold_tab_bar_widget.dart';

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
    // Savdo bo'limi adminkadan o'chirilsa tab ham ko'rinmaydi:
    // ochiq tab bosilganda bo'sh ekran chiqmasin.
    final savdoOchiq = FeatureService().isEnabled('marketplace');

    return GlassScaffold(
      // Tab ichida — embeddedInShell (fon MainScreen'dan). Alohida route
      // sifatida (Profil banneri) — o'z MeshBackground foni + orqaga tugmasi.
      embeddedInShell: widget.embedded,
      showBackButton: !widget.embedded,
      title: 'Buyurtmalarim'.tr,
      body: auth.isAuthenticated
          // Ikki bo'lim: oddiy buyurtmalar va o'zi bergan ish e'lonlari
          // (e'longa ustalar taklif beradi, mijoz birini tanlaydi).
          // Uch bo'lim: buyurtmalar, ish e'lonlari va SAVDO e'lonlari
          // (buyum sotish). Savdo alohida tab: muddati va uzaytirish
          // qoidalari ish e'lonidan butunlay boshqa.
          ? DefaultTabController(
              length: savdoOchiq ? 3 : 2,
              child: Column(
                children: [
                  GoldTabBar(
                    tabs: [
                      'Buyurtmalar'.tr,
                      'E\'lonlarim'.tr,
                      if (savdoOchiq) 'Savdo'.tr,
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
                                color: const Color(0xFFC9A227),
                                child: OrdersListWidget(filter: _filter),
                              ),
                            ),
                          ],
                        ),
                        const MyJobsScreen(embedded: true),
                        if (savdoOchiq) const MyListingsScreen(embedded: true),
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
