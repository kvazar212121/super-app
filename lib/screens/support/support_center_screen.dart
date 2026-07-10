import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_surface.dart';
import '../chat_screen.dart';

/// Qo'llab-quvvatlash markazi — AI yordamchi yoki real inson (telefon/email/telegram).
class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  bool _loading = true;
  String _phone = '';
  String _email = '';
  String _telegram = '';
  String _telegramBot = '';
  String _workHours = '';
  bool _aiEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService().getSupportConfig();
      _phone = (s['phone'] as String?)?.trim() ?? '';
      _email = (s['email'] as String?)?.trim() ?? '';
      _telegram = (s['telegram'] as String?)?.trim() ?? '';
      _telegramBot = (s['telegram_bot'] as String?)?.trim() ?? '';
      _workHours = (s['work_hours'] as String?)?.trim() ?? '';
      _aiEnabled = s['ai_enabled'] != false;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _launch(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ochib bo\'lmadi'.tr)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ochib bo\'lmadi'.tr)),
        );
      }
    }
  }

  String _telegramUrl(String value) {
    var v = value.trim();
    if (v.startsWith('http')) return v;
    if (v.startsWith('@')) v = v.substring(1);
    return 'https://t.me/$v';
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Yordam markazi'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _headerCard(),
                const SizedBox(height: 24),
                // AI yordamchi — darhol javob
                if (_aiEnabled) ...[
                  _sectionLabel('Tezkor yordam'.tr),
                  _channelCard(
                    icon: Icons.smart_toy_rounded,
                    color: const Color(0xFF06B6D4),
                    title: 'AI yordamchi'.tr,
                    subtitle: 'Savolingizga darhol javob oling'.tr,
                    badge: '24/7',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Real inson bilan bog'lanish
                if (_phone.isNotEmpty || _email.isNotEmpty || _telegram.isNotEmpty ||
                    _telegramBot.isNotEmpty) ...[
                  _sectionLabel('Operator bilan bog\'lanish'.tr),
                  if (_phone.isNotEmpty)
                    _channelCard(
                      icon: Icons.phone_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Telefon'.tr,
                      subtitle: _phone,
                      onTap: () => _launch(Uri.parse('tel:${_phone.replaceAll(' ', '')}')),
                    ),
                  if (_telegram.isNotEmpty)
                    _channelCard(
                      icon: Icons.send_rounded,
                      color: const Color(0xFF0088CC),
                      title: 'Telegram'.tr,
                      subtitle: _telegram,
                      onTap: () => _launch(Uri.parse(_telegramUrl(_telegram))),
                    ),
                  if (_telegramBot.isNotEmpty)
                    _channelCard(
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFF229ED9),
                      title: 'Telegram bot'.tr,
                      subtitle: _telegramBot,
                      onTap: () => _launch(Uri.parse(_telegramUrl(_telegramBot))),
                    ),
                  if (_email.isNotEmpty)
                    _channelCard(
                      icon: Icons.email_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'Email'.tr,
                      subtitle: _email,
                      onTap: () => _launch(Uri.parse('mailto:$_email')),
                    ),
                ],
                if (_workHours.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${'Ish vaqti'.tr}: $_workHours',
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                // Hech qanday operator kanali sozlanmagan bo'lsa
                if (_phone.isEmpty && _email.isEmpty && _telegram.isEmpty &&
                    _telegramBot.isEmpty && !_aiEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Qo\'llab-quvvatlash tez orada ulanadi.'.tr,
                        style: TextStyle(color: GlassTokens.secondaryText(context)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sizga qanday yordam bera olamiz?'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI yordamchi yoki operatorni tanlang'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: GlassTokens.secondaryText(context),
        ),
      ),
    );
  }

  Widget _channelCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        opacity: 0.55,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: GlassTokens.secondaryText(context)),
          ],
        ),
      ),
    );
  }
}
