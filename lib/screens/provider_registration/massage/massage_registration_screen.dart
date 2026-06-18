import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/massage_hijoma.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/massage_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import 'massage_pending_screen.dart';

/// Massaj va hijoma — uyga chiqish va/yoki salonda.
class MassageRegistrationScreen extends StatefulWidget {
  const MassageRegistrationScreen({super.key});

  @override
  State<MassageRegistrationScreen> createState() =>
      _MassageRegistrationScreenState();
}

class _MassageRegistrationScreenState extends State<MassageRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _submitting = false;
  String _role = 'solo';
  String _gender = 'both';

  final Set<String> _visitModes = {'home_visit', 'at_center'};
  final Set<String> _serviceTypes = {'classic_massage', 'hijoma'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    if (name.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ism va hududni kiriting')),
      );
      return;
    }
    if (_visitModes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida bitta qabul usulini tanlang')),
      );
      return;
    }
    if (_role == 'salon' && _addressCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon manzilini kiriting')),
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
      await MassagePortalService().register(
        name: name,
        phone: phone,
        serviceArea: area,
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        massageRole: _role,
        visitModes: _visitModes.toList(),
        serviceTypes: _serviceTypes.toList(),
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MassagePendingScreen(providerName: name),
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
    const accent = Color(0xFFE11D48);
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Massaj va Hijoma')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mijozlarni uyga chaqirasiz yoki salonga qabul qilasiz — ikkalasini ham belgilashingiz mumkin.',
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'solo', label: Text('Yakka mutaxassis')),
                  ButtonSegment(value: 'salon', label: Text('Salon / markaz')),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() {
                  _role = s.first;
                  if (_role == 'salon' && !_visitModes.contains('at_center')) {
                    _visitModes.add('at_center');
                  }
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: _role == 'salon' ? 'Salon nomi' : 'Ismingiz',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Xizmat hududi',
                  hintText: 'Masalan: Toshkent, Chilonzor',
                ),
              ),
              if (_role == 'salon') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Salon manzili',
                    hintText: 'Ko\'cha, uy raqami',
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 20),
              const Text('Qabul usuli', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MassageVisitMode.values.map((m) {
                  final selected = _visitModes.contains(m.key);
                  return FilterChip(
                    label: Text(m.label),
                    avatar: Icon(m.icon, size: 18),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _visitModes.add(m.key);
                      } else if (_visitModes.length > 1) {
                        _visitModes.remove(m.key);
                      }
                    }),
                    selectedColor: accent,
                    checkmarkColor: accent,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Xizmatlar', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ServiceType.classicMassage,
                  ServiceType.hijoma,
                  ServiceType.sportMassage,
                  ServiceType.thaiMassage,
                ].map((t) {
                  final key = t.name;
                  final selected = _serviceTypes.contains(key);
                  return FilterChip(
                    label: Text(t.label),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _serviceTypes.add(key);
                      } else if (_serviceTypes.length > 1) {
                        _serviceTypes.remove(key);
                      }
                    }),
                    selectedColor: accent,
                    checkmarkColor: accent,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Mijozlar', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'both', label: Text('Ikkalasi')),
                  ButtonSegment(value: 'male', label: Text('Erkak')),
                  ButtonSegment(value: 'female', label: Text('Ayol')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
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
                      : const Text('Yuborish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
