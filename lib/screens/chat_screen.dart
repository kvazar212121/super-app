import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import '../services/ai_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isTyping = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });
    // Add initial greeting message
    _chatHistory.add({
      'role': 'assistant',
      'content': "Assalomu alaykum! Men HubServis SuperApp'ning sun'iy intellekt yordamchisiman. Ilova bo'yicha qanday savollaringiz bor? Sizga bajonidil yordam beraman. 🤖✨",
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    final response = await _aiService.sendMessage(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _chatHistory.add({'role': 'assistant', 'content': response});
      });
      _scrollToBottom();
    }
  }

  /// AI ovozli xabar modali — mikrofon bosilganda ochiladi
  void _showVoiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceMessageModal(
        onSend: (text) async {
          // Chat tarixiga qo'shish
          setState(() {
            _chatHistory.add({'role': 'user', 'content': '🎤 $text'});
            _isTyping = true;
          });
          _scrollToBottom();

          // AI ga yuborish
          final response = await _aiService.sendMessage(text);

          if (mounted) {
            setState(() {
              _isTyping = false;
              _chatHistory.add({'role': 'assistant', 'content': response});
            });
            _scrollToBottom();
          }

          return response;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'AI Yordamchi',
      actions: [
        IconButton(
          icon: Icon(LucideIcons.refreshCcw, color: GlassTokens.primaryText(context), size: 20),
          onPressed: () {
            _aiService.clearHistory();
            setState(() {
              _chatHistory.clear();
              _chatHistory.add({
                'role': 'assistant',
                'content': "Chat tozalab tashlandi. Sizga yana qanday yordam bera olaman?",
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
              ? (isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2))
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          border: Border.all(
            color: isUser
                ? Colors.blue.withValues(alpha: 0.3)
                : GlassTokens.glassBorder(context),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: GlassTokens.primaryText(context),
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
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6),
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
            Text('Yozmoqda', style: TextStyle(color: GlassTokens.secondaryText(context), fontSize: 13)),
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: GlassTokens.glassBorder(context)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: GlassTokens.glassBorder(context)),
              ),
              child: TextField(
                controller: _textController,
                style: TextStyle(color: GlassTokens.primaryText(context)),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Xabar yozish...',
                  hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _hasText
                ? (_isTyping ? null : _sendMessage)
                : _showVoiceModal,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hasText
                      ? [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_hasText ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _hasText ? LucideIcons.send : LucideIcons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Ovozli xabar modali
// ══════════════════════════════════════════════════════════

enum _VoiceState { idle, recording, sending, response }

class _VoiceMessageModal extends StatefulWidget {
  final Future<String> Function(String text) onSend;

  const _VoiceMessageModal({required this.onSend});

  @override
  State<_VoiceMessageModal> createState() => _VoiceMessageModalState();
}

class _VoiceMessageModalState extends State<_VoiceMessageModal>
    with SingleTickerProviderStateMixin {
  _VoiceState _state = _VoiceState.idle;
  final TextEditingController _voiceTextController = TextEditingController();
  String _aiResponse = '';
  String _errorMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceTextController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _state = _VoiceState.recording;
      _recordSeconds = 0;
      _errorMessage = '';
    });
    _pulseController.repeat(reverse: true);

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordSeconds++);
      }
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final text = _voiceTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _state = _VoiceState.idle;
        _errorMessage = 'Iltimos, xabar matnini kiriting';
      });
      return;
    }

    _sendToAI(text);
  }

  Future<void> _sendToAI(String text) async {
    setState(() => _state = _VoiceState.sending);

    try {
      final response = await widget.onSend(text);
      if (mounted) {
        setState(() {
          _aiResponse = response;
          _state = _VoiceState.response;
        });

        // 5 soniyadan keyin avtomatik yopish
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _state == _VoiceState.response) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _VoiceState.idle;
          _errorMessage = 'Xatolik yuz berdi';
        });
      }
    }
  }

  String get _formattedTime {
    final m = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sarlavha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.bot, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Ovozli xabar',
                  style: TextStyle(
                    color: GlassTokens.primaryText(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  LucideIcons.x,
                  color: GlassTokens.secondaryText(context),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Asosiy kontent — holatga qarab
          if (_state == _VoiceState.idle) _buildIdleState(),
          if (_state == _VoiceState.recording) _buildRecordingState(),
          if (_state == _VoiceState.sending) _buildSendingState(),
          if (_state == _VoiceState.response) _buildResponseState(),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _voiceTextController,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(
              color: GlassTokens.primaryText(context),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'AI ga savolingizni yozing...',
              hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Icon(
                  LucideIcons.messageCircle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(LucideIcons.mic, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bosing va xabaringizni yozing',
          style: TextStyle(
            color: GlassTokens.secondaryText(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: _voiceTextController,
            maxLines: 3,
            minLines: 2,
            autofocus: true,
            style: TextStyle(
              color: GlassTokens.primaryText(context),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Xabaringizni yozing...',
              hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _formattedTime,
          style: TextStyle(
            color: Colors.red.shade400,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bekor qilish
            GestureDetector(
              onTap: () {
                _recordTimer?.cancel();
                _pulseController.stop();
                _pulseController.reset();
                setState(() {
                  _state = _VoiceState.idle;
                  _voiceTextController.clear();
                });
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Icon(LucideIcons.x, color: Colors.red.shade400, size: 22),
              ),
            ),
            const SizedBox(width: 24),
            // Pulsatsiya animatsiyasi
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.mic, color: Colors.white, size: 30),
                  ),
                );
              },
            ),
            const SizedBox(width: 24),
            // Yuborish tugmasi
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Yozib bo\'lgach ➡️ yuborish tugmasini bosing',
          style: TextStyle(
            color: GlassTokens.secondaryText(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSendingState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'AI javob yozmoqda...',
          style: TextStyle(
            color: GlassTokens.primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Biroz kuting ⏳',
          style: TextStyle(
            color: GlassTokens.secondaryText(context),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResponseState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                const Color(0xFF3B82F6).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.bot, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI javobi',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.check, color: Colors.green.shade400, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _aiResponse,
                style: TextStyle(
                  color: GlassTokens.primaryText(context),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.check, size: 18),
            label: const Text('Tayyor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '5 soniyadan keyin avtomatik yopiladi',
          style: TextStyle(
            color: GlassTokens.secondaryText(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
