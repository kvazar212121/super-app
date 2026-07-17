import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import '../../l10n/locale_controller.dart';
import '../../services/call_service.dart';
import '../../services/ringtone_service.dart';
import '../../app_navigator.dart';
import 'post_call_dialogs.dart';

/// WhatsApp uslubidagi ovozli qo'ng'iroq ekrani.
/// Jiringlash animatsiyasi, vaqt ko'rsatkichi va boshqaruv tugmalari bilan.
class CallScreen extends StatefulWidget {
  final bool isIncoming;
  final Map<String, dynamic>? incomingData;
  final bool isBookingCall;

  const CallScreen({
    super.key,
    this.isIncoming = false,
    this.incomingData,
    this.isBookingCall = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late CallService _callService;
  bool _isAccepted = false;
  Timer? _vibrationTimer;

  // Jiringlash animatsiyasi
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  void _startRingingEffects() {
    if (widget.isIncoming && !_isAccepted) {
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (
        timer,
      ) {
        HapticFeedback.vibrate();
      });
      HapticFeedback.vibrate();
    }
  }

  void _stopRingingEffects() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _callService = CallService();
    _isAccepted = !widget.isIncoming || _callService.inCall;

    // Pulse animatsiya (avatar atrofida to'lqin)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Ring animatsiya (telefon ikonka tebranishi)
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ringAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.elasticIn),
    );

    if (!_isAccepted) {
      // Kiruvchi qo'ng'iroqda animatsiyalarni boshlash
      _pulseController.repeat();
      _ringController.repeat(reverse: true);
      _startRingingEffects();
    } else if (!widget.isIncoming) {
      // Chiquvchi qo'ng'iroqda pulse animatsiyasini boshlash
      _pulseController.repeat();
    }

    _callService.onCallEnded = () {
      _stopRingingEffects();
      final cs = _callService;

      // Qo'ng'iroq ekranini yopamiz. Global navigatorKey ishlatamiz — chunki
      // keyingi kelishuv dialoglari ASINXRON (ekran yopilgandan keyin ham)
      // davom etadi va barqaror root kontekst kerak.
      final navCtx = navigatorKey.currentContext;
      if (navCtx != null && Navigator.of(navCtx).canPop()) {
        Navigator.of(navCtx).pop();
      }

      // Kelishuv faqat ZAKAZ qo'ng'irog'i + haqiqiy suhbat bo'lganda so'raladi
      // (missed/rad etilgan yoki shaxsiy qo'ng'iroqda so'ralmaydi).
      final isDeal = cs.lastCallWasOrder &&
          cs.lastCallConnected &&
          cs.lastCallId != null &&
          (cs.lastCallRemoteUserId ?? 0) != 0;
      if (isDeal && navCtx != null) {
        PostCallDialogs.showDealFlow(
          navCtx,
          callId: cs.lastCallId!,
          otherUserId: cs.lastCallRemoteUserId!,
          otherName: cs.lastCallRemoteUserName ?? 'Mijoz',
          categoryKey: cs.lastCallCategoryKey,
          iAmProvider: cs.lastCallIAmProvider,
        );
      }
    };

    _callService.onCallAnswered = () {
      _stopRingingEffects();
      if (mounted) {
        setState(() => _isAccepted = true);
        _pulseController.stop();
        _ringController.stop();
      }
    };

    _callService.onError = (msg) {
      _stopRingingEffects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _stopRingingEffects();
    super.dispose();
  }

  void _acceptCall() async {
    setState(() => _isAccepted = true);
    _pulseController.stop();
    _ringController.stop();
    _stopRingingEffects();
    RingtoneService().stop();

    final senderId = widget.incomingData?['sender_id'] as int? ?? 0;
    final senderName =
        widget.incomingData?['sender_name'] as String? ?? 'Noma\'lum';

    await _callService.answerCall(senderId, senderName);
  }

  void _declineCall() {
    _stopRingingEffects();
    RingtoneService().stop();
    _callService.rejectCall();
    Navigator.of(context).pop();
  }

  void _endCall() {
    _stopRingingEffects();
    RingtoneService().stop();
    _callService.endCall();
    // Navigator.pop is handled by onCallEnded / PostCallDialogs.show
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _callService,
      builder: (context, _) {
        final bool showConnecting = _callService.isConnecting && _isAccepted;
        final bool showRinging =
            !_isAccepted &&
            widget.isIncoming; // Kiruvchi, hali qabul qilinmagan
        final bool showCalling =
            !_isAccepted && !widget.isIncoming; // Chiquvchi, kutilmoqda
        final bool showInCall =
            _isAccepted && !_callService.isConnecting; // Gaplashuvda

        String statusText;
        if (showRinging) {
          statusText = 'Kiruvchi qo\'ng\'iroq...'.tr;
        } else if (showCalling || showConnecting) {
          statusText = 'Ulanmoqda...'.tr;
        } else if (showInCall) {
          statusText = _callService.callDuration;
        } else {
          statusText = '';
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Status text
                  Text(
                    showInCall ? 'Ovozli qo\'ng\'iroq'.tr : '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Duration / Status
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      statusText,
                      key: ValueKey(statusText),
                      style: TextStyle(
                        color: showInCall
                            ? const Color(0xFF00D26A)
                            : Colors.white,
                        fontSize: showInCall ? 18 : 16,
                        fontWeight: showInCall
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Avatar with pulse animation
                  _buildAvatar(showRinging || showCalling),

                  const SizedBox(height: 24),

                  // Name
                  Text(
                    _callService.remoteUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // Zakaz qo'ng'irog'i belgisi — bu buyurtma bo'yicha qo'ng'iroq.
                  if (_callService.isOrderCall) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF22C55E),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Zakaz qo\'ng\'irog\'i'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(flex: 2),

                  // Controls
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: _isAccepted || !widget.isIncoming
                        ? _buildActiveControls()
                        : _buildIncomingControls(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(bool animate) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse rings
        if (animate) ...[
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 140 * _pulseAnimation.value,
                height: 140 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D26A).withValues(
                      alpha: 1.0 - (_pulseAnimation.value - 1.0) * 2.5,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
        ],
        // Main avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00D26A), Color(0xFF0BA360)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D26A),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: animate
              ? AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _ringAnimation.value,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                )
              : const Icon(Icons.person, size: 60, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildIncomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCallButton(
          icon: Icons.call_end,
          label: 'Rad etish'.tr,
          color: const Color(0xFFE53935),
          onTap: _declineCall,
        ),
        _buildCallButton(
          icon: Icons.call,
          label: 'Qabul qilish'.tr,
          color: const Color(0xFF00D26A),
          onTap: _acceptCall,
        ),
      ],
    );
  }

  Widget _buildActiveControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSmallButton(
              icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
              label: _callService.isMuted ? 'Ovoz yoq'.tr : 'Mikrofon'.tr,
              isActive: _callService.isMuted,
              onTap: _callService.toggleMute,
            ),
            _buildSmallButton(
              icon: _callService.isSpeaker
                  ? Icons.volume_up
                  : Icons.volume_down,
              label: _callService.isSpeaker ? 'Karnay'.tr : 'Quloq'.tr,
              isActive: _callService.isSpeaker,
              onTap: _callService.toggleSpeaker,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildCallButton(
          icon: Icons.call_end,
          label: 'Tugatish'.tr,
          color: const Color(0xFFE53935),
          onTap: _endCall,
          size: 70,
        ),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 64,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF16213E) : Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
