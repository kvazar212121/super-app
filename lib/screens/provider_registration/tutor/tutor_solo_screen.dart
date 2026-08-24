import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../models/tutor_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/tutor_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

class TutorSoloScreen extends StatefulWidget {
  const TutorSoloScreen({super.key});

  @override
  State<TutorSoloScreen> createState() => _TutorSoloScreenState();
}

class _TutorSoloScreenState extends State<TutorSoloScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController(text: '3');
  bool _submitting = false;

  final Set<String> _subjects = {'Matematika', 'Ingliz tili'};
  final Set<String> _lessonModes = {'online', 'home_visit'};

  static const _subjectOptions = [
    'Matematika',
    'Ingliz tili',
    'Fizika',
    'Rus tili',
    'Kimyo',
    'Biologiya',
    'Test tayyorlov',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _experienceCtrl.dispose();
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
    if (_subjects.isEmpty || _lessonModes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamida bitta fan va dars formatini tanlang'.tr),
        ),
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
      await TutorPortalService().registerSolo(
        name: name,
        phone: phone,
        serviceArea: area,
        subjects: _subjects.toList(),
        lessonModes: _lessonModes.toList(),
        experienceYears: int.tryParse(_experienceCtrl.text.trim()) ?? 0,
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
        appBar: AppBar(title: Text('Yakka repetitor'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Onlayn yoki uyga kelib dars berasiz — band kattalar va o\'quvchilar sizni topadi.'.tr,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Ismingiz'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _areaCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Xizmat hududi'.tr,
                  hintText: 'Masalan: Toshkent, Yunusobod'.tr,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _experienceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Tajriba (yil)'.tr),
              ),
              const SizedBox(height: 20),
              Text('Fanlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjectOptions.map((s) {
                  return FilterChip(
                    label: Text(s),
                    selected: _subjects.contains(s),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _subjects.add(s);
                        } else if (_subjects.length > 1) {
                          _subjects.remove(s);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Dars formati'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...LessonMode.values.where((m) => m != LessonMode.atCenter).map((
                m,
              ) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.label.tr),
                  value: _lessonModes.contains(m.key),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _lessonModes.add(m.key);
                      } else if (_lessonModes.length > 1) {
                        _lessonModes.remove(m.key);
                      }
                    });
                  },
                );
              }),
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
