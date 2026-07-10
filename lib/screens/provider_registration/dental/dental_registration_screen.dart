import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/dental_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import '../../map_address_picker_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class DentalRegistrationScreen extends StatefulWidget {
  const DentalRegistrationScreen({super.key});

  @override
  State<DentalRegistrationScreen> createState() =>
      _DentalRegistrationScreenState();
}

class _DentalRegistrationScreenState extends State<DentalRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _submitting = false;

  static const accent = Color(0xFF0EA5E9);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (name.isEmpty || address.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klinika nomi va manzilni kiriting'.tr)),
      );
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (auth.user?['phone'] as String? ?? '');
    try {
      await DentalPortalService().register(
        name: name,
        phone: phone,
        address: address,
      );
      if (!mounted) return;
      // Stomatologiya darhol faol — admin tasdiqlovchi ekransiz to'g'ridan-to'g'ri dashboardga
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProviderDashboardScreen(
            config: ProviderCategoryConfig.dental,
          ),
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
        appBar: AppBar(title: Text('Stomatologiya klinikasi'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mijozlar klinikangizga kelib vaqt bron qiladi. Qabul vaqtlarini panelda sozlaysiz.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Klinika nomi'.tr),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              // Manzil + xarita tugmasi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Klinika manzili'.tr,
                        hintText: 'Ko\'cha, bino, mo\'ljal...',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.map, color: accent),
                      tooltip: 'Xaritadan tanlash'.tr,
                      onPressed: () async {
                        final picked = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapAddressPickerScreen(),
                          ),
                        );
                        if (picked != null && picked.isNotEmpty) {
                          setState(() => _addressCtrl.text = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
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
                      : const Text(
                          'Yuborish',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
