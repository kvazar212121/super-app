import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/massage_hijoma.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../services/massage_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import 'massage_pending_screen.dart';
import '../../location_picker_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

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
  final _latCtrl = TextEditingController(text: '41.2995');
  final _lngCtrl = TextEditingController(text: '69.2401');
  final _capacityCtrl = TextEditingController(text: '1');
  bool _submitting = false;
  String _role = 'solo';
  String _gender = 'both';
  String? _selectedSubCategory;

  final Set<String> _visitModes = {'at_center'};
  final Set<String> _serviceTypes = {'classic_massage', 'hijoma'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    if (name.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ism va hududni kiriting'.tr)));
      return;
    }
    if (_visitModes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamida bitta qabul usulini tanlang'.tr)),
      );
      return;
    }
    if (_role == 'salon' && _addressCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Salon manzilini kiriting'.tr)));
      return;
    }

    int capacity = 1;
    if (_role == 'salon') {
      capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 1;
      if (capacity < 1) capacity = 1;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final phoneInput = _phoneCtrl.text.trim();
    final userPhone = user?['phone'] as String? ?? '';
    final phone = phoneInput.isNotEmpty
        ? normalizeUzPhone(phoneInput.replaceAll(RegExp(r'\D'), ''))
        : userPhone;

    if (phone.isEmpty || phone.replaceAll(RegExp(r'\D'), '').length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yaroqli telefon raqamini kiriting (kamida 9 ta raqam)'.tr,
          ),
        ),
      );
      return;
    }

    try {
      await MassagePortalService().register(
        name: name,
        phone: phone,
        serviceArea: area,
        address: _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
        lat: double.tryParse(_latCtrl.text.trim()) ?? 41.2995,
        lng: double.tryParse(_lngCtrl.text.trim()) ?? 69.2401,
        massageRole: _role,
        visitModes: _visitModes.toList(),
        serviceTypes: _serviceTypes.toList(),
        gender: _gender,
        subCategory: _selectedSubCategory,
        concurrentCapacity: capacity,
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
        showFriendlyErrorSnack(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2563EB);
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Massaj va Hijoma'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mijozlarni o\'z markazingizda yoki salonda qabul qilasiz.'.tr,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'solo',
                    label: Text('Yakka mutaxassis'.tr),
                  ),
                  ButtonSegment(
                    value: 'salon',
                    label: Text('Salon / markaz'.tr),
                  ),
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
                decoration: InputDecoration(labelText: 'Telefon'.tr),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              if (ProviderCategoryConfig.massage.subCategories != null &&
                  ProviderCategoryConfig.massage.subCategories!.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Kategoriya tanlang'.tr,
                  ),
                  initialValue: _selectedSubCategory,
                  items: ProviderCategoryConfig.massage.subCategories!
                      .map((sc) => DropdownMenuItem(value: sc, child: Text(sc.tr)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedSubCategory = val),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _areaCtrl,
                decoration: InputDecoration(
                  labelText: 'Xizmat hududi'.tr,
                  hintText: 'Masalan: Toshkent, Chilonzor'.tr,
                ),
              ),
              if (_role == 'salon') ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Salon manzili'.tr,
                          hintText: 'Ko\'cha, uy raqami'.tr,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: IconButton.filledTonal(
                        icon: const Icon(LucideIcons.map),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLat:
                                    double.tryParse(_latCtrl.text) ?? 41.2995,
                                initialLng:
                                    double.tryParse(_lngCtrl.text) ?? 69.2401,
                              ),
                            ),
                          );
                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setState(() {
                              _latCtrl.text = result['lat'].toString();
                              _lngCtrl.text = result['lng'].toString();
                              if (result['address'] != 'Noma\'lum manzil' &&
                                  result['address'] !=
                                      'Manzilni aniqlab bo\'lmadi') {
                                _addressCtrl.text = result['address'];
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _capacityCtrl,
                  decoration: InputDecoration(
                    labelText: 'Bir vaqtda nechta mijoz qabul qila olasiz?'.tr,
                    hintText: 'Masalan: 3'.tr,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 20),

              Text('Xizmatlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      ServiceType.classicMassage,
                      ServiceType.hijoma,
                      ServiceType.sportMassage,
                      ServiceType.thaiMassage,
                    ].map((t) {
                      final key = t.name;
                      final selected = _serviceTypes.contains(key);
                      return FilterChip(
                        label: Text(t.label.tr),
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
              Text('Mijozlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'both', label: Text('Ikkalasi'.tr)),
                  ButtonSegment(value: 'male', label: Text('Erkak'.tr)),
                  ButtonSegment(value: 'female', label: Text('Ayol'.tr)),
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
