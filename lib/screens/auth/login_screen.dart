import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/auth/otp_auth_panel.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/glass/mesh_background.dart';
import '../../widgets/hub_servis_brand.dart';
import 'auth_gate_screen.dart';
import '../../l10n/locale_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _finishLogin(Map<String, dynamic> user) async {
    if (user.isNotEmpty) {
      context.read<AppProvider>().applyAuthUser(user);
    }
    await context.read<AppProvider>().fetchInitialData();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
              icon: Icon(
                LucideIcons.arrowLeft,
                color: GlassTokens.primaryText(context),
              ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OtpAuthPanel(
                              title: 'Telefon orqali kirish'.tr,
                              subtitle:
                                  'SMS kod bilan tasdiqlang — parolsiz kirish mumkin emas'
                                      .tr,
                              onLoginSuccess: _finishLogin,
                              onNeedRegister: (_, _) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => const AuthGateScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
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
                                    children: [
                                      TextSpan(text: 'Hisobingiz yo\'qmi? '.tr),
                                      TextSpan(
                                        text: 'Ro\'yxatdan o\'ting'.tr,
                                        style: const TextStyle(
                                          color: Color(0xFF102A43),
                                          fontWeight: FontWeight.w800,
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
    return const HubServisBrand(logoSize: 88, titleSize: 30, compact: true);
  }
}
