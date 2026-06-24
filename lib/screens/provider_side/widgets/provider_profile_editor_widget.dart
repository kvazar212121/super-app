import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';

class ProviderProfileEditorWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderProfileEditorWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<ProviderProfileEditorWidget> createState() => _ProviderProfileEditorWidgetState();
}

class _ProviderProfileEditorWidgetState extends State<ProviderProfileEditorWidget> {
  final _portal = ProviderPortalService();
  final _nameCtrl = TextEditingController();
  
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _baseMeta = {};
  String? _coverUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _portal.getMe(widget.categoryKey);
      final meta = Map<String, dynamic>.from(data['metadata_json'] as Map<String, dynamic>? ?? {});
      _baseMeta = meta;
      _nameCtrl.text = meta['display_name'] ?? data['name'] ?? '';
      _coverUrl = meta['cover_url'];
    } catch (_) {
      // Ignored
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? finalCoverUrl = _coverUrl;

      // Upload image if a new one is selected
      if (_selectedImage != null) {
        finalCoverUrl = await _portal.uploadCover(_selectedImage!.path);
      }

      final meta = Map<String, dynamic>.from(_baseMeta);
      meta['display_name'] = _nameCtrl.text.trim();
      if (finalCoverUrl != null) {
        meta['cover_url'] = finalCoverUrl;
      }

      await _portal.updateMetadata(widget.categoryKey, meta);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil ma'lumotlari saqlandi")),
        );
        setState(() {
          _coverUrl = finalCoverUrl;
          _selectedImage = null; // Clear picked state after successful save
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saqlashda xatolik yuz berdi')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Asosiy ma'lumotlar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Spacer(),
            IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _load),
          ],
        ),
        const SizedBox(height: 16),
        
        // Banner Image Editor
        const Text(
          'Muqova rasmi (Banner)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : (_coverUrl != null && _coverUrl!.isNotEmpty)
                    ? Image.network(
                        _coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(LucideIcons.image, size: 40, color: Colors.black26)),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.imagePlus, size: 32, color: Colors.black45),
                            SizedBox(height: 8),
                            Text('Rasm tanlash', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 16),

        // Display Name Editor
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Ismingiz yoki tashkilot nomi',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Asosiy ma'lumotlarni saqlash", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
