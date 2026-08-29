import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/tutor_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';
import '../../../theme/lux_tokens.dart';

class TutorCenterScreen extends StatefulWidget {
  const TutorCenterScreen({super.key});

  @override
  State<TutorCenterScreen> createState() => _TutorCenterScreenState();
}

class _TutorCenterScreenState extends State<TutorCenterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _submitting = false;

  final Set<String> _courses = {'Matematika', 'Ingliz tili'};

  static const _courseOptions = [
    'Matematika',
    'Ingliz tili',
    'Fizika',
    'Programmalash',
    'Grafik dizayn',
    'IELTS',
    'Test tayyorlov',
  ];

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
        SnackBar(content: Text('Markaz nomi va manzilni kiriting'.tr)),
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
      await TutorPortalService().registerCenter(
        name: name,
        phone: phone,
        address: address,
        courses: _courses.toList(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProviderDashboardScreen(
            config: ProviderCategoryConfig.tutor,
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
        appBar: AppBar(title: Text('O\'quv markazi'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Markaz manzili va kurslar — ro\'yxatdan o\'tishi bilan mijozlar vaqt bron qilishni boshlaydi.'.tr,
                style: TextStyle(color: LuxTokens.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Markaz nomi'.tr),
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
                  labelText: 'To\'liq manzil'.tr,
                  hintText: 'Ko\'cha, kvartal, orientir'.tr,
                ),
              ),
              const SizedBox(height: 20),
              Text('Kurslar / yo\'nalishlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _courseOptions.map((c) {
                  return FilterChip(
                    label: Text(c),
                    selected: _courses.contains(c),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _courses.add(c);
                        } else if (_courses.length > 1) {
                          _courses.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
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
