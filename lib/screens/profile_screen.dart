import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/card_item_widget.dart';
import '../widgets/cashback_card_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../theme/glass_tokens.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;

    return GlassScaffold(
      title: 'Profil',
      actions: [
        IconButton(
          icon: Icon(
            provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: GlassTokens.primaryText(context),
          ),
          onPressed: () => provider.toggleTheme(),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile user) {
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
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.3),
                  const Color(0xFFA855F7).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: user.avatarUrl != null
                ? ClipOval(child: Image.network(user.avatarUrl!, fit: BoxFit.cover))
                : Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                  '${user.name} ${user.surname}'.trim(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                Text(user.phone, style: TextStyle(color: GlassTokens.secondaryText(context))),
                if (user.telegramUsername != null)
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
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ha'),
          ),
        ],
      ),
    );
  }
}
