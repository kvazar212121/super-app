import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/demo_auth_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/auth/uz_phone_field.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/glass/mesh_background.dart';

/// Buyurtma berishdan oldin ochiladigan kirish / ro'yxatdan o'tish oynasi.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _showRegister = false;

  Future<void> _finishAuth() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<AppProvider>().applyAuthUser(auth.user!);
      await context.read<AppProvider>().fetchInitialData();
    }
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
              icon: Icon(LucideIcons.x, color: GlassTokens.primaryText(context)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              _showRegister ? 'Ro\'yxatdan o\'tish' : 'Kirish',
              style: TextStyle(
                color: GlassTokens.primaryText(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _showRegister
                  ? _RegisterFlow(onDone: _finishAuth, onLoginTap: () => setState(() => _showRegister = false))
                  : _LoginPanel(onDone: _finishAuth, onRegisterTap: () => setState(() => _showRegister = true)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onRegisterTap;

  const _LoginPanel({required this.onDone, required this.onRegisterTap});

  @override
  State<_LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<_LoginPanel> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _secret = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      phone: UzPhoneField.fullPhone(_phone),
      password: _secret.text,
    );
    if (!mounted) return;
    if (ok) {
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Xatolik')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassSurface(
      padding: const EdgeInsets.all(24),
      borderRadius: GlassTokens.radiusXl,
      opacity: isDark ? 0.22 : 0.78,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buyurtma berish uchun kiring',
              style: TextStyle(
                fontSize: 15,
                color: GlassTokens.secondaryText(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            UzPhoneField(controller: _phone),
            const SizedBox(height: 16),
            TextFormField(
              controller: _secret,
              obscureText: _obscure,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Parol yoki PIN',
                prefixIcon: const Icon(LucideIcons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Parol yoki PIN kiriting' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Demo: parol ${DemoAuthService.demoPassword}',
              style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: auth.isLoading ? null : _login,
                child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Kirish'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: widget.onRegisterTap,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 14),
                    children: const [
                      TextSpan(text: 'Hisobingiz yo\'qmi? '),
                      TextSpan(
                        text: 'Ro\'yxatdan o\'ting',
                        style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterFlow extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onLoginTap;

  const _RegisterFlow({required this.onDone, required this.onLoginTap});

  @override
  State<_RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<_RegisterFlow> {
  int _step = 0;
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();
  bool _wantsPin = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _otp.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (_name.text.trim().length < 2 || _surname.text.trim().length < 2) {
        _toast('Ism va familiyani to\'liq kiriting');
        return;
      }
      if (UzPhoneField.validateNineDigits(_phone.text) != null) {
        _toast('Telefon raqamni to\'g\'ri kiriting');
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!DemoAuthService.verifyOtp(_otp.text)) {
        _toast('Noto\'g\'ri kod. Demo kod: ${DemoAuthService.demoOtp}');
        return;
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      if (_wantsPin) {
        setState(() => _step = 3);
      } else {
        _completeRegister();
      }
      return;
    }
    if (_step == 3) {
      if (_pin.text.length != 4 || _pin.text != _pinConfirm.text) {
        _toast('PIN 4 raqamli bo\'lishi va mos kelishi kerak');
        return;
      }
      _completeRegister(pin: _pin.text);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _completeRegister({String? pin}) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      surname: _surname.text.trim(),
      phone: UzPhoneField.fullPhone(_phone),
      password: DemoAuthService.demoPassword,
      pin: pin,
    );
    if (!mounted) return;
    if (ok) {
      widget.onDone();
    } else {
      _toast(auth.error ?? 'Xatolik');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneDisplay = UzPhoneField.fullPhone(_phone);

    return GlassSurface(
      padding: const EdgeInsets.all(24),
      borderRadius: GlassTokens.radiusXl,
      opacity: isDark ? 0.22 : 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: _step, total: 4),
          const SizedBox(height: 20),
          if (_step == 0) ...[
            Text('Ma\'lumotlaringiz', style: _titleStyle(context)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ism', prefixIcon: Icon(LucideIcons.user, size: 20)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _surname,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Familiya', prefixIcon: Icon(LucideIcons.users, size: 20)),
            ),
            const SizedBox(height: 14),
            UzPhoneField(controller: _phone),
          ],
          if (_step == 1) ...[
            Text('Telefonni tasdiqlang', style: _titleStyle(context)),
            const SizedBox(height: 8),
            Text(
              '$phoneDisplay raqamiga SMS kod yuborildi',
              style: TextStyle(color: GlassTokens.secondaryText(context), height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo kod: ${DemoAuthService.demoOtp}',
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _otp,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Tasdiqlash kodi',
                hintText: '• • • •',
                prefixIcon: Icon(LucideIcons.messageSquare, size: 20),
              ),
            ),
          ],
          if (_step == 2) ...[
            Text('PIN kod qo\'yasizmi?', style: _titleStyle(context)),
            const SizedBox(height: 12),
            Text(
              'Keyingi safar tezroq kirish uchun 4 raqamli PIN qo\'yishingiz mumkin. Bu ixtiyoriy.',
              style: TextStyle(color: GlassTokens.secondaryText(context), height: 1.45),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _wantsPin = false;
                      _completeRegister();
                    },
                    child: const Text('Keyinroq'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() {
                      _wantsPin = true;
                      _step = 3;
                    }),
                    child: const Text('PIN qo\'yaman'),
                  ),
                ),
              ],
            ),
          ],
          if (_step == 3) ...[
            Text('PIN kod o\'rnating', style: _titleStyle(context)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              decoration: const InputDecoration(labelText: '4 raqamli PIN', prefixIcon: Icon(LucideIcons.keyRound, size: 20)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pinConfirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              decoration: const InputDecoration(labelText: 'PIN ni tasdiqlang', prefixIcon: Icon(LucideIcons.shieldCheck, size: 20)),
            ),
          ],
          if (_step != 2) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: auth.isLoading ? null : _next,
                child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_step == 3 ? 'Tugatish' : 'Davom etish'),
              ),
            ),
          ],
          if (_step > 0 && _step != 2)
            TextButton(
              onPressed: () => setState(() => _step--),
              child: const Text('Orqaga'),
            ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: widget.onLoginTap,
              child: Text(
                'Allaqachon hisobingiz bormi? Kirish',
                style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _titleStyle(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: GlassTokens.primaryText(context),
      );
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF6366F1) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
