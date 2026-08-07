import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/pin_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/mesh_background.dart';
import '../../l10n/locale_controller.dart';

/// Ilova background'dan qaytganda — PIN yoqilgan bo'lsa — bu ekran chiqadi.
/// Orqaga ketib bo'lmaydi (PopScope canPop: false).
/// To'g'ri PIN kiritilganda `Navigator.pop()` orqali yopiladi.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  int _attempts = 0;
  static const _maxAttempts = 5;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4 || _attempts >= _maxAttempts) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _verify);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    final ok = await PinService().verifyPin(_pin);
    if (ok) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _attempts++;
    _shakeCtrl.forward(from: 0);
    setState(() {
      _pin = '';
      if (_attempts >= _maxAttempts) {
        _error = 'Juda ko\'p urinish. Ilovani qayta ishga tushiring.'.tr;
      } else {
        _error = 'Noto\'g\'ri PIN ($_attempts/$_maxAttempts urinish)'.tr;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocked = _attempts >= _maxAttempts;

    return PopScope(
      canPop: false, // orqaga tugmasidan yopilmaydi
      child: Stack(
        fit: StackFit.expand,
        children: [
          MeshBackground(isDark: isDark),
          Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.25),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  // Shield icon
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.55),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'HubServis',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: GlassTokens.primaryText(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blocked
                        ? 'Ilovani qayta ishga tushiring'.tr
                        : 'PIN kodingizni kiriting'.tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // PIN nuqtalar — shake animatsiya bilan
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i < _pin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 13),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            border: Border.all(
                              color: filled
                                  ? const Color(0xFF6366F1)
                                  : Colors.white.withValues(alpha: 0.45),
                              width: 2.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!blocked)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                      child: _buildNumpad(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3'], context),
        const SizedBox(height: 14),
        _row(['4', '5', '6'], context),
        const SizedBox(height: 14),
        _row(['7', '8', '9'], context),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 96),
            _digitBtn('0', context),
            const SizedBox(width: 14),
            _deleteBtn(context),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits, BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: digits
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _digitBtn(d, context),
                ))
            .toList(),
      );

  Widget _digitBtn(String digit, BuildContext context) {
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: GlassTokens.primaryText(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBtn(BuildContext context) {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: GlassTokens.primaryText(context),
            size: 26,
          ),
        ),
      ),
    );
  }
}
