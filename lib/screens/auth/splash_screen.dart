import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/locale_controller.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/lux_tokens.dart';
import '../../widgets/glass/mesh_background.dart';
import '../../widgets/hub_servis_brand.dart';
import '../root_shell.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

  Timer? _tipTimer;
  int _currentTipIndex = 0;

  final List<Map<String, dynamic>> _tips = [
    {
      'icon': LucideIcons.wrench,
      'category': 'Maishiy xizmatlar',
      'text': 'Usta, santexnik va elektrik xizmatlarini bir zumda chaqiring',
    },
    {
      'icon': LucideIcons.car,
      'category': 'Avto xizmatlar',
      'text': 'Avto-ustaxona, yuvish va evakuator xizmatlari doim qo\'l ostingizda',
    },
    {
      'icon': LucideIcons.sparkles,
      'category': 'AiHub Intellekti',
      'text': 'Sun\'iy intellekt yordamchisidan har qanday savolingizga javob oling',
    },
    {
      'icon': LucideIcons.home,
      'category': 'Uy va Oila',
      'text': 'Uy tozalash, enaga va tibbiy hamshira xizmatlarini qulay buyurtma qiling',
    },
    {
      'icon': LucideIcons.briefcase,
      'category': 'Ish va Bandlik',
      'text': 'Xizmat ko\'rsatish bo\'yicha bo\'sh ish o\'rinlari va e\'lonlar',
    },
    {
      'icon': LucideIcons.shoppingBag,
      'category': 'Smart Bozor',
      'text': 'Moliyaviy kalkulyatorlar va ehtiyojlar uchun foydali vositalar',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    _startTipCarousel();
    _checkAuth();
  }

  void _startTipCarousel() {
    _tipTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
        });
      }
    });
  }

  Future<void> _checkAuth() async {
    // Ilova ishga tushishi bilan Joylashuv ruxsatini so'rash
    try {
      await Permission.locationWhenInUse.request();
    } catch (e) {
      debugPrint('Location permission request error: $e');
    }

    // Start auth check and data fetching in parallel immediately
    final authFuture = () async {
      try {
        final auth = context.read<AuthProvider>();
        final loggedIn = await auth.tryAutoLogin();
        if (!mounted) return;

        if (loggedIn && auth.user != null) {
          context.read<AppProvider>().applyAuthUser(auth.user!);
        }
        await context.read<AppProvider>().fetchInitialData();
      } catch (e) {
        debugPrint('Splash checkAuth error: $e');
      }
    }();

    // Wait for the splash screen presentation delay
    await Future.delayed(const Duration(milliseconds: 2800));

    // Ensure auth check is completed before navigating
    await authFuture;

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const RootShell()));
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tip = _tips[_currentTipIndex];

    return Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // 1) Logo + HubServis Title + Tagline (High Contrast & Clear Typography)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _scaleAnim,
                        _slideAnim,
                        _pulseAnim,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: Transform.scale(
                            scale: _scaleAnim.value * _pulseAnim.value,
                            child: child,
                          ),
                        );
                      },
                      child: const HubServisBrand(logoSize: 112, titleSize: 42),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // 2) Dynamic App Features & Tips Carousel Card
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: LuxTokens.gold.withValues(alpha: 0.5),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: LuxTokens.gold.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentTipIndex),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LuxTokens.goldGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: LuxTokens.gold.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  tip['icon'] as IconData,
                                  size: 20,
                                  color: const Color(0xFF140D02),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (tip['category'] as String).tr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8A5D0B),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      (tip['text'] as String).tr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                        height: 1.3,
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

                  const SizedBox(height: 24),

                  // 3) High Quality Animated Loading Spinner with Status Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: const Color(0xFFC9A227),
                          backgroundColor: LuxTokens.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Xizmatlar yuklanmoqda...'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
