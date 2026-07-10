import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../screens/order_detail_screen.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../l10n/locale_controller.dart';

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
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
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
        color: const Color(0xFF6366F1),
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
                        color: isRead ? Colors.white : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead
                              ? Colors.grey[200]!
                              : const Color(0xFFC7D2FE),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconContainer(notif['type']),
                          const SizedBox(width: 16),
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
                                              ? FontWeight.bold
                                              : FontWeight.w900,
                                          fontSize: 15,
                                          color: isRead
                                              ? Colors.black87
                                              : const Color(0xFF312E81),
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6366F1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  timeFormatted,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
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
        title: Text("Hammasini tozalash".tr),
        content: Text(
          "Barcha bildirishnomalar o'chiriladi. Davom etasizmi?".tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Bekor qilish".tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Tozalash".tr,
              style: const TextStyle(color: Color(0xFFEF4444)),
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
    Color iconColor = const Color(0xFF6366F1);
    Color bgColor = const Color(0xFFEEF2FF);

    if (type == 'order_status_changed') {
      iconData = LucideIcons.packageCheck;
      iconColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFECFDF5);
    } else if (type == 'new_order') {
      iconData = LucideIcons.plusCircle;
      iconColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20)],
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Bildirishnomalar yo'q".tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sizda hozircha hech qanday bildirishnomalar mavjud emas. Yangi xabarlar shu yerda paydo bo'ladi."
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
