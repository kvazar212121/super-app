import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../screens/order_detail_screen.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';
import '../theme/lux_tokens.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final notifications = provider.notifications;

    return GlassScaffold(
      showBackButton: true,
      title: "Bildirishnomalar".tr,
      actions: [
        if (provider.unreadCount > 0)
          TextButton(
            onPressed: () => provider.markAllNotificationsRead(),
            child: Text(
              "Hammasini o'qish".tr,
              style: const TextStyle(
                color: Color(0xFF8A5D0B),
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
          ),
        if (notifications.isNotEmpty)
          IconButton(
            tooltip: "Hammasini tozalash".tr,
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
            onPressed: () => _confirmClearAll(context, provider),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () => provider.fetchNotifications(),
        color: LuxTokens.gold,
        child: notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isRead = notif['is_read'] ?? false;
                  final createdAtStr = notif['created_at'] ?? '';
                  String timeFormatted = '';
                  try {
                    final date = DateTime.parse(createdAtStr).toLocal();
                    timeFormatted = DateFormat('dd.MM.yyyy HH:mm').format(date);
                  } catch (_) {}

                  return Dismissible(
                    key: ValueKey(notif['id']),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        provider.deleteNotification(notif['id'].toString()),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!isRead) {
                          provider.markNotificationRead(notif['id']);
                        }
                        _openNotification(context, notif);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? const Color(0xFFE2E8F0)
                                : LuxTokens.gold,
                            width: isRead ? 1.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isRead
                                  ? Colors.black.withValues(alpha: 0.02)
                                  : LuxTokens.gold.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIconContainer(notif['type']),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['title'] ?? 'Xabar'.tr,
                                          style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.w700
                                                : FontWeight.w900,
                                            fontSize: 15,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: LuxTokens.gold,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif['message'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF475569),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    timeFormatted,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, AppProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: LuxTokens.gold.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        title: Text(
          "Hammasini tozalash".tr,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Barcha bildirishnomalar o'chiriladi. Davom etasizmi?".tr,
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Bekor qilish".tr,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Tozalash".tr,
              style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.clearAllNotifications();
    }
  }

  void _openNotification(BuildContext context, Map<dynamic, dynamic> notif) {
    if (notif['type'] != 'order_status_changed') return;
    final message = notif['message']?.toString() ?? '';
    final match = RegExp(r'#(\d+)').firstMatch(message);
    if (match == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: match.group(1)!),
      ),
    );
  }

  Widget _buildIconContainer(String? type) {
    IconData iconData = LucideIcons.bell;
    if (type == 'order_status_changed') {
      iconData = LucideIcons.packageCheck;
    } else if (type == 'new_order') {
      iconData = LucideIcons.plusCircle;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: LuxTokens.goldBoxDecoration(isCircle: true),
      child: Icon(iconData, color: const Color(0xFF140D02), size: 20),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: GlassSurface(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          borderRadius: GlassTokens.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuxTokens.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bellOff,
                  size: 40,
                  color: Color(0xFF140D02),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Bildirishnomalar yo'q".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF140D02),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sizda hozircha hech qanday bildirishnomalar mavjud emas. Yangi xabarlar shu yerda paydo bo'ladi."
                    .tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF332205),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
