import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/api_service.dart';
import '../theme/lux_tokens.dart';

/// Hujjat rasmini tanlash va serverga yuklash.
class DocumentUploadTile extends StatefulWidget {
  final String label;
  final String? subtitle;
  final String? url;
  final ValueChanged<String?> onUrlChanged;
  final Color accent;

  const DocumentUploadTile({
    super.key,
    required this.label,
    this.subtitle,
    this.url,
    required this.onUrlChanged,
    this.accent = const Color(0xFFEBD79B),
  });

  @override
  State<DocumentUploadTile> createState() => _DocumentUploadTileState();
}

class _DocumentUploadTileState extends State<DocumentUploadTile> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await ApiService().uploadCover(file.path);
      widget.onUrlChanged(url);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${widget.label} yuklandi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yuklashda xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.url != null && widget.url!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasUrl ? widget.accent : Colors.grey),
        color: hasUrl ? widget.accent : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasUrl ? LucideIcons.circleCheck : LucideIcons.upload,
              color: widget.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(fontSize: 12, color: LuxTokens.textMuted),
                  ),
                if (hasUrl)
                  Text(
                    'Yuklangan ✓',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (_uploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: _pickAndUpload,
              child: Text(hasUrl ? 'Almashtirish' : 'Yuklash'),
            ),
        ],
      ),
    );
  }
}
