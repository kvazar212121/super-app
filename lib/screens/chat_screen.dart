import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Bottom padding for SafeArea
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
                : () {
                    // STT (Speech-to-Text) logic will go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ovozli xabar kiritish keyingi yangilanishda qo'shiladi")),
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hasText
                      ? [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)], // Green for mic
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
