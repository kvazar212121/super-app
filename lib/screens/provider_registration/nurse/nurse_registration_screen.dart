import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/nurse_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/nurse_portal_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../../map_address_picker_screen.dart';
import 'nurse_pending_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class NurseRegistrationScreen extends StatefulWidget {
  const NurseRegistrationScreen({super.key});

  @override
  State<NurseRegistrationScreen> createState() =>
      _NurseRegistrationScreenState();
}

class _NurseRegistrationScreenState extends State<NurseRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _qualCtrl = TextEditingController(text: 'Malakali hamshira');
  bool _submitting = false;
  final Set<String> _medicalTypes = {'injection', 'blood_test', 'drip'};

  // Hujjat fayllari
  File? _documentFile; // diplom yoki sertifikat
  File? _passportFile; // pasport
  String? _documentUrl;
  String? _passportUrl;
  bool _uploadingDoc = false;
  bool _uploadingPassport = false;

  final _picker = ImagePicker();

  static const accent = Color(0xFF2563EB);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _qualCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload({required bool isPassport}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Kamera'.tr),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galereya'.tr),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked == null) return;

    final file = File(picked.path);
    if (isPassport) {
      setState(() {
        _passportFile = file;
        _uploadingPassport = true;
      });
    } else {
      setState(() {
        _documentFile = file;
        _uploadingDoc = true;
      });
    }

    try {
      final url = await ApiService().uploadFile(file.path);
      if (mounted) {
        setState(() {
          if (isPassport) {
            _passportUrl = url;
          } else {
            _documentUrl = url;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
        if (isPassport) {
          setState(() => _passportFile = null);
        } else {
          setState(() => _documentFile = null);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isPassport) {
            _uploadingPassport = false;
          } else {
            _uploadingDoc = false;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    if (name.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ism va xizmat hududini kiriting'.tr)),
      );
      return;
    }
    if (_documentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Iltimos, diplom yoki sertifikatingizni yuklang'.tr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_passportUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Iltimos, pasportingizni yuklang'.tr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (auth.user?['phone'] as String? ?? '');
    try {
      await NursePortalService().register(
        name: name,
        phone: phone,
        serviceArea: area,
        medicalTypes: _medicalTypes.toList(),
        qualifications: _qualCtrl.text.trim(),
        documentUrl: _documentUrl,
        passportUrl: _passportUrl,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => NursePendingScreen(providerName: name),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Hamshira xizmati'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eslatma
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Faqat uyga chiqish — mijoz manziliga borasiz.\nAdministrator hujjatlaringizni tekshirib, tasdiqlagach ishlay boshlaysiz.'.tr,
                        style: TextStyle(height: 1.4, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ism
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Ism yoki xizmat nomi'.tr,
                ),
              ),
              const SizedBox(height: 12),

              // Telefon
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Hudud
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _areaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Xizmat hududi (manzil)'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.map, color: accent),
                      onPressed: () async {
                        final picked = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapAddressPickerScreen(),
                          ),
                        );
                        if (picked != null && picked.isNotEmpty) {
                          setState(() {
                            _areaCtrl.text = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Malaka
              TextField(
                controller: _qualCtrl,
                decoration: InputDecoration(
                  labelText: 'Malaka darajasi (qisqacha)'.tr,
                ),
              ),
              const SizedBox(height: 20),

              // ── HUJJATLAR ─────────────────────────────────
              Text('Tasdiqlovchi hujjatlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text('Admin ko\'rib chiqishi uchun hujjatlaringizni yuklang'.tr,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Diplom / Sertifikat
              _DocumentUploadTile(
                label: 'Diplom yoki Sertifikat'.tr,
                subtitle: 'Hamshiralik malakasini tasdiqlovchi hujjat'.tr,
                icon: Icons.school_outlined,
                file: _documentFile,
                isUploading: _uploadingDoc,
                isUploaded: _documentUrl != null,
                onTap: () => _pickAndUpload(isPassport: false),
              ),
              const SizedBox(height: 10),

              // Pasport
              _DocumentUploadTile(
                label: 'Pasport'.tr,
                subtitle: 'Shaxsni tasdiqlovchi hujjat (1-2 bet)'.tr,
                icon: Icons.badge_outlined,
                file: _passportFile,
                isUploading: _uploadingPassport,
                isUploaded: _passportUrl != null,
                onTap: () => _pickAndUpload(isPassport: true),
              ),
              const SizedBox(height: 20),

              // Tibbiy xizmatlar
              Text('Tibbiy xizmatlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: MedicalService.values.take(6).map((m) {
                  final selected = _medicalTypes.contains(m.key);
                  return FilterChip(
                    label: Text(m.label.tr),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _medicalTypes.add(m.key);
                      } else if (_medicalTypes.length > 1) {
                        _medicalTypes.remove(m.key);
                      }
                    }),
                    selectedColor: accent,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Yuborish tugmasi
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      (_submitting || _uploadingDoc || _uploadingPassport)
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text('Ariza yuborish'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hujjat yuklash kartochkasi
class _DocumentUploadTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final File? file;
  final bool isUploading;
  final bool isUploaded;
  final VoidCallback onTap;

  const _DocumentUploadTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.isUploading,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2563EB);
    final Color borderColor = isUploaded
        ? Colors.green
        : isUploading
        ? accent.withOpacity(0.5)
        : Colors.grey.shade300;
    final Color bgColor = isUploaded
        ? Colors.green.withOpacity(0.06)
        : Colors.grey.shade50;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isUploaded ? 1.5 : 1),
        ),
        child: Row(
          children: [
            // Preview yoki icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file != null
                  ? Image.file(file!, width: 52, height: 52, fit: BoxFit.cover)
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isUploaded
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isUploaded ? Icons.check_circle : icon,
                        color: isUploaded ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isUploaded
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded ? '✓ Muvaffaqiyatli yuklandi' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUploaded ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUploading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Icon(
                isUploaded ? Icons.edit_outlined : Icons.upload_outlined,
                color: isUploaded ? Colors.green : accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
