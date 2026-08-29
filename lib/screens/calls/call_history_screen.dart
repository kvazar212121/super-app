import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/locale_controller.dart';
import '../../services/call_history_service.dart';
import '../../utils/call_helper.dart';
import '../../theme/glass_tokens.dart';
import '../../theme/lux_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/gold_tab_bar_widget.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/guest_blocker_widget.dart';
import '../support/support_chat_screen.dart';
import 'dm_chat_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return GlassScaffold(
      showBackButton: false,
      title: "Aloqa tarixi".tr,
      actions: [
        IconButton(
          tooltip: "Operator bilan chat".tr,
          icon: const Icon(LucideIcons.messageCircle),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupportChatScreen()),
          ),
        ),
      ],
      bottom: GoldTabBar(
        controller: _tab,
        tabs: [
          "Qo'ng'iroqlar".tr,
          "Habarlar".tr,
          "Bloklangan".tr,
        ],
      ),
      body: auth.isAuthenticated
          ? TabBarView(
              controller: _tab,
              children: [
                _CallsTab(),
                _MessagesTab(),
                _BlockedTab(),
              ],
            )
          : GuestBlockerWidget(
              title: 'Aloqa tarixini ko\'rish uchun'.tr,
              subtitle: 'Ro\'yxatdan o\'ting yoki tizimga kiring'.tr,
              icon: Icons.history,
            ),
    );
  }
}

/// Qo'ng'iroqlar ro'yxati (amallar bilan).
class _CallsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CallHistoryService(),
      builder: (context, _) {
        final svc = CallHistoryService();
        final logs = svc.history;
        if (logs.isEmpty) {
          return _empty(context, 'Qo\'ng\'iroqlar tarixi bo\'sh'.tr);
        }
        return Column(
          children: [
            // 1 oylik eslatma + tozalash
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 14, color: GlassTokens.secondaryText(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Faqat oxirgi 1 oy saqlanadi'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, svc),
                    icon: const Icon(LucideIcons.trash2, size: 15, color: Color(0xFFEF4444)),
                    label: Text(
                      'Tozalash'.tr,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final log = logs[idx];
                  final blocked = svc.isUserBlocked(log.userId);
                  final timeStr = DateFormat('dd.MM.yyyy HH:mm').format(log.timestamp);
                  final connected = log.status == 'connected';
                  final iconData = connected
                      ? (log.isIncoming ? Icons.call_received : Icons.call_made)
                      : (log.isIncoming
                          ? Icons.call_received_outlined
                          : Icons.call_made_outlined);
                  final iconColor = connected ? Colors.green : Colors.red;

                  return GlassSurface(
                    padding: const EdgeInsets.all(8),
                    opacity: 0.55,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(iconData, color: iconColor),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              log.userName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: GlassTokens.primaryText(context),
                              ),
                            ),
                          ),
                          if (blocked)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(LucideIcons.ban,
                                  size: 14, color: Colors.red.shade400),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${log.isIncoming ? "Kiruvchi".tr : "Chiquvchi".tr} • $timeStr'
                        '\n${'Davomiyligi'.tr}: ${log.duration}',
                        style: TextStyle(color: GlassTokens.secondaryText(context)),
                      ),
                      trailing: _menu(context, svc, log, blocked),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _menu(BuildContext context, CallHistoryService svc, CallLog log, bool blocked) {
    return PopupMenuButton<String>(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      icon: Icon(LucideIcons.ellipsisVertical, color: GlassTokens.secondaryText(context)),
      onSelected: (v) async {
        switch (v) {
          case 'call':
            CallHelper.makeDirectCall(context, log.userId, log.userName);
            break;
          case 'message':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DmChatScreen(
                  peerId: log.userId,
                  peerName: log.userName,
                ),
              ),
            );
            break;
          case 'block':
            await svc.blockUser(log.userId, log.userName);
            if (!context.mounted) return;
            _toast(context, '${log.userName} ${'bloklandi'.tr}');
            break;
          case 'unblock':
            await svc.unblockUser(log.userId);
            if (!context.mounted) return;
            _toast(context, '${log.userName} ${'blokdan chiqarildi'.tr}');
            break;
          case 'delete':
            await svc.deleteCallLog(log.id);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'call',
          child: Row(children: [
            const Icon(Icons.phone, color: Colors.green, size: 18),
            const SizedBox(width: 10),
            Text('Qo\'ng\'iroq qilish'.tr, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ]),
        ),
        PopupMenuItem(
          value: 'message',
          child: Row(children: [
            const Icon(LucideIcons.messageSquare, color: Color(0xFFC9A227), size: 18),
            const SizedBox(width: 10),
            Text('Xabar yozish'.tr, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ]),
        ),
        PopupMenuItem(
          value: blocked ? 'unblock' : 'block',
          child: Row(children: [
            Icon(blocked ? LucideIcons.circleCheck : LucideIcons.ban,
                color: blocked ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 10),
            Text(blocked ? 'Blokdan chiqarish'.tr : 'Bloklash'.tr, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Text('O\'chirish'.tr, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, CallHistoryService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tozalash'.tr),
        content: Text('Barcha qo\'ng\'iroqlar tarixi o\'chiriladi. Davom etasizmi?'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Bekor qilish'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Tozalash'.tr, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok == true) await svc.clearHistory();
  }

  void _toast(BuildContext context, String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 2)),
    );
  }

  Widget _empty(BuildContext context, String text, [String? subtitle, IconData? icon]) {
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
                child: Icon(
                  icon ?? LucideIcons.phoneOff,
                  size: 40,
                  color: const Color(0xFF140D02),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF140D02),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF332205),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yozishmalar (SMS-uslub) ro'yxati.
class _MessagesTab extends StatefulWidget {
  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  final ApiService _api = ApiService();
  List<dynamic> _convos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.getDmConversations();
      if (mounted) {
        setState(() {
        _convos = list;
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_convos.isEmpty) {
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
                    LucideIcons.messageSquare,
                    size: 40,
                    color: Color(0xFF140D02),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hali yozishma yo\'q'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF140D02),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Qo\'ng\'iroqlar ro\'yxatidan abonentga xabar yozing'.tr,
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _convos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, idx) {
          final c = Map<String, dynamic>.from(_convos[idx] as Map);
          final unread = (c['unread'] as num?)?.toInt() ?? 0;
          final peerId = (c['peer_id'] as num).toInt();
          final peerName = c['peer_name'] as String? ?? '';
          String time = '';
          try {
            time = DateFormat('dd.MM HH:mm').format(DateTime.parse(c['last_at']).toLocal());
          } catch (_) {}
          return GlassSurface(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DmChatScreen(
                    peerId: peerId,
                    peerName: peerName,
                  ),
                ),
              );
              _load();
            },
            padding: const EdgeInsets.all(8),
            opacity: 0.55,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFC9A227).withValues(alpha: 0.15),
                child: const Icon(LucideIcons.user, color: Color(0xFFC9A227)),
              ),
              title: Text(
                c['peer_name'] as String? ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              subtitle: Text(
                c['last_message'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: GlassTokens.secondaryText(context)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(time,
                          style: TextStyle(fontSize: 11, color: GlassTokens.secondaryText(context))),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Text('$unread',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  _msgMenu(context, peerId, peerName),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// SMS suhbat uchun amallar menyusi: qo'ng'iroq, bloklash/blokdan chiqarish,
  /// suhbatни o'chirish.
  Widget _msgMenu(BuildContext context, int peerId, String peerName) {
    final svc = CallHistoryService();
    final blocked = svc.isUserBlocked(peerId);
    return PopupMenuButton<String>(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      icon: Icon(LucideIcons.ellipsisVertical, color: GlassTokens.secondaryText(context)),
      onSelected: (v) async {
        switch (v) {
          case 'call':
            CallHelper.makeDirectCall(context, peerId, peerName);
            break;
          case 'block':
            await svc.blockUser(peerId, peerName);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$peerName ${'bloklandi'.tr}')),
            );
            break;
          case 'unblock':
            await svc.unblockUser(peerId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$peerName ${'blokdan chiqarildi'.tr}')),
            );
            break;
          case 'delete':
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
                  'Suhbatni o\'chirish'.tr,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
                ),
                content: Text(
                  '$peerName ${'bilan yozishma o\'chiriladi. Davom etasizmi?'.tr}',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Bekor qilish'.tr,
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'O\'chirish'.tr,
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
            if (ok == true) {
              try {
                await _api.deleteDmThread(peerId);
              } catch (_) {}
              _load();
            }
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'call',
          child: Row(children: [
            const Icon(Icons.phone, color: Colors.green, size: 18),
            const SizedBox(width: 10),
            Text('Qo\'ng\'iroq qilish'.tr, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ]),
        ),
        PopupMenuItem(
          value: blocked ? 'unblock' : 'block',
          child: Row(children: [
            Icon(blocked ? LucideIcons.circleCheck : LucideIcons.ban,
                color: blocked ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 10),
            Text(blocked ? 'Blokdan chiqarish'.tr : 'Bloklash'.tr, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Text('Suhbatni o\'chirish'.tr, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
    );
  }
}

/// Bloklangan kontaktlar.
class _BlockedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CallHistoryService(),
      builder: (context, _) {
        final svc = CallHistoryService();
        final blocked = svc.blocked;
        if (blocked.isEmpty) {
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
                        LucideIcons.shieldCheck,
                        size: 40,
                        color: Color(0xFF140D02),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bloklangan kontaktlar yo\'q'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF140D02),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: blocked.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final b = blocked[idx];
            return GlassSurface(
              padding: const EdgeInsets.all(8),
              opacity: 0.55,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.12),
                  child: Icon(LucideIcons.ban, color: Colors.red.shade400),
                ),
                title: Text(
                  b.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                subtitle: Text(
                  '${'Bloklangan'.tr}: ${DateFormat('dd.MM.yyyy').format(b.blockedAt)}',
                  style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 12),
                ),
                trailing: OutlinedButton(
                  onPressed: () => svc.unblockUser(b.userId),
                  child: Text('Blokdan chiqarish'.tr),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
