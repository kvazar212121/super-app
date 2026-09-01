import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/lux_tokens.dart';
import '../../l10n/locale_controller.dart';
import '../../services/todo_local_service.dart';

class VoiceNotesWidget extends StatefulWidget {
  final VoidCallback onChanged;

  const VoiceNotesWidget({
    super.key,
    required this.onChanged,
  });

  @override
  State<VoiceNotesWidget> createState() => _VoiceNotesWidgetState();
}

class _VoiceNotesWidgetState extends State<VoiceNotesWidget> {
  final TodoLocalService _service = TodoLocalService();
  List<Map<String, dynamic>> _voiceNotes = [];
  bool _isLoading = true;
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _service.getVoiceNotes();
    if (mounted) {
      setState(() {
        _voiceNotes = list;
        _isLoading = false;
      });
    }
  }

  void _togglePlay(String noteId) {
    setState(() {
      if (_currentlyPlayingId == noteId) {
        _currentlyPlayingId = null;
      } else {
        _currentlyPlayingId = noteId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: LuxTokens.gold));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ovozli Qaydlar va Matnlar:'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          if (_voiceNotes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? LuxTokens.surface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LuxTokens.border),
              ),
              child: Center(
                child: Text(
                  'Hali ovozli qaydlar saqlanmadi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            Column(
              children: _voiceNotes.map<Widget>((note) {
                final bool isPlaying = _currentlyPlayingId == note['id'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? LuxTokens.surface : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isPlaying
                          ? LuxTokens.gold
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isPlaying ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isPlaying
                            ? LuxTokens.gold.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _togglePlay(note['id']),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: LuxTokens.goldBoxDecoration(radius: 14),
                              child: Icon(
                                isPlaying ? LucideIcons.pause : LucideIcons.play,
                                color: const Color(0xFF140D02),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note['title'] ?? 'Ovozli qayd',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${note['date']} · ${note['time']} · ${note['duration_sec']} sek',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Transcription box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.quote,
                              size: 16,
                              color: LuxTokens.gold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note['transcription'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
