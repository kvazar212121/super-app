import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/provider_category_config.dart';
import '../../../models/event_planning.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/event_portal_service.dart';
import '../../../utils/phone_utils.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../widgets/friendly_error.dart';

class EventRegistrationScreen extends StatefulWidget {
  const EventRegistrationScreen({super.key});

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _teamCtrl = TextEditingController(text: '5');
  bool _submitting = false;

  final Set<String> _organizerTypes = {
    'stage_setup',
    'sound_light',
    'village_events',
    'full_organization',
  };
  final Set<String> _eventTypes = {'wedding', 'birthday', 'corporate'};
  final Set<String> _venueTypes = {
    'village_yard',
    'open_field',
    'garden',
    'hall',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _teamCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    if (name.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guruh nomi va xizmat hududini kiriting'.tr)),
      );
      return;
    }
    if (_organizerTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamida bitta xizmat turini tanlang'.tr)),
      );
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final phone = _phoneCtrl.text.trim().isNotEmpty
        ? normalizeUzPhone(_phoneCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : (auth.user?['phone'] as String? ?? '');
    final teamSize = int.tryParse(_teamCtrl.text.trim()) ?? 3;

    try {
      await EventPortalService().register(
        name: name,
        phone: phone,
        serviceArea: area,
        teamSize: teamSize,
        organizerTypes: _organizerTypes.toList(),
        eventTypes: _eventTypes.toList(),
        venueTypes: _venueTypes.toList(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProviderDashboardScreen(
            config: ProviderCategoryConfig.events,
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
    const accent = Color(0xFFB8921F);
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Tadbir guruhi'.tr)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qishloq va shaharda sahna, ovoz, dekoratsiya va to\'liq tadbir tashkiloti. Ro\'yxatdan o\'tishi bilan darhol buyurtmalar qabul qila boshlaysiz.'.tr,
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Guruh / kompaniya nomi'.tr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Telefon'.tr),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaCtrl,
                decoration: InputDecoration(
                  labelText: 'Xizmat hududi (viloyatlar, tumanlar)'.tr,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _teamCtrl,
                decoration: InputDecoration(
                  labelText: 'Jamoadagi odamlar soni'.tr,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Text('Ko\'rsatadigan xizmatlar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrganizerServiceType.values.map((t) {
                  final selected = _organizerTypes.contains(t.key);
                  return FilterChip(
                    label: Text(t.label.tr),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _organizerTypes.add(t.key);
                      } else if (_organizerTypes.length > 1) {
                        _organizerTypes.remove(t.key);
                      }
                    }),
                    selectedColor: accent,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Tadbir turlari'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                children:
                    [
                      EventType.wedding,
                      EventType.birthday,
                      EventType.corporate,
                      EventType.engagement,
                      EventType.memorial,
                    ].map((t) {
                      final selected = _eventTypes.contains(t.key);
                      return FilterChip(
                        label: Text(t.label.tr),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _eventTypes.add(t.key);
                          } else if (_eventTypes.length > 1) {
                            _eventTypes.remove(t.key);
                          }
                        }),
                        selectedColor: accent,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Ishlaydigan joylar'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                children:
                    [
                      EventVenueType.villageYard,
                      EventVenueType.openField,
                      EventVenueType.garden,
                      EventVenueType.hall,
                      EventVenueType.restaurant,
                    ].map((t) {
                      final selected = _venueTypes.contains(t.key);
                      return FilterChip(
                        label: Text(t.label.tr),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _venueTypes.add(t.key);
                          } else if (_venueTypes.length > 1) {
                            _venueTypes.remove(t.key);
                          }
                        }),
                        selectedColor: accent,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? CircularProgressIndicator(color: Colors.white)
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
