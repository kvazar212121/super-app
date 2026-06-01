import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/nanny_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/nanny_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import 'nanny_pending_screen.dart';
import '../../../widgets/document_upload_tile.dart';

/// Enaga — hujjatlar va admin tasdiqlash bilan ro'yxatdan o'tish.
class NannyRegistrationScreen extends StatefulWidget {
  const NannyRegistrationScreen({super.key});

  @override
  State<NannyRegistrationScreen> createState() => _NannyRegistrationScreenState();
}

class _NannyRegistrationScreenState extends State<NannyRegistrationScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _submitting = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController(text: '3');

  final Set<String> _ageGroups = {'1-3', '3-7'};
  final Set<String> _languages = {'uz'};
  final Set<String> _serviceTypes = {'hourly', 'half_day', 'full_day'};

  String? _medicalUrl;
  String? _idUrl;
  String? _criminalUrl;

  static const _accent = Color(0xFFF472B6);
  static const _ageOptions = ['0-1', '1-3', '3-7', '7-12'];
  static const _langOptions = ['uz', 'ru', 'en'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty || _areaCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ism va hududni kiriting')),
        );
        return;
      }
    }
    if (_step == 1) {
      if (_medicalUrl == null || _idUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tibbiy spravka va pasport rasmini yuklang'),
          ),
        );
        return;
      }
    }
    if (_step < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (user?['phone'] as String? ?? '');

    try {
      await NannyPortalService().register(
        name: _nameCtrl.text.trim(),
        phone: phone,
        serviceArea: _areaCtrl.text.trim(),
        experienceYears: int.tryParse(_experienceCtrl.text.trim()) ?? 0,
        ageGroups: _ageGroups.toList(),
        languages: _languages.toList(),
        serviceTypes: _serviceTypes.toList(),
        documents: {
          'medical_cert': _medicalUrl != null,
          'id_verified': _idUrl != null,
          'criminal_record': _criminalUrl != null,
          if (_medicalUrl != null) 'medical_cert_url': _medicalUrl,
          if (_idUrl != null) 'id_url': _idUrl,
          if (_criminalUrl != null) 'criminal_record_url': _criminalUrl,
        },
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => NannyPendingScreen(providerName: _nameCtrl.text.trim()),
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
        appBar: AppBar(
          title: Text('Enaga — ${_step + 1}/3'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / 3),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicStep(),
                  _buildDocumentsStep(),
                  _buildServicesStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _next,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == 2 ? 'So\'rov yuborish' : 'Keyingi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asosiy ma\'lumotlar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Bolalar bilan ishlash tajribangiz va xizmat hududingiz.',
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Ismingiz'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Telefon'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _areaCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Xizmat hududi',
              hintText: 'Masalan: Toshkent, Yunusobod',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _experienceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tajriba (yil)'),
          ),
          const SizedBox(height: 20),
          const Text('Qaysi yoshdagi bolalar bilan ishlaysiz?', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _ageOptions.map((a) {
              final selected = _ageGroups.contains(a);
              return FilterChip(
                label: Text('$a yosh'),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _ageGroups.add(a);
                    } else {
                      _ageGroups.remove(a);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Tillaringiz', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _langOptions.map((l) {
              final selected = _languages.contains(l);
              return FilterChip(
                label: Text(NannyService.languageLabel(l)),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _languages.add(l);
                    } else if (_languages.length > 1) {
                      _languages.remove(l);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ishonch va xavfsizlik',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hujjatlaringiz administrator tomonidan tekshiriladi. Tasdiqlanguncha profilingiz mijozlarga ko\'rinmaydi.',
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 24),
          DocumentUploadTile(
            label: 'Tibbiy ma\'lumotnoma (spravka)',
            subtitle: 'Majburiy — bolalar bilan ishlash uchun',
            url: _medicalUrl,
            accent: _accent,
            onUrlChanged: (url) => setState(() => _medicalUrl = url),
          ),
          DocumentUploadTile(
            label: 'Pasport / ID',
            subtitle: 'Majburiy',
            url: _idUrl,
            accent: _accent,
            onUrlChanged: (url) => setState(() => _idUrl = url),
          ),
          DocumentUploadTile(
            label: 'Sudlanganlik haqida ma\'lumotnoma',
            subtitle: 'Ixtiyoriy, lekin tavsiya etiladi',
            url: _criminalUrl,
            accent: _accent,
            onUrlChanged: (url) => setState(() => _criminalUrl = url),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Hujjatlar administrator tomonidan tekshiriladi. Tasdiqlanguncha profilingiz mijozlarga ko\'rinmaydi.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xizmat turlari',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Qaysi formatda ishlayotganingizni tanlang. Narxlarni panelda keyinroq sozlaysiz.',
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 16),
          ...NannyServiceType.values.map((t) {
            final selected = _serviceTypes.contains(t.key);
            return CheckboxListTile(
              title: Text(t.label),
              value: selected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _serviceTypes.add(t.key);
                  } else if (_serviceTypes.length > 1) {
                    _serviceTypes.remove(t.key);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
