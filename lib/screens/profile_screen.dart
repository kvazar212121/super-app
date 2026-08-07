import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/card_item_widget.dart';
import '../widgets/account_balance_card_widget.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/provider_portal_entry.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';
import 'auth/auth_gate_screen.dart';
import 'auth/pin_setup_screen.dart';
import 'premium/premium_screen.dart';
import 'orders_screen.dart';
import 'support/support_center_screen.dart';
import '../config/app_config.dart';
import '../services/pin_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = provider.user;

    return GlassScaffold(
      // Endi header'dagi (yuqori o'ng) profil tugmasidan alohida route sifatida
      // ochiladi — o'z MeshBackground foni + orqaga tugmasi kerak.
      showBackButton: true,
      title: 'Profil',
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
              _buildOrdersBanner(context),
              const SizedBox(height: 20),
              _buildPremiumBanner(context, user),
              const SizedBox(height: 20),
              if (user.isProvider) ...[
                AccountBalanceCard(
                  balance: user.balance,
                  isPremium: user.isPremium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showTopUpSheet(context, provider),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text('Hisobni to\'ldirish'.tr),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _sectionTitle(context, 'Sozlamalar'),
              GlassSurface(
                onTap: () => _showReminderOffsetDialog(context, provider),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                opacity: 0.55,
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: GlassTokens.primaryText(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eslatmalar vaqti'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GlassTokens.primaryText(context),
                            ),
                          ),
                          Text(
                            '${'Rejadan'.tr} ${user.reminderOffsetMinutes} ${'daqiqa oldin xabar berish'.tr}',
                            style: TextStyle(
                              fontSize: 12,
                              color: GlassTokens.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Til almashtirgich (UZ / RU)
              GlassSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                opacity: 0.55,
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: GlassTokens.primaryText(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ilova tili'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                    ),
                    _langBtn(context, 'uz', "O'zbek"),
                    const SizedBox(width: 8),
                    _langBtn(context, 'ru', 'Русский'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // PIN himoya bo'limi
              const _PinSection(),
              const SizedBox(height: 12),
              // Yordam markazi (AI yordamchi / operator)
              GlassSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportCenterScreen()),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                opacity: 0.55,
                child: Row(
                  children: [
                    Icon(
                      Icons.headset_mic_outlined,
                      color: GlassTokens.primaryText(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yordam markazi'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GlassTokens.primaryText(context),
                            ),
                          ),
                          Text(
                            'AI yordamchi yoki operator'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: GlassTokens.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  opacity: 0.5,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: GlassTokens.primaryText(context),
                      ),
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
              Row(
                children: [
                  Expanded(
                    child: GlassSurface(
                      onTap: () => _showLogoutDialog(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      opacity: 0.48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Chiqish'.tr,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassSurface(
                      onTap: () => _showDeleteAccountDialog(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      opacity: 0.48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_forever_rounded,
                              color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Hisobni o\'chirish'.tr,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Buyurtmalar paneli — Premium banner o'lchamida, undan yuqorida turadi.
  /// Bosilganda buyurtmalar ro'yxati (OrdersScreen) ochiladi.
  Widget _buildOrdersBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyurtmalarim'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Faol va o\'tgan buyurtmalar'.tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  /// Premium banner — obuna faol bo'lsa "faol" holatini, aks holda sotib olishga
  /// undovchi karta ko'rsatadi. Bosilganда PremiumScreen ochiladi.
  Widget _buildPremiumBanner(BuildContext context, UserProfile user) {
    final isPremium = user.isPremium;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPremium
                ? const [Color(0xFF059669), Color(0xFF10B981)]
                : const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                  .withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium faol'.tr : 'HubServis Premium'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium
                        ? 'Barcha imkoniyatlar ochiq ✅'.tr
                        : 'Barcha imkoniyatlarni oching'.tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sotib olish'.tr,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.white),
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
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              height: 1.4,
            ),
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
              child: Text('Kirish / Ro\'yxatdan o\'tish'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    UserProfile user,
    bool isLoggedIn,
  ) {
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
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: isLoggedIn && user.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      AppConfig.formatImageUrl(user.avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      isLoggedIn
                          ? (user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?')
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
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchLang(BuildContext context, String lang) async {
    if (LocaleController.instance.lang == lang) return;
    // Loading overlay — til o'zgarib, butun ilova qayta chizilguncha
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    );
    await LocaleController.instance.setLang(lang);
    // Qayta chizishga ulgurishi uchun qisqa pauza
    await Future.delayed(const Duration(milliseconds: 450));
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Widget _langBtn(BuildContext context, String lang, String label) {
    final active = LocaleController.instance.lang == lang;
    return GestureDetector(
      onTap: () => _switchLang(context, lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF3B82F6)
                : GlassTokens.secondaryText(context).withValues(alpha: 0.4),
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
                decoration: InputDecoration(hintText: 'Summa (so\'m)'),
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
                child: Text('To\'ldirish'.tr),
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
        title: Text('Karta qo\'shish'.tr),
        content: Text('Tez orada qo\'shiladi'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'.tr),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chiqish'.tr),
        content: Text('Haqiqatan chiqasizmi?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Yo\'q'.tr),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
            child: Text('Ha'.tr),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hisobni o\'chirish'.tr),
        content: const Text(
          'Haqiqatan ham hisobingizni butunlay o\'chirmoqchimisiz? Bu amalni ortga qaytarib bo\'lmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().deleteAccount();
            },
            child: Text('O\'chirish'.tr),
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
        title: Text(
          'Eslatma vaqtini tanlang'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30, 60].map((mins) {
            final isSelected = mins == currentOffset;
            return ListTile(
              title: Text(
                '$mins ${'daqiqa oldin'.tr}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6))
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await provider.updateReminderOffset(mins);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${'Eslatma vaqti'.tr} $mins ${'daqiqaga o\'zgartirildi'.tr}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sozlamani saqlab bo\'lmadi'.tr),
                      ),
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
            child: Text(
              'Bekor qilish'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PIN himoya bo'limi — alohida StatefulWidget (o'z holati bor)
// ─────────────────────────────────────────────────────────────

class _PinSection extends StatefulWidget {
  const _PinSection();
  @override
  State<_PinSection> createState() => _PinSectionState();
}

class _PinSectionState extends State<_PinSection> {
  bool _pinEnabled = false;
  bool _hasPin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PinService().isEnabled;
    final hasPin = await PinService().hasPin;
    if (mounted) {
      setState(() {
        _pinEnabled = enabled;
        _hasPin = hasPin;
        _loading = false;
      });
    }
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      if (!_hasPin) {
        // PIN o'rnatish ekranini ochish
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        );
        if (ok != true) return; // Bekor qilindi
        if (mounted) {
          setState(() {
            _pinEnabled = true;
            _hasPin = true;
          });
        }
      } else {
        await PinService().setEnabled(true);
        if (mounted) setState(() => _pinEnabled = true);
      }
    } else {
      await PinService().setEnabled(false);
      if (mounted) setState(() => _pinEnabled = false);
    }
  }

  Future<void> _changePin() async {
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen(isChange: true)),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN muvaffaqiyatli o\'zgartirildi'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Column(
      children: [
        // Asosiy toggle qator
        GlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          opacity: 0.55,
          child: Row(
            children: [
              Icon(Icons.lock_outlined, color: GlassTokens.primaryText(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN himoya'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    Text(
                      _pinEnabled
                          ? 'Ilova ochilganda PIN so\'raladi'.tr
                          : 'Background\'dan qaytganda PIN so\'raladi'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _pinEnabled,
                onChanged: _onToggle,
                activeThumbColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ),
        // "PIN o'zgartirish" tugmasi — faqat PIN o'rnatilgan bo'lsa
        if (_hasPin) ...[          
          const SizedBox(height: 8),
          GlassSurface(
            onTap: _changePin,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            opacity: 0.45,
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: GlassTokens.secondaryText(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PIN o\'zgartirish'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: GlassTokens.secondaryText(context),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
