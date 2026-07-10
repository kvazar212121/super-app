import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/provider_category_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/provider_portal_service.dart';
import '../../utils/phone_utils.dart';
import '../provider_side/provider_theme.dart';
import 'provider_success_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class ProviderDataEntryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final int? categoryDbId;

  const ProviderDataEntryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryDbId,
  });

  @override
  State<ProviderDataEntryScreen> createState() =>
      _ProviderDataEntryScreenState();
}

class _ProviderDataEntryScreenState extends State<ProviderDataEntryScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  bool _submitting = false;
  String? _selectedSubCategory;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    _priceCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitProvider() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : '${user?['name'] ?? ''} ${user?['surname'] ?? ''}'.trim();
    final address = _addressCtrl.text.trim().isNotEmpty
        ? _addressCtrl.text.trim()
        : 'Toshkent shahri';
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (user?['phone'] as String? ?? '');

    int? categoryId = widget.categoryDbId;
    final regConfig = ProviderCategoryConfig.byRegistrationId(
      widget.categoryId,
    );
    if (categoryId == null) {
      try {
        final cats = await ApiService().getCategories();
        final lookupKey = regConfig?.categoryKey ?? widget.categoryId;
        for (final c in cats) {
          if (c['key'] == lookupKey) {
            categoryId = c['id'] as int?;
            break;
          }
        }
      } catch (_) {}
    }

    if (categoryId != null && auth.isAuthenticated) {
      try {
        await ProviderPortalService().register(
          categoryId: categoryId,
          name: name.isNotEmpty ? name : widget.categoryName,
          address: address,
          phone: phone,
          metadata: {
            if (_hoursCtrl.text.trim().isNotEmpty)
              'hours': _hoursCtrl.text.trim(),
            if (_priceCtrl.text.trim().isNotEmpty)
              'price_note': _priceCtrl.text.trim(),
            if (_extraCtrl.text.trim().isNotEmpty)
              'extra': _extraCtrl.text.trim(),
            if (_selectedSubCategory != null)
              'sub_category': _selectedSubCategory,
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
        }
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderSuccessScreen(
          providerName: name,
          categoryName: widget.categoryName,
          categoryId: widget.categoryId,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                '${widget.categoryName} sifatida ro\'yxatdan o\'tish',
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Malumotlaringizni to\'ldiring',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ma\'lumotlar serverga yuboriladi. Admin tasdiqlagach ko\'rinadi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (ProviderCategoryConfig.byRegistrationId(
                            widget.categoryId,
                          )?.subCategories !=
                          null &&
                      ProviderCategoryConfig.byRegistrationId(
                        widget.categoryId,
                      )!.subCategories!.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kategoriya tanlang'.tr,
                      ),
                      value: _selectedSubCategory,
                      items:
                          ProviderCategoryConfig.byRegistrationId(
                                widget.categoryId,
                              )!.subCategories!
                              .map(
                                (sc) => DropdownMenuItem(
                                  value: sc,
                                  child: Text(sc.tr),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSubCategory = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nomi / Salon nomi'.tr,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(labelText: 'Manzil'.tr),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(labelText: 'Telefon'.tr),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hoursCtrl,
                    decoration: InputDecoration(labelText: 'Ish vaqti'.tr),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Narxlar (ixtiyoriy)'.tr,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _extraCtrl,
                    decoration: InputDecoration(
                      labelText: 'Qo\'shimcha ma\'lumot',
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submitProvider,
                      child: _submitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Yuborish'.tr),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
