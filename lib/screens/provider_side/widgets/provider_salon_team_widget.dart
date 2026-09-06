import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/salon_portal_service.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Salon egasi — taklif kodi va xodim so'rovlari.
class ProviderSalonTeamWidget extends StatefulWidget {
  final Color accent;
  final String? inviteCode;

  const ProviderSalonTeamWidget({
    super.key,
    required this.accent,
    this.inviteCode,
  });

  @override
  State<ProviderSalonTeamWidget> createState() =>
      _ProviderSalonTeamWidgetState();
}

class _ProviderSalonTeamWidgetState extends State<ProviderSalonTeamWidget> {
  final _portal = SalonPortalService();
  List<Map<String, dynamic>> _pending = [];
  String? _inviteCode;
  bool _loading = true;
  int? _actingUserId;

  @override
  void initState() {
    super.initState();
    _inviteCode = widget.inviteCode;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _pending = await _portal.getPendingMembers();
      if (_inviteCode == null) {
        final status = await _portal.getMyStatus();
        _inviteCode = status['invite_code']?.toString();
      }
    } catch (_) {
      _pending = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _copyCode() async {
    final code = _inviteCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Taklif kodi nusxalandi'.tr)));
    }
  }

  Future<void> _regenerate() async {
    try {
      final code = await _portal.regenerateInvite();
      if (mounted) {
        setState(() => _inviteCode = code);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yangi kod yaratildi'.tr)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kod yangilanmadi'.tr)));
      }
    }
  }

  Future<void> _respond(int userId, bool approve) async {
    setState(() => _actingUserId = userId);
    try {
      if (approve) {
        await _portal.approveMember(userId);
      } else {
        await _portal.rejectMember(userId);
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Amal bajarilmadi'.tr)));
      }
    } finally {
      if (mounted) setState(() => _actingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xodimlar va taklif',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_inviteCode != null && _inviteCode!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 1.5),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.link, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Taklif kodi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mutaxassislar ro\'yxatdan o\'tishda shu kodni kiritadi',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _inviteCode!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.copy),
                      onPressed: _copyCode,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw),
                      onPressed: _regenerate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_pending.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Kutilayotgan xodimlar (${_pending.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._pending.map((m) {
            final uid = m['user_id'] as int;
            final acting = _actingUserId == uid;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['name']?.toString() ?? 'Mutaxassis',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (m['phone'] != null)
                    Text(
                      m['phone'].toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: acting ? null : () => _respond(uid, false),
                          child: Text('Rad'.tr),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: acting ? null : () => _respond(uid, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: acting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Qabul qilish'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
