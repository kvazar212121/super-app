import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';

/// Abonent bilan yozishma (SMS-uslub, foydalanuvchilararo).
class DmChatScreen extends StatefulWidget {
  final int peerId;
  final String peerName;

  /// Qaysi ish e'loni bo'yicha yozishma. Berilsa yuborilgan xabarlar
  /// shu e'longa bog'lanadi va suhbatdoshda "Bu e'lon bo'yicha"
  /// ko'rsatkichi chiqadi.
  final int? jobId;

  const DmChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.jobId,
  });

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  /// Suhbatdoshning usta profili (bo'lsa): reyting, sharhlar soni.
  /// Mijoz kim bilan gaplashayotganini bilishi kerak.
  Map<String, dynamic>? _peerProvider;
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final res = await _api.getDmThread(widget.peerId);
      final msgs = (res['messages'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) {
        final hadNew = msgs.length != _messages.length;
        setState(() {
          _messages = msgs;
          _peerProvider = res['peer_provider'] == null
              ? null
              : Map<String, dynamic>.from(res['peer_provider'] as Map);
          _loading = false;
        });
        if (hadNew) _scrollToEnd();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    setState(() {
      _messages.add({'text': text, 'is_mine': true, 'created_at': null, 'pending': true});
    });
    _scrollToEnd();
    try {
      await _api.sendDirectMessage(widget.peerId, text, jobId: widget.jobId);
      await _load(silent: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yuborilmadi. Qayta urinib ko\'ring.'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: widget.peerName,
      body: Column(
        children: [
          _providerHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _empty()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _bubble(_messages[i]),
                      ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 52, color: GlassTokens.secondaryText(context)),
            const SizedBox(height: 14),
            Text(
              'Hali xabar yo\'q. Birinchi bo\'lib yozing.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: GlassTokens.secondaryText(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final isMine = m['is_mine'] == true;
    final pending = m['pending'] == true;
    final color = isMine ? const Color(0xFF6366F1) : GlassTokens.glassFill(context);
    final textColor = isMine ? Colors.white : GlassTokens.primaryText(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: GlassTokens.glassBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // "Bu e'lon bo'yicha" — mijozda bir vaqtda bir necha e'lon
            // bo'lishi mumkin, qaysi biri haqida ekani ko'rinishi kerak
            if (m['job'] != null) _jobTag(m['job'] as Map, textColor),
            Text(m['text'] as String? ?? '', style: TextStyle(color: textColor, fontSize: 15)),
            if (pending)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'yuborilmoqda…'.tr,
                  style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Xabar qaysi e'lon bo'yicha kelgani.
  Widget _jobTag(Map job, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 13, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${'Bu e\'lon bo\'yicha'.tr}: ${job['title'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Suhbatdosh usta bo'lsa — reytingi va sharhlar soni.
  Widget _providerHeader() {
    final p = _peerProvider;
    if (p == null) return const SizedBox.shrink();
    final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = (p['review_count'] as int?) ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTokens.glassBorder(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              p['name'] as String? ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
          const SizedBox(width: 3),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '—',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            '($reviews)',
            style: TextStyle(color: GlassTokens.secondaryText(context)),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: TextStyle(color: GlassTokens.primaryText(context)),
                decoration: InputDecoration(
                  hintText: 'Xabar yozing...'.tr,
                  filled: true,
                  fillColor: GlassTokens.glassFill(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
