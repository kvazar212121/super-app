import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/lux_tokens.dart';
import '../../l10n/locale_controller.dart';
import '../../services/todo_local_service.dart';

/// 24K Oltin Jonli Mikrofon Tugmasi — "Mening Rejalarim" sahifasining o'zidan
/// ovozli buyruq yoki ovozli qayd kiritish uchun.
class TodoVoiceMicButton extends StatelessWidget {
  final VoidCallback onDataChanged;

  const TodoVoiceMicButton({
    super.key,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: LuxTokens.goldBoxDecoration(radius: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openVoiceModal(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF140D02),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.mic,
                    color: LuxTokens.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ovozli buyruq yuborish...'.tr,
                  style: const TextStyle(
                    fontFamily: LuxTokens.body,
                    color: Color(0xFF140D02),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.sparkles,
                  color: Color(0xFF140D02),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVoiceModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AiVoiceRecordingModal(onDataChanged: onDataChanged),
    );
  }
}

class _AiVoiceRecordingModal extends StatefulWidget {
  final VoidCallback onDataChanged;

  const _AiVoiceRecordingModal({required this.onDataChanged});

  @override
  State<_AiVoiceRecordingModal> createState() => _AiVoiceRecordingModalState();
}

class _AiVoiceRecordingModalState extends State<_AiVoiceRecordingModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  bool _isListening = true;
  String _statusText = 'Ovoz yozib olinmoqda... Tap qiling yoki gapiring.';
  String _recognizedText = '';

  bool get isListening => _isListening;

  final List<String> _sampleVoiceCommands = [
    '💧 500 ml suv ichdim',
    '💊 Soat 20:00 da vitamin ichishni eslat',
    '🎯 Har kuni kitob o\'qish odatini qo\'sh',
    '📝 Usta bilan soat 14:00 da uchrashuv bor',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _processVoiceCommand(String command) async {
    setState(() {
      _isListening = false;
      _recognizedText = command;
      _statusText = 'AI tahlil qilmoqda va saqlamoqda...';
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final service = TodoLocalService();
    final today = DateTime.now();

    if (command.contains('suv') || command.contains('ml')) {
      int amount = 350;
      if (command.contains('500')) amount = 500;
      if (command.contains('250')) amount = 250;
      await service.addWaterIntake(today, amount);
    } else if (command.contains('kitob') || command.contains('odat')) {
      await service.addHabit('Kitob o\'qish odati', 'book');
    } else if (command.contains('vitamin') || command.contains('dori')) {
      await service.addPill('Vitaminkalar', '1 kapsula', ['20:00']);
    } else {
      // Voice Note & Task
      await service.addVoiceNote('Ovozli eslatma', command, 10);
      await service.addTask({
        'id': 'task_${DateTime.now().millisecondsSinceEpoch}',
        'date': service.formatDate(today),
        'title': command,
        'time': "${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}",
        'is_done': false,
        'category': 'ovozli',
      });
    }

    widget.onDataChanged();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Ovozli buyruq saqlandi: "$command"'),
          backgroundColor: const Color(0xFF140D02),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? LuxTokens.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: LuxTokens.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.sparkles, color: LuxTokens.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                'AI Ovozli Yordamchi'.tr,
                style: TextStyle(
                  fontFamily: LuxTokens.body,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 24),

          // Animated Soundwave Visualizer
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final scale = 1.0 + (_waveController.value * 0.18);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LuxTokens.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: LuxTokens.gold.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: _waveController.value * 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF140D02),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.mic,
                        color: LuxTokens.gold,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: LuxTokens.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LuxTokens.gold, width: 1.2),
              ),
              child: Text(
                '"$_recognizedText"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8A5D0B),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Sample Voice Commands list
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ovozli namuna buyruqlari:'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: _sampleVoiceCommands.map((cmd) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _processVoiceCommand(cmd),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cmd,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D02),
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: LuxTokens.gold,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
