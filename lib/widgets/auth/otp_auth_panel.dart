import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../providers/auth_provider.dart';
import '../../theme/glass_tokens.dart';
import 'uz_phone_field.dart';

/// 6 xonali SMS OTP kiritish maydoni.
class OtpCodeField extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;
  final bool enabled;

  const OtpCodeField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.enabled = true,
  });

  @override
  OtpCodeFieldState createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) {
      final node = FocusNode();
      node.onKeyEvent = (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[index].text.isEmpty && index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();
            widget.onChanged?.call(code);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
      return node;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get code => _controllers.map((c) => c.text).join();

  /// SMS'dan avtomatik kelgan kodni joylash (barcha kataklar to'ldiriladi).
  void setCode(String digits) => _pasteCode(digits);

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _onDigit(int index, String value) {
    if (value.length > 1) {
      _pasteCode(value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  void _pasteCode(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    if (digits.length >= widget.length) {
      widget.onCompleted(digits.substring(0, widget.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Row(
      children: List.generate(widget.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: accent,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (v) => _onDigit(i, v),
            ),
          ),
        );
      }),
    );
  }
}

/// OTP yuborish va tasdiqlash oqimi.
class OtpAuthPanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool registerMode;
  final void Function(Map<String, dynamic> user) onLoginSuccess;
  final void Function(String phone, String verificationToken) onNeedRegister;

  const OtpAuthPanel({
    super.key,
    required this.title,
    required this.subtitle,
    this.registerMode = false,
    required this.onLoginSuccess,
    required this.onNeedRegister,
  });

  @override
  State<OtpAuthPanel> createState() => _OtpAuthPanelState();
}

class _OtpAuthPanelState extends State<OtpAuthPanel> {
  int _step = 0;
  final _phoneCtrl = TextEditingController();
  final _otpFieldKey = GlobalKey<OtpCodeFieldState>();
  String? _phone;
  String? _devCodeHint;
  int _resendSeconds = 0;
  bool _loading = false;

  @override
  void dispose() {
    if (!kIsWeb && Platform.isAndroid) {
      SmartAuth.instance.removeUserConsentApiListener();
    }
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// SMS kelishini kutib, koddan avtomatik to'ldirish (Android User Consent API).
  /// Tizim bitta ruxsat so'raydi — foydalanuvchi "Allow" bossa kod o'zi kiritiladi.
  Future<void> _listenForSms() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      // Oldingi kutish bo'lsa bekor qilamiz (qayta yuborishda)
      await SmartAuth.instance.removeUserConsentApiListener();
      final result = await SmartAuth.instance.getSmsWithUserConsentApi();
      if (!mounted || !result.hasData) return;

      final sms = result.requireData;
      final code = sms.code ?? RegExp(r'\b\d{6}\b').firstMatch(sms.sms)?.group(0);
      if (code != null && code.length == 6) {
        _otpFieldKey.currentState?.setCode(code);
      }
    } catch (e) {
      debugPrint('SMS avtoto\'ldirish xatosi: $e');
    }
  }

  Future<void> _sendOtp() async {
    if (UzPhoneField.validateNineDigits(_phoneCtrl.text) != null) {
      _toast('Telefon raqamni to\'g\'ri kiriting');
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.sendOtp(
      phone: UzPhoneField.fullPhone(_phoneCtrl),
      purpose: widget.registerMode ? 'register' : 'login',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == null) {
      _toast(auth.error ?? 'SMS yuborib bo\'lmadi');
      return;
    }
    _phone = result['phone'] as String?;
    _devCodeHint = result['dev_code'] as String?;
    setState(() {
      _step = 1;
      _resendSeconds = 60;
    });
    _startResendTimer();
    _listenForSms();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 60));
      return _resendSeconds > 0;
    });
  }

  Future<void> _verifyOtp(String code) async {
    if (_phone == null) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.verifyOtp(phone: _phone!, code: code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == null) {
      _toast(auth.error ?? 'Kod noto\'g\'ri');
      _otpFieldKey.currentState?.clear();
      return;
    }
    if (result['user_exists'] == true) {
      widget.onLoginSuccess(auth.user!);
    } else {
      widget.onNeedRegister(
        _phone!,
        result['verification_token'] as String,
      );
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: _titleStyle(context)),
          const SizedBox(height: 8),
          Text(widget.subtitle, style: _subStyle(context)),
          const SizedBox(height: 20),
          UzPhoneField(controller: _phoneCtrl),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _sendOtp,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.messageSquare, size: 20),
              label: const Text('SMS kod yuborish'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kodni kiriting', style: _titleStyle(context)),
        const SizedBox(height: 8),
        Text(
          '$_phone raqamiga yuborilgan 6 xonali kodni kiriting',
          style: _subStyle(context),
        ),
        if (_devCodeHint != null) ...[
          const SizedBox(height: 8),
          Text(
            'Dev kod: $_devCodeHint',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 24),
        OtpCodeField(
          key: _otpFieldKey,
          enabled: !_loading,
          onCompleted: _verifyOtp,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: _loading ? null : () => setState(() => _step = 0),
              child: const Text('Raqamni o\'zgartirish'),
            ),
            const Spacer(),
            TextButton(
              onPressed: (_loading || _resendSeconds > 0) ? null : _sendOtp,
              child: Text(
                _resendSeconds > 0 ? 'Qayta ($_resendSeconds)' : 'Qayta yuborish',
              ),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _titleStyle(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: GlassTokens.primaryText(context),
      );

  TextStyle _subStyle(BuildContext context) => TextStyle(
        color: GlassTokens.secondaryText(context),
        height: 1.4,
      );
}
