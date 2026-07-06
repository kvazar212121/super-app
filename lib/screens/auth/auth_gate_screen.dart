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
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _obscure = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
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
      _toast('Ism va familiyani kiriting');
      return;
    }
    if (_password.text.length < 4) {
      _toast('Parol kamida 4 belgi');
      return;
    }
    if (_password.text != _passwordConfirm.text) {
      _toast('Parollar mos emas');
      return;
    }
    if (!_agreedToTerms) {
      _toast('Davom etish uchun foydalanish shartlariga rozilik bering');
      return;
    }
    if (_verifiedPhone == null || _verificationToken == null) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      surname: _surname.text.trim(),
      phone: _verifiedPhone!,
      password: _password.text,
      verificationToken: _verificationToken!,
    );
    if (!mounted) return;
    if (ok) {
      await _finishAuth();
    } else {
      _toast(auth.error ?? 'Xatolik');
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
              icon: Icon(LucideIcons.x, color: GlassTokens.primaryText(context)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              _registerDetails
                  ? 'Ma\'lumotlaringiz'
                  : (_showRegister ? 'Ro\'yxatdan o\'tish' : 'Kirish'),
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
                                ? 'Telefon raqamni tasdiqlang'
                                : 'Telefon orqali kirish',
                            subtitle: _showRegister
                                ? 'Ro\'yxatdan o\'tish uchun SMS kod yuboramiz'
                                : 'Raqamingizga SMS kod yuboramiz — shundoq kirish mumkin emas',
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
                              onTap: () => setState(() => _showRegister = !_showRegister),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: GlassTokens.secondaryText(context),
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _showRegister
                                          ? 'Hisobingiz bormi? '
                                          : 'Hisobingiz yo\'qmi? ',
                                    ),
                                    TextSpan(
                                      text: _showRegister ? 'Kirish' : 'Ro\'yxatdan o\'ting',
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
          'Telefon tasdiqlandi: $_verifiedPhone',
          style: TextStyle(color: GlassTokens.secondaryText(context)),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ism',
            prefixIcon: Icon(LucideIcons.user, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _surname,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Familiya',
            prefixIcon: Icon(LucideIcons.users, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Parol',
            prefixIcon: const Icon(LucideIcons.lock, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordConfirm,
          obscureText: _obscure,
          decoration: const InputDecoration(
            labelText: 'Parolni tasdiqlang',
            prefixIcon: Icon(LucideIcons.shieldCheck, size: 20),
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
                  Text('Men ', style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsScreen()),
                    ),
                    child: const Text(
                      'foydalanish shartlariga',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(' roziman', style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 13)),
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
            onPressed: (auth.isLoading || !_agreedToTerms) ? null : _completeRegister,
            child: auth.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Ro\'yxatdan o\'tish'),
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
              'Allaqachon hisobingiz bormi? Kirish',
              style: TextStyle(color: GlassTokens.secondaryText(context)),
            ),
          ),
        ),
      ],
    );
  }
}
