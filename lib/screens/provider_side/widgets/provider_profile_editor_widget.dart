import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';
import '../../../services/hub_data_service.dart';
import '../../../services/settings_save_controller.dart';
import '../../../config/app_config.dart';
import 'package:super_app/l10n/locale_controller.dart';

class ProviderProfileEditorWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;
  final bool showSaveButton;
  final SettingsSaveController? saveController;

  const ProviderProfileEditorWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
    this.showSaveButton = true,
    this.saveController,
  });

  @override
  State<ProviderProfileEditorWidget> createState() =>
      _ProviderProfileEditorWidgetState();
}

class _ProviderProfileEditorWidgetState
    extends State<ProviderProfileEditorWidget> {
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
    widget.saveController?.register(_saveExternal);
  }

  @override
  void dispose() {
    widget.saveController?.deregister(_saveExternal);
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<bool> _saveExternal() async {
    try {
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _portal.getMe(widget.categoryKey);
      final meta = Map<String, dynamic>.from(
        data['metadata_json'] as Map<String, dynamic>? ?? {},
      );
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
      try {
        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          targetPath,
          quality: 70,
          format: CompressFormat.jpeg,
        );
        if (compressedFile != null) {
          setState(() {
            _selectedImage = File(compressedFile.path);
          });
        }
      } catch (e) {
        // Fallback if compression fails
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
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

      final latestData = await _portal.getMe(widget.categoryKey);
      final latestMeta = Map<String, dynamic>.from(
        latestData['metadata'] as Map<String, dynamic>? ??
            latestData['metadata_json'] as Map<String, dynamic>? ??
            {},
      );
      final meta = Map<String, dynamic>.from(latestMeta);
      meta['display_name'] = _nameCtrl.text.trim();
      if (finalCoverUrl != null) {
        meta['cover_url'] = finalCoverUrl;
      }

      await _portal.updateMetadata(widget.categoryKey, meta);
      if (finalCoverUrl != null) {
        await _portal.updateCover(widget.categoryKey, finalCoverUrl);
      }

      // Clear cache so that the client immediately reflects the updated name/banner
      HubDataService().clearCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil ma'lumotlari saqlandi".tr)),
        );
        setState(() {
          _coverUrl = finalCoverUrl;
          _selectedImage = null; // Clear picked state after successful save
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saqlashda xatolik yuz berdi'.tr)),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _load,
            ),
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
                    AppConfig.formatImageUrl(_coverUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 40,
                        color: Colors.black26,
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.imagePlus,
                          size: 32,
                          color: Colors.black45,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Rasm tanlash',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Display Name Editor
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Ismingiz yoki tashkilot nomi'.tr,
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),

        // Save Button
        if (widget.showSaveButton) ...[
          const SizedBox(height: 16),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Asosiy ma'lumotlarni saqlash",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
