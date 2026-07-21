import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// HubServis huquqiy hujjati (foydalanish shartlari / maxfiylik / FAQ).
/// Matn backenddan (admin panelдан tahrirlanadi) olinadi; xato bo'lsa zaxira matn ko'rsatiladi.
class TermsScreen extends StatefulWidget {
  final String doc; // terms | privacy | faq
  const TermsScreen({super.key, this.doc = 'terms'});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String? _content;
  bool _loading = true;

  static const Map<String, String> _titles = {
    'terms': 'Foydalanish shartlari',
    'privacy': 'Maxfiylik siyosati',
    'faq': 'Ko\'p so\'raladigan savollar',
  };

  static const String _fallback =
      'HubServis — Foydalanish shartlari\n\n'
      'Ilovadan foydalanish orqali siz xizmat shartlariga rozilik bildirasiz. '
      'To\'liq matnni internetga ulanganда ko\'rishingiz mumkin.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final legal = await ApiService().getLegal();
      final c = legal[widget.doc];
      _content = (c is String && c.trim().isNotEmpty) ? c : _fallback;
    } catch (_) {
      _content = _fallback;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = _titles[widget.doc] ?? 'Hujjat';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [..._buildParagraphs(context, _content ?? _fallback)],
            ),
    );
  }

  List<Widget> _buildParagraphs(BuildContext context, String text) {
    final blocks = text.split('\n\n').where((b) => b.trim().isNotEmpty);
    return blocks.map((b) {
      final lines = b.split('\n');
      final first = lines.first.trim();
      // Qisqa birinchi qator — sarlavha sifatida
      final isHeading = first.length < 60 && lines.length > 1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHeading) ...[
              Text(
                first,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lines.skip(1).join('\n'),
                style: TextStyle(
                  height: 1.55,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ] else
              Text(
                b,
                style: TextStyle(
                  height: 1.55,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
      );
    }).toList();
  }
}
