import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/auth/otp_auth_panel.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/glass/mesh_background.dart';
import '../legal/terms_screen.dart';
import '../../l10n/locale_controller.dart';

/// Buyurtma berishdan oldin ochiladigan kirish / ro'yxatdan o'tish (SMS OTP).
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _showRegister = false;
  bool _registerDetails = false;
  String? _verifiedPhone;
  String? _verificationToken;

  final _name = TextEditingController();
  final _surname = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    super.dispose();
  }

  Future<void> _finishAuth() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<AppProvider>().applyAuthUser(auth.user!);
      await context.read<AppProvider>().fetchInitialData();
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _completeRegister() async {
    if (_name.text.trim().length < 2 || _surname.text.trim().length < 2) {
      _toast('Ism va familiyani kiriting'.tr);
      return;
    }
    if (!_agreedToTerms) {
      _toast('Davom etish uchun foydalanish shartlariga rozilik bering'.tr);
      return;
    }
    if (_verifiedPhone == null || _verificationToken == null) return;

    // Foydalanuvchi ko'rmaydigan avtomatik parol — kirish faqat SMS OTP orqali
    final autoPassword =
        'Hs${DateTime.now().millisecondsSinceEpoch}${_verifiedPhone!.replaceAll(RegExp(r'[^0-9]'), '')}';

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      surname: _surname.text.trim(),
      phone: _verifiedPhone!,
      password: autoPassword,
      verificationToken: _verificationToken!,
    );
    if (!mounted) return;
    if (ok) {
      await _finishAuth();
    } else {
      _toast(auth.error ?? 'Xatolik'.tr);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                LucideIcons.x,
                color: GlassTokens.primaryText(context),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              _registerDetails
                  ? 'Ma\'lumotlaringiz'.tr
                  : (_showRegister ? 'Ro\'yxatdan o\'tish'.tr : 'Kirish'.tr),
              style: TextStyle(
                color: GlassTokens.primaryText(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: GlassSurface(
                padding: const EdgeInsets.all(24),
                borderRadius: GlassTokens.radiusXl,
                opacity: isDark ? 0.22 : 0.78,
                child: _registerDetails
                    ? _buildRegisterDetails(auth)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OtpAuthPanel(
                            title: _showRegister
                                ? 'Telefon raqamni tasdiqlang'.tr
                                : 'Telefon orqali kirish'.tr,
                            subtitle: _showRegister
                                ? 'Ro\'yxatdan o\'tish uchun SMS kod yuboramiz'
                                      .tr
                                : 'Raqamingizga SMS kod yuboramiz — shundoq kirish mumkin emas'
                                      .tr,
                            registerMode: _showRegister,
                            onLoginSuccess: (_) => _finishAuth(),
                            onNeedRegister: (phone, token) {
                              setState(() {
                                _verifiedPhone = phone;
                                _verificationToken = token;
                                _registerDetails = true;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _showRegister = !_showRegister,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: GlassTokens.secondaryText(context),
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _showRegister
                                          ? 'Hisobingiz bormi? '.tr
                                          : 'Hisobingiz yo\'qmi? '.tr,
                                    ),
                                    TextSpan(
                                      text: _showRegister
                                          ? 'Kirish'.tr
                                          : 'Ro\'yxatdan o\'ting'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterDetails(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'Telefon tasdiqlandi'.tr}: $_verifiedPhone',
          style: TextStyle(color: GlassTokens.secondaryText(context)),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Ism'.tr,
            prefixIcon: const Icon(LucideIcons.user, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _surname,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Familiya'.tr,
            prefixIcon: const Icon(LucideIcons.users, size: 20),
          ),
        ),

        const SizedBox(height: 16),
        // Foydalanish shartlariga rozilik (majburiy)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Men '.tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsScreen()),
                    ),
                    child: Text(
                      'foydalanish shartlariga'.tr,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ' roziman'.tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (auth.isLoading || !_agreedToTerms)
                ? null
                : _completeRegister,
            child: auth.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text('Ro\'yxatdan o\'tish'.tr),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _showRegister = false;
              _registerDetails = false;
            }),
            child: Text(
              'Allaqachon hisobingiz bormi? Kirish'.tr,
              style: TextStyle(color: GlassTokens.secondaryText(context)),
            ),
          ),
        ),
      ],
    );
  }
}
