import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass/mesh_background.dart';
import '../../widgets/hub_servis_brand.dart';
import '../main_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_app/l10n/locale_controller.dart';

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
    _checkAuth();
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
    await Future.delayed(const Duration(milliseconds: 2200));

    // Ensure auth check is completed before navigating
    await authFuture;

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;

    return Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: FadeTransition(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HubServisBrand(logoSize: 108, titleSize: 38),
                      const SizedBox(height: 52),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: const Color(0xFF6366F1),
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
}
