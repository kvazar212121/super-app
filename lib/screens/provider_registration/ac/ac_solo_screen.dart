import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/ac_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

/// Konditsioner — faqat yakka usta.
class AcSoloScreen extends StatefulWidget {
  const AcSoloScreen({super.key});

  @override
  State<AcSoloScreen> createState() => _AcSoloScreenState();
}

class _AcSoloScreenState extends State<AcSoloScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
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

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (user?['phone'] as String? ?? '');

    try {
      await AcPortalService().registerSolo(
        name: name,
        phone: phone,
        serviceArea: area,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderSuccessScreen(
            providerName: name,
            categoryName: 'Konditsioner',
            categoryId: 'ac',
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        showFriendlyErrorSnack(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Konditsioner sifatida'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konditsioner o\'rnatish, profilaktika va gaz quyish xizmatini uyga borib ko\'rsatasiz.'.tr,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Ismingiz yoki xizmat nomi'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Xizmat ko\'rsatadigan hudud'.tr,
                  hintText: 'Masalan: Toshkent, Yunusobod, Sergeli'.tr,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Ro\'yxatdan o\'tish'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
