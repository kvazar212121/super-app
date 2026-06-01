import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/salon_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';

class SalonMobileScreen extends StatefulWidget {
  const SalonMobileScreen({super.key});

  @override
  State<SalonMobileScreen> createState() => _SalonMobileScreenState();
}

class _SalonMobileScreenState extends State<SalonMobileScreen> {
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
        const SnackBar(content: Text('Ism va xizmat hududini kiriting')),
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
      await SalonPortalService().registerMobile(name: name, phone: phone, serviceArea: area);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderSuccessScreen(
            providerName: name,
            categoryName: 'Mobil kosmetolog',
            categoryId: 'salon',
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Mobil kosmetolog')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mijoz manziliga borib kosmetik xizmat ko\'rsatasiz — fen, manikyur, makiyaj.',
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Ismingiz')),
              const SizedBox(height: 16),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telefon')),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Xizmat ko\'rsatadigan hudud',
                  hintText: 'Masalan: Toshkent, Yunusobod',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Ro\'yxatdan o\'tish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
