import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';
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
          "Assalomu alaykum! Men HubServis SuperApp'ning sun'iy intellekt yordamchisiman. Ilova bo'yicha qanday savollaringiz bor? Sizga bajonidil yordam beraman. 🤖✨"
              .tr,
    });

    _initSpeechEngine().then((_) {
      if (widget.startVoice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startRecording();
        });
      }
    });
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
                  'Ovoz yozishda xatolik yuz berdi'.tr + ': ${error.errorMsg}',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mikrofonga ruxsat berilmadi'.tr)));
      return;
    }

    if (!_isSpeechInitialized) {
      await _initSpeechEngine();
      if (!_isSpeechInitialized) {
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
        _chatHistory.add({'role': 'assistant', 'content': response});
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'AI Yordamchi'.tr,
      actions: [
        IconButton(
          icon: Icon(
            LucideIcons.refreshCcw,
            color: GlassTokens.primaryText(context),
            size: 20,
          ),
          onPressed: () {
            _aiService.clearHistory();
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
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String content, required bool isUser}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
    );
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
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isRecording
                        ? (isDark
                              ? Colors.red.withOpacity(0.1)
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
                            ? Colors.redAccent.withOpacity(0.7)
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
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : (_hasText
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF10B981))
                                        .withOpacity(0.5),
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
        ),
      ),
    );
  }
}
