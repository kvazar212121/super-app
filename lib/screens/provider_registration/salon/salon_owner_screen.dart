import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/salon_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../provider_success_screen.dart';
import '../../location_picker_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/hub_data_service.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

class SalonOwnerScreen extends StatefulWidget {
  const SalonOwnerScreen({super.key});

  @override
  State<SalonOwnerScreen> createState() => _SalonOwnerScreenState();
}

class _SalonOwnerScreenState extends State<SalonOwnerScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '41.2995');
  final _lngCtrl = TextEditingController(text: '69.2401');
  bool _alsoStylist = true;
  bool _submitting = false;

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
        SnackBar(content: Text('Salon nomi va manzilni kiriting'.tr)),
      );
      return;
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
      await SalonPortalService().registerOwner(
        name: name,
        address: address,
        phone: phone,
        lat: double.tryParse(_latCtrl.text.trim()) ?? 41.2995,
        lng: double.tryParse(_lngCtrl.text.trim()) ?? 69.2401,
        alsoWorksAsStylist: _alsoStylist,
        hours: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
      );
      HubDataService().clearCache();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderSuccessScreen(
            providerName: name,
            categoryName: 'Salon egasi',
            categoryId: 'salon',
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
        appBar: AppBar(title: Text('Salon egasi'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Salon nomi'.tr,
                  hintText: 'Masalan: Belleza Salon'.tr,
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
                      decoration: InputDecoration(
                        labelText: 'Manzil (to\'liq)'.tr,
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
                              initialLat:
                                  double.tryParse(_latCtrl.text) ?? 41.2995,
                              initialLng:
                                  double.tryParse(_lngCtrl.text) ?? 69.2401,
                            ),
                          ),
                        );
                        if (result != null && result is Map<String, dynamic>) {
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
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hoursCtrl,
                decoration: InputDecoration(
                  labelText: 'Ish vaqti (ixtiyoriy)'.tr,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Men ham mutaxassisman'.tr),
                subtitle: Text('O\'zingiz ham xizmat ko\'rsatasizmi yoki faqat egasi?'.tr,
                ),
                value: _alsoStylist,
                onChanged: (v) => setState(() => _alsoStylist = v),
              ),
              const SizedBox(height: 24),
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
