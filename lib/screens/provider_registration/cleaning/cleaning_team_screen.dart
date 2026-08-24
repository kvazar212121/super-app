import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/cleaning_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

class CleaningTeamScreen extends StatefulWidget {
  const CleaningTeamScreen({super.key});

  @override
  State<CleaningTeamScreen> createState() => _CleaningTeamScreenState();
}

class _CleaningTeamScreenState extends State<CleaningTeamScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _teamSizeCtrl = TextEditingController(text: '4');
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _teamSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    final teamSize = int.tryParse(_teamSizeCtrl.text.trim()) ?? 0;

    if (name.isEmpty || address.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kompaniya nomi, manzil va hududni kiriting'.tr),
        ),
      );
      return;
    }
    if (teamSize < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jamoa kamida 2 kishidan iborat bo\'lishi kerak'.tr),
        ),
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
      await CleaningPortalService().registerTeam(
        name: name,
        phone: phone,
        address: address,
        serviceArea: area,
        teamSize: teamSize,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderSuccessScreen(
            providerName: name,
            categoryName: 'Tozalash jamoasi',
            categoryId: 'cleaner',
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
        appBar: AppBar(title: Text('Tozalash jamoasi'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jamoa sifatida katta kvartira, ofis va general tozalash buyurtmalarini qabul qilasiz.'.tr,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Kompaniya / jamoa nomi'.tr,
                ),
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
                  labelText: 'Ofis manzili'.tr,
                  hintText: 'Masalan: Chilonzor, 9-kvartal'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Xizmat ko\'rsatadigan hudud'.tr,
                  hintText: 'Masalan: Butun Toshkent'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teamSizeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Jamoa a\'zolari soni'.tr,
                  hintText: 'Masalan: 4'.tr,
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
