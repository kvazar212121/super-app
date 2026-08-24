import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auto_help_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

/// Ustaxona ro'yxatdan o'tish.
class AutoWorkshopScreen extends StatefulWidget {
  const AutoWorkshopScreen({super.key});

  @override
  State<AutoWorkshopScreen> createState() => _AutoWorkshopScreenState();
}

class _AutoWorkshopScreenState extends State<AutoWorkshopScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _specOptions = [
    'Motor',
    'Xodovoy',
    'Elektronika',
    'Tuning',
    'Shinopompa',
    'Konditsioner',
  ];
  final Set<String> _specs = {'Motor', 'Xodovoy'};
  bool _submitting = false;

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
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nom va manzilni kiriting'.tr)));
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (user?['phone'] as String? ?? '');

    try {
      await AutoHelpPortalService().registerWorkshop(
        name: name,
        phone: phone,
        address: address,
        specializations: _specs.toList(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderSuccessScreen(
            providerName: name,
            categoryName: 'Ustaxona',
            categoryId: 'auto',
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
        appBar: AppBar(title: Text('Ustaxona sifatida'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doimiy servis markazi — mijozlar ustaxonangizga vaqt bron qiladi.'.tr,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Ustaxona nomi'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ustaxona manzili'.tr,
                  hintText: 'Masalan: Yunusobod, 19-kvartal'.tr,
                ),
              ),
              const SizedBox(height: 16),
              Text('Mutaxassislik'.tr,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _specOptions.map((s) {
                  final selected = _specs.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _specs.add(s);
                        } else if (_specs.length > 1) {
                          _specs.remove(s);
                        }
                      });
                    },
                  );
                }).toList(),
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
