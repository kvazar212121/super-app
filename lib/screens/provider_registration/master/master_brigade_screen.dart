import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/master_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';

class MasterBrigadeScreen extends StatefulWidget {
  const MasterBrigadeScreen({super.key});

  @override
  State<MasterBrigadeScreen> createState() => _MasterBrigadeScreenState();
}

class _MasterBrigadeScreenState extends State<MasterBrigadeScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _teamSizeCtrl = TextEditingController(text: '3');
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
        const SnackBar(content: Text('Brigada nomi, manzil va hududni kiriting')),
      );
      return;
    }
    if (teamSize < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brigada kamida 2 kishidan iborat bo\'lishi kerak')),
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
      await MasterPortalService().registerBrigade(
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
            categoryName: 'Ustalar brigadasi',
            categoryId: 'builder',
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ustalar brigadasi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brigada sifatida katta ta\'mirlash, mebel yigish va montaj buyurtmalarini qabul qilasiz.',
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Brigada / kompaniya nomi'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ofis manzili',
                  hintText: 'Masalan: Yunusobod, 12-kvartal',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Xizmat ko\'rsatadigan hudud',
                  hintText: 'Masalan: Butun Toshkent',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teamSizeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Brigada a\'zolari soni',
                  hintText: 'Masalan: 3',
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
