import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../models/disinfection_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/disinfection_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Dezinfeksiya xizmati — ro'yxatdan o'tish.
class DisinfectionRegistrationScreen extends StatefulWidget {
  const DisinfectionRegistrationScreen({super.key});

  @override
  State<DisinfectionRegistrationScreen> createState() =>
      _DisinfectionRegistrationScreenState();
}

class _DisinfectionRegistrationScreenState
    extends State<DisinfectionRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  bool _submitting = false;
  bool _isCertified = false;

  final Set<String> _areaTypes = {'apartment', 'office', 'vehicle'};

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
        SnackBar(content: Text('Xizmat nomi va hududni kiriting'.tr)),
      );
      return;
    }
    if (_areaTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamida bitta obyekt turini tanlang'.tr)),
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
      await DisinfectionPortalService().register(
        name: name,
        phone: phone,
        serviceArea: area,
        areaTypes: _areaTypes.toList(),
        isCertified: _isCertified,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProviderDashboardScreen(
            config: ProviderCategoryConfig.disinfection,
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
    const accent = Color(0xFF14B8A6);
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Dezinfeksiya xizmati'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uy, ofis, mashina va maktablarni professional dezinfeksiya qilasiz. Ro\'yxatdan o\'tishi bilan darhol ishlashni boshlashingiz mumkin.',
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Xizmat yoki kompaniya nomi'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                decoration: InputDecoration(
                  labelText: 'Xizmat ko\'rsatish hududi',
                  hintText: 'Masalan: Toshkent, Chilonzor'.tr,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Qaysi obyektlarga xizmat?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AreaType.values.map((t) {
                  final selected = _areaTypes.contains(t.key);
                  return FilterChip(
                    label: Text(t.label.tr),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _areaTypes.add(t.key);
                      } else {
                        _areaTypes.remove(t.key);
                      }
                    }),
                    selectedColor: accent,
                    checkmarkColor: accent,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isCertified,
                onChanged: (v) => setState(() => _isCertified = v),
                title: Text('Sertifikatlangan xizmat'.tr),
                subtitle: Text(
                  'Sanitariya yoki dezinfeksiya sertifikati bor'.tr,
                ),
                activeThumbColor: accent,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Yuborish'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
