import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/card_item_widget.dart';
import '../widgets/cashback_card_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/provider_portal_entry.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';
import 'auth/auth_gate_screen.dart';
import '../services/call_history_service.dart';
import '../services/call_service.dart';
import 'calls/call_screen.dart';
import 'calls/call_history_screen.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = provider.user;

    return GlassScaffold(
      embeddedInShell: true,
      title: 'Profil',
      actions: const [],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: [
            if (!auth.isAuthenticated) ...[
              _buildGuestCard(context),
              const SizedBox(height: 20),
            ],
            _buildProfileHeader(context, user, auth.isAuthenticated),
            const SizedBox(height: 20),
            if (auth.isAuthenticated) ...[
              if (user.isProvider) ...[
                CashbackCardWidget(
                  balance: user.balance,
                  cashback: user.cashback,
                  isPremium: user.isPremium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showTopUpSheet(context, provider),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Hisobni to\'ldirish'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _sectionTitle(context, 'Sozlamalar'),
              GlassSurface(
                onTap: () => _showReminderOffsetDialog(context, provider),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                opacity: 0.55,
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: GlassTokens.primaryText(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eslatmalar vaqti',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GlassTokens.primaryText(context),
                            ),
                          ),
                          Text(
                            'Rejadan ${user.reminderOffsetMinutes} daqiqa oldin xabar berish',
                            style: TextStyle(
                              fontSize: 12,
                              color: GlassTokens.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: GlassTokens.secondaryText(context)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Til almashtirgich (UZ / RU)
              GlassSurface(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                opacity: 0.55,
                child: Row(
                  children: [
                    Icon(Icons.language, color: GlassTokens.primaryText(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ilova tili'.tr,
                        style: TextStyle(fontWeight: FontWeight.w600, color: GlassTokens.primaryText(context)),
                      ),
                    ),
                    _langBtn(context, 'uz', "O'zbek"),
                    const SizedBox(width: 8),
                    _langBtn(context, 'ru', 'Русский'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Soha egasi'.tr),
              const ProviderPortalEntry(compact: true),
              const SizedBox(height: 16),
              if (user.isProvider) ...[
                _sectionTitle(context, 'Mening kartalarim'),
                ...provider.cards.map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CardItemWidget(card: card),
                  ),
                ),
                GlassSurface(
                  onTap: () => _showAddCardDialog(context, provider),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  opacity: 0.5,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: GlassTokens.primaryText(context)),
                      const SizedBox(width: 12),
                      Text(
                        'Karta qo\'shish',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GlassSurface(
                onTap: () => _showLogoutDialog(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                opacity: 0.48,
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Text(
                      'Chiqish',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                onTap: () => _showDeleteAccountDialog(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                opacity: 0.48,
                child: Row(
                  children: const [
                    Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Text(
                      'Hisobni o\'chirish',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: GlassTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mehmon rejimi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ilovani ko\'rib chiqing. Buyurtma berish yoki balansdan foydalanish uchun kiring.',
            style: TextStyle(color: GlassTokens.secondaryText(context), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const AuthGateScreen(),
                  ),
                );
                if (ok == true && context.mounted) {
                  final auth = context.read<AuthProvider>();
                  if (auth.user != null) {
                    context.read<AppProvider>().applyAuthUser(auth.user!);
                    await context.read<AppProvider>().fetchInitialData();
                  }
                }
              },
              child: const Text('Kirish / Ro\'yxatdan o\'tish'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile user, bool isLoggedIn) {
    return GlassSurface(
      padding: const EdgeInsets.all(18),
      borderRadius: GlassTokens.radiusLg,
      opacity: 0.55,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: isLoggedIn && user.avatarUrl != null
                ? ClipOval(child: Image.network(AppConfig.formatImageUrl(user.avatarUrl), fit: BoxFit.cover))
                : Center(
                    child: Text(
                      isLoggedIn
                          ? (user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                          : 'M',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? '${user.name} ${user.surname}'.trim() : 'Mehmon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                Text(
                  isLoggedIn ? user.phone : 'Buyurtma uchun kiring',
                  style: TextStyle(color: GlassTokens.secondaryText(context)),
                ),
                if (isLoggedIn && user.telegramUsername != null)
                  Text(
                    user.telegramUsername!,
                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langBtn(BuildContext context, String lang, String label) {
    final active = LocaleController.instance.lang == lang;
    return GestureDetector(
      onTap: () => LocaleController.instance.setLang(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF6366F1) : GlassTokens.secondaryText(context).withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : GlassTokens.primaryText(context),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: GlassTokens.primaryText(context),
          ),
        ),
      ),
    );
  }

  void _showTopUpSheet(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: GlassSurface(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          borderRadius: GlassTokens.radiusXl,
          opacity: 0.88,
          blur: GlassTokens.blurHeavy,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hisobni to\'ldirish',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(ctx),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Summa (so\'m)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    await provider.topUpBalance(amount);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('To\'ldirish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, AppProvider provider) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Karta qo\'shish'),
        content: const Text('Tez orada qo\'shiladi'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Haqiqatan chiqasizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yo\'q')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
            child: const Text('Ha'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hisobni o\'chirish'),
        content: const Text('Haqiqatan ham hisobingizni butunlay o\'chirmoqchimisiz? Bu amalni ortga qaytarib bo\'lmaydi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().deleteAccount();
            },
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  void _showReminderOffsetDialog(BuildContext context, AppProvider provider) {
    final currentOffset = provider.user.reminderOffsetMinutes;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          side: BorderSide(color: Colors.white),
        ),
        title: const Text(
          'Eslatma vaqtini tanlang',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30, 60].map((mins) {
            final isSelected = mins == currentOffset;
            return ListTile(
              title: Text('$mins daqiqa oldin', style: const TextStyle(color: Colors.white)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF6366F1)) : null,
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await provider.updateReminderOffset(mins);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eslatma vaqti $mins daqiqaga o\'zgartirildi')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sozlamani saqlab bo\'lmadi')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

