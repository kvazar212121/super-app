import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../models/master_worker.dart';
import 'orders_screen.dart';
import 'provider_profile_screen.dart';
import '../models/service_hub_kind.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';

enum _VoiceState { idle, recording, processing }

class ChatScreen extends StatefulWidget {
  final bool startVoice;
  const ChatScreen({super.key, this.startVoice = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final AiService _aiService = AiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isTyping = false;
  bool _hasText = false;

  // Speech to Text variables
  _VoiceState _voiceState = _VoiceState.idle;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  String _speechLocale = 'uz_UZ';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  // Mikrofon ovoz balandligi (ekvalayzer chiziqlarini jonlantirish uchun).
  double _soundLevel = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _chatHistory.add({
      'role': 'assistant',
      'content':
          "Assalomu alaykum! Men AiHub — HubServis SuperApp'ning sun'iy intellekt yordamchisiman. Ilova bo'yicha qanday savollaringiz bor? Sizga bajonidil yordam beraman. 🤖✨"
              .tr,
    });

    // Saqlangan chat tarixini yuklaymiz (ilova qayta ochilganda ham chat qoladi).
    _loadSavedHistory();

    _initSpeechEngine().then((_) {
      if (widget.startVoice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startRecording();
        });
      }
    });
  }

  /// AiService diskdagi tarixni yuklaydi va ekranga qo'shadi.
  Future<void> _loadSavedHistory() async {
    try {
      final saved = await _aiService.loadHistory();
      if (saved.isEmpty || !mounted) return;
      setState(() {
        for (final m in saved) {
          _chatHistory.add({
            'role': m['role'] ?? 'assistant',
            'content': m['content'] ?? '',
          });
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeechEngine() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' &&
              _voiceState == _VoiceState.recording &&
              mounted) {
            _stopRecordingAndSend();
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            _resetVoiceState();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${'Ovoz yozishda xatolik yuz berdi'.tr}: ${error.errorMsg}',
                ),
              ),
            );
          }
        },
      );
      if (available && mounted) {
        _isSpeechInitialized = true;
        try {
          var locales = await _speech.locales();
          for (var loc in locales) {
            if (loc.localeId.startsWith('uz')) {
              _speechLocale = loc.localeId;
              break;
            }
          }
        } catch (e) {
          debugPrint('Locales error: $e');
        }
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  void _startRecording() async {
    if (_voiceState == _VoiceState.recording) return;

    bool hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mikrofonga ruxsat berilmadi'.tr)));
      return;
    }

    if (!_isSpeechInitialized) {
      await _initSpeechEngine();
      if (!_isSpeechInitialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ovozli tizim faollashmadi'.tr)));
        return;
      }
    }

    setState(() {
      _voiceState = _VoiceState.recording;
      _textController.clear();
    });
    _pulseController.repeat(reverse: true);

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          }
        },
        onSoundLevelChange: (level) {
          // Ekvalayzer chiziqlari shu qiymatga qarab jonlanadi.
          if (mounted) setState(() => _soundLevel = level);
        },
        localeId: _speechLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('Speech listen exception: $e');
      _resetVoiceState();
    }
  }

  void _stopRecordingAndSend() async {
    _pulseController.stop();
    _pulseController.reset();

    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Speech stop error: $e');
    }

    if (!mounted) return;

    final text = _textController.text.trim();
    if (text.isEmpty) {
      _resetVoiceState();
      return;
    }

    setState(() {
      _voiceState = _VoiceState.processing;
    });

    await _sendMessage(text: text, isVoice: true);

    if (mounted) {
      _resetVoiceState();
    }
  }

  void _resetVoiceState() {
    if (mounted) {
      setState(() {
        _voiceState = _VoiceState.idle;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage({String? text, bool isVoice = false}) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _chatHistory.add({
        'role': 'user',
        'content': isVoice ? '🎤 $messageText' : messageText,
      });
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    final response = await _aiService.sendMessage(messageText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _chatHistory.add({
          'role': 'assistant',
          'content': response,
          // AI amallari (masalan bron yaratildi) — chatда tugma ko'rsatish uchun.
          'actions': List<Map<String, dynamic>>.from(_aiService.lastActions),
        });
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'AiHub'.tr,
      actions: [
        IconButton(
          icon: Icon(
            LucideIcons.refreshCcw,
            color: GlassTokens.primaryText(context),
            size: 20,
          ),
          onPressed: () {
            unawaited(_aiService.clearHistory());
            setState(() {
              _chatHistory.clear();
              _chatHistory.add({
                'role': 'assistant',
                'content':
                    "Chat tozalab tashlandi. Sizga yana qanday yordam bera olaman?"
                        .tr,
              });
            });
          },
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatHistory.length) {
                  return _buildTypingIndicator();
                }
                final message = _chatHistory[index];
                return _buildMessageBubble(
                  content: message['content'],
                  isUser: message['role'] == 'user',
                  actions: (message['actions'] as List?)
                      ?.cast<Map<String, dynamic>>(),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isUser,
    List<Map<String, dynamic>>? actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionButtons = isUser ? const <Widget>[] : _actionButtons(actions);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: actionButtons.isEmpty ? 16 : 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.blue
                  : (isDark ? const Color(0xFF334155) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              border: Border.all(
                color: isUser ? Colors.blue : GlassTokens.glassBorder(context),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          if (actionButtons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
            ),
        ],
      ),
    );
  }

  /// AI amallaridan chatда bosiladigan tugma yasaydi. Masalan bron yaratilса —
  /// "Buyurtmani ko'rish" tugmasi (Buyurtmalar bo'limiga o'tadi).
  List<Widget> _actionButtons(List<Map<String, dynamic>>? actions) {
    if (actions == null || actions.isEmpty) return const [];
    final buttons = <Widget>[];
    for (final a in actions) {
      final type = a['type'];
      if (type == 'booking_created') {
        final providerName = a['provider_name'] as String?;
        buttons.add(_chatActionButton(
          icon: LucideIcons.calendarCheck,
          label: providerName != null
              ? "${'Bron'.tr}: $providerName"
              : 'Buyurtmani ko\'rish'.tr,
          onTap: () => _openBookings(),
        ));
      } else if (type == 'provider_list') {
        // Har provayder uchun ALOHIDA tugma — bosilса o'sha provayderning
        // bron/profil sahifasi ochiladi.
        final key = a['category_key'] as String?;
        final provs = (a['providers'] as List?) ?? const [];
        for (final p in provs) {
          final pm = Map<String, dynamic>.from(p as Map);
          final id = (pm['id'] as num?)?.toInt();
          final name = pm['name'] as String? ?? '';
          if (id == null) continue;
          buttons.add(_chatActionButton(
            icon: LucideIcons.calendarPlus,
            label: name.isNotEmpty ? name : 'Bron qilish'.tr,
            onTap: () => _openProviderBooking(id, key),
          ));
        }
      } else if (type == 'orders_changed') {
        buttons.add(_chatActionButton(
          icon: LucideIcons.shoppingBag,
          label: 'Buyurtmalarim'.tr,
          onTap: () => _openBookings(),
        ));
      } else if (type == 'navigate' && a['route'] is String) {
        // Kelajakда backend 'navigate' action bersa — shu ishlaydi.
        buttons.add(_chatActionButton(
          icon: LucideIcons.arrowRight,
          label: (a['label'] as String?) ?? 'Ochish'.tr,
          onTap: () => _handleNavigate(a['route'] as String),
        ));
      }
    }
    return buttons;
  }

  Widget _chatActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookings() {
    // Buyurtmalar ro'yxati ekraniga o'tadi.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
  }

  /// Provayder id bo'yicha to'liq ma'lumot olib, uning bron/profil sahifasini
  /// ochadi. Foydalanuvchi o'sha yerда vaqt tanlaб bron qiladi.
  Future<void> _openProviderBooking(int providerId, String? categoryKey) async {
    ServiceHubKind kind = ServiceHubKind.sartarosh;
    if (categoryKey != null) {
      try {
        kind = ServiceHubKind.values.byName(categoryKey);
      } catch (_) {}
    }
    // Yuklanmoqda indikatori
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final json = await ApiService().getProvider(providerId);
      final master = Master.fromProviderJson(json);
      if (!mounted) return;
      Navigator.pop(context); // yuklanmoqda dialogини yopamiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderProfileScreen(master: master, category: kind),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provayderni ochib bo\'lmadi'.tr)),
      );
    }
  }

  void _handleNavigate(String route) {
    // Backend kelajakда 'navigate' action bersa — bu yerда route bo'yicha
    // tegishli ekranga o'tkazish qo'shiladi. Hozircha buyurtmalar.
    _openBookings();
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: GlassTokens.glassBorder(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yozmoqda'.tr,
              style: TextStyle(
                color: GlassTokens.secondaryText(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ovozga reaksiya qiluvchi ekvalayzer — recording paytida input ustida.
  Widget _buildEqualizer() {
    final norm = (_soundLevel.clamp(0, 10)) / 10.0; // 0..1
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final t = _pulseController.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(11, (i) {
              final phase = i * 0.6;
              final wave = 0.5 + 0.5 * math.sin(t * 2 * math.pi + phase);
              final h = 6.0 + (8 + norm * 34) * wave;
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRecording = _voiceState == _VoiceState.recording;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: GlassTokens.glassBorder(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecording) _buildEqualizer(),
              Row(
                children: [
                  Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isRecording
                        ? (isDark
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.red.shade50)
                        : (isDark ? Colors.black : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isRecording
                          ? Colors.redAccent
                          : GlassTokens.glassBorder(context),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                      color: isRecording
                          ? Colors.redAccent
                          : GlassTokens.primaryText(context),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!isRecording) _sendMessage();
                    },
                    readOnly: isRecording,
                    decoration: InputDecoration(
                      hintText: isRecording
                          ? 'Eshitilmoqda...'.tr
                          : 'Xabar yozish...'.tr,
                      hintStyle: TextStyle(
                        color: isRecording
                            ? Colors.redAccent.withValues(alpha: 0.7)
                            : GlassTokens.secondaryText(context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (_hasText && !isRecording) {
                    if (!_isTyping) _sendMessage();
                  } else if (isRecording) {
                    _stopRecordingAndSend();
                  } else {
                    _startRecording();
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isRecording ? _pulseAnim.value : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRecording
                                ? [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626),
                                  ]
                                : _hasText
                                ? [
                                    const Color(0xFF8B5CF6),
                                    const Color(0xFF3B82F6),
                                  ]
                                : [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isRecording
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : (_hasText
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF10B981))
                                        .withValues(alpha: 0.5),
                              blurRadius: isRecording ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording
                              ? LucideIcons
                                    .square // Stop icon
                              : (_hasText ? LucideIcons.send : LucideIcons.mic),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
