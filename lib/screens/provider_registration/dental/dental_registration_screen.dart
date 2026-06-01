import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/dental_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import 'dental_pending_screen.dart';

class DentalRegistrationScreen extends StatefulWidget {
  const DentalRegistrationScreen({super.key});

  @override
  State<DentalRegistrationScreen> createState() => _DentalRegistrationScreenState();
}

class _DentalRegistrationScreenState extends State<DentalRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
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
    if (name.isEmpty || address.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klinika nomi va manzilni kiriting')),
      );
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (auth.user?['phone'] as String? ?? '');
    try {
      await DentalPortalService().register(name: name, phone: phone, address: address);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => DentalPendingScreen(providerName: name)),
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
    const accent = Color(0xFF0EA5E9);
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Stomatologiya klinikasi')),
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
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Klinika nomi')),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telefon'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Klinika manzili'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Yuborish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
