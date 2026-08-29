import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/pin_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/mesh_background.dart';
import '../../l10n/locale_controller.dart';

/// 4 raqamli PIN o'rnatish ekrani (2 bosqichli: kiritish + tasdiqlash).
/// [isChange] = true bo'lsa sarlavha "O'zgartirish" bo'ladi.
/// Muvaffaqiyatli bo'lsa `Navigator.pop(true)` qaytaradi.
class PinSetupScreen extends StatefulWidget {
  final bool isChange;
  const PinSetupScreen({super.key, this.isChange = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  // Bosqich: 0 = yangi PIN kiritish, 1 = PIN tasdiqlash
  int _step = 0;
  String _firstPin = '';
  String _pin = '';
  String? _error;

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
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onFull);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _onFull() async {
    if (_step == 0) {
      // Birinchi PIN kiritildi — tasdiqlashga o't
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _step = 1;
      });
    } else {
      // Tasdiqlash
      if (_pin == _firstPin) {
        await PinService().setPin(_pin);
        await PinService().setEnabled(true);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        _shakeCtrl.forward(from: 0);
        setState(() {
          _error = 'PIN mos kelmadi — qaytadan urinib ko\'ring';
          _pin = '';
          _firstPin = '';
          _step = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConfirmStep = _step == 1;

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
              widget.isChange ? 'PIN o\'zgartirish'.tr : 'PIN o\'rnatish'.tr,
              style: TextStyle(
                color: GlassTokens.primaryText(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 44),
                // Yuqori icon
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC9A227), Color(0xFFE3C766)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC9A227).withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.lock,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  isConfirmStep
                      ? 'PIN ni tasdiqlang'.tr
                      : 'Yangi PIN kiriting'.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isConfirmStep
                      ? 'Yana bir marta kiriting'.tr
                      : '4 raqamli PIN kodni o\'rnating'.tr,
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                // PIN nuqtalar
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
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? const Color(0xFFC9A227)
                              : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? const Color(0xFFC9A227)
                                : GlassTokens.secondaryText(context)
                                    .withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                // Numpad
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: _buildNumpad(context),
                ),
              ],
            ),
          ),
        ),
      ],
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
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
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
          color: Colors.white.withValues(alpha: 0.06),
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
