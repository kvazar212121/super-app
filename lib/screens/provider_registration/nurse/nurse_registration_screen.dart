import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/nurse_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/nurse_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import 'nurse_pending_screen.dart';

class NurseRegistrationScreen extends StatefulWidget {
  const NurseRegistrationScreen({super.key});

  @override
  State<NurseRegistrationScreen> createState() => _NurseRegistrationScreenState();
}

class _NurseRegistrationScreenState extends State<NurseRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _qualCtrl = TextEditingController(text: 'Litsenziyalangan hamshira');
  bool _submitting = false;
  final Set<String> _medicalTypes = {'injection', 'blood_test', 'drip'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _qualCtrl.dispose();
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
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NursePendingScreen(providerName: name)),
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
    const accent = Color(0xFFEF4444);
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Hamshira xizmati')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Faqat uyga chiqish — mijoz manziliga borasiz. Administrator tasdiqlagach ishlay boshlaysiz.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Ism yoki xizmat nomi')),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telefon'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: _areaCtrl, decoration: const InputDecoration(labelText: 'Xizmat hududi')),
              const SizedBox(height: 12),
              TextField(controller: _qualCtrl, decoration: const InputDecoration(labelText: 'Malaka / litsenziya')),
              const SizedBox(height: 16),
              const Text('Tibbiy xizmatlar', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: MedicalService.values.take(6).map((m) {
                  final selected = _medicalTypes.contains(m.key);
                  return FilterChip(
                    label: Text(m.label),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _medicalTypes.add(m.key);
                      } else if (_medicalTypes.length > 1) {
                        _medicalTypes.remove(m.key);
                      }
                    }),
                    selectedColor: accent.withValues(alpha: 0.2),
                  );
                }).toList(),
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
