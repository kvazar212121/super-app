import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/demo_auth_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/auth/uz_phone_field.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/glass/mesh_background.dart';
import 'auth_gate_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      phone: UzPhoneField.fullPhone(_phoneController),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (auth.user != null) {
        context.read<AppProvider>().applyAuthUser(auth.user!);
      }
      await context.read<AppProvider>().fetchInitialData();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'Xatolik yuz berdi'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              icon: Icon(LucideIcons.arrowLeft, color: GlassTokens.primaryText(context)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _buildLogo(isDark),
                      const SizedBox(height: 36),
                      GlassSurface(
                        padding: const EdgeInsets.all(28),
                        borderRadius: GlassTokens.radiusXl,
                        opacity: isDark ? 0.22 : 0.72,
                        blur: GlassTokens.blurHeavy,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kirish',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: GlassTokens.primaryText(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hisobingizga kiring',
                                style: TextStyle(color: GlassTokens.secondaryText(context)),
                              ),
                              const SizedBox(height: 28),
                              UzPhoneField(controller: _phoneController),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Parol yoki PIN',
                                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Parol yoki PIN kiriting' : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Demo parol: ${DemoAuthService.demoPassword}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: GlassTokens.secondaryText(context),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: FilledButton(
                                  onPressed: auth.isLoading ? null : _handleLogin,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2.5),
                                        )
                                      : const Text('Kirish'),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (_) => const AuthGateScreen(),
                                    ),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: GlassTokens.secondaryText(context),
                                        fontSize: 14,
                                      ),
                                      children: const [
                                        TextSpan(text: 'Hisobingiz yo\'qmi? '),
                                        TextSpan(
                                          text: 'Ro\'yxatdan o\'ting',
                                          style: TextStyle(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              ),
              child: const Icon(LucideIcons.layers, color: Color(0xFF6366F1), size: 42),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Super App',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: GlassTokens.primaryText(context),
          ),
        ),
        Text(
          'Barcha xizmatlar bir joyda',
          style: TextStyle(color: GlassTokens.secondaryText(context)),
        ),
      ],
    );
  }
}
