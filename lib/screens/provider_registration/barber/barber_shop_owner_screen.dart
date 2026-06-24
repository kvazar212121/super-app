import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../services/barber_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';
import '../../location_picker_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/hub_data_service.dart';

class BarberShopOwnerScreen extends StatefulWidget {
  final int? categoryDbId;

  const BarberShopOwnerScreen({super.key, this.categoryDbId});

  @override
  State<BarberShopOwnerScreen> createState() => _BarberShopOwnerScreenState();
}

class _BarberShopOwnerScreenState extends State<BarberShopOwnerScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '41.2995');
  final _lngCtrl = TextEditingController(text: '69.2401');
  bool _alsoBarber = true;
  bool _submitting = false;
  String? _selectedSubCategory;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xona nomi va manzilni kiriting')),
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
      await BarberPortalService().registerShopOwner(
        name: name,
        address: address,
        phone: phone,
        lat: double.tryParse(_latCtrl.text.trim()) ?? 41.2995,
        lng: double.tryParse(_lngCtrl.text.trim()) ?? 69.2401,
        alsoWorksAsBarber: _alsoBarber,
        hours: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
        subCategory: _selectedSubCategory,
      );
      HubDataService().clearCache();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderSuccessScreen(
            providerName: name,
            categoryName: 'Sartarosh xona egasi',
            categoryId: 'barber',
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
        appBar: AppBar(title: const Text('Sartarosh xona egasi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xona ma\'lumotlari',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sartaroshxona nomi',
                  hintText: 'Masalan: Style Barbershop',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Manzil (to\'liq)',
                        hintText: 'Tuman, ko\'cha, uy raqami',
                      ),
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
                              initialLat: double.tryParse(_latCtrl.text) ?? 41.2995,
                              initialLng: double.tryParse(_lngCtrl.text) ?? 69.2401,
                            ),
                          ),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _latCtrl.text = result['lat'].toString();
                            _lngCtrl.text = result['lng'].toString();
                            if (result['address'] != 'Noma\'lum manzil' && result['address'] != 'Manzilni aniqlab bo\'lmadi') {
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
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(labelText: 'Ish vaqti (ixtiyoriy)'),
              ),
              const SizedBox(height: 16),
              if (ProviderCategoryConfig.barber.subCategories != null &&
                  ProviderCategoryConfig.barber.subCategories!.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Kategoriya tanlang'),
                  value: _selectedSubCategory,
                  items: ProviderCategoryConfig.barber.subCategories!
                      .map((sc) => DropdownMenuItem(value: sc, child: Text(sc)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSubCategory = val),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Men ham sartaroshman'),
                subtitle: const Text('O\'zingiz ham kesim qilasizmi yoki faqat egasi?'),
                value: _alsoBarber,
                onChanged: (v) => setState(() => _alsoBarber = v),
              ),
              const SizedBox(height: 24),
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
