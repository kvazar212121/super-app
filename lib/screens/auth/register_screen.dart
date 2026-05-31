import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        if (auth.user != null) {
          context.read<AppProvider>().applyAuthUser(auth.user!);
        }
        await context.read<AppProvider>().fetchInitialData();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Xatolik yuz berdi'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        LucideIcons.userPlus,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ro\'yxatdan o\'tish',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form card
                    Container(
                      width: size.width > 500 ? 420 : double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                label: 'Ism',
                                hint: 'Ismingiz',
                                icon: LucideIcons.user,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 2) {
                                  return 'Kamida 2 ta belgi kiriting';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Surname
                            TextFormField(
                              controller: _surnameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                label: 'Familiya',
                                hint: 'Familiyangiz',
                                icon: LucideIcons.users,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 2) {
                                  return 'Kamida 2 ta belgi kiriting';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                label: 'Telefon raqam',
                                hint: '+998901234567',
                                icon: LucideIcons.phone,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 9) {
                                  return 'To\'g\'ri telefon raqam kiriting';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _inputDecoration(
                                label: 'Parol',
                                hint: 'Kamida 6 ta belgi',
                                icon: LucideIcons.lock,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return 'Parol kamida 6 ta belgi bo\'lishi kerak';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              decoration: _inputDecoration(
                                label: 'Parolni tasdiqlang',
                                hint: 'Parolni qayta kiriting',
                                icon: LucideIcons.shieldCheck,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Parollar mos kelmayapti';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Register button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed:
                                    auth.isLoading ? null : _handleRegister,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Ro\'yxatdan o\'tish',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hisobingiz bormi? ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Kirish',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
