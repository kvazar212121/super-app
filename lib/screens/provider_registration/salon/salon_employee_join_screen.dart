import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/salon_portal_service.dart';
import '../../provider_side/provider_theme.dart';
import 'salon_pending_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class SalonEmployeeJoinScreen extends StatefulWidget {
  const SalonEmployeeJoinScreen({super.key});

  @override
  State<SalonEmployeeJoinScreen> createState() =>
      _SalonEmployeeJoinScreenState();
}

class _SalonEmployeeJoinScreenState extends State<SalonEmployeeJoinScreen>
    with SingleTickerProviderStateMixin {
  final _portal = SalonPortalService();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  late TabController _tabs;
  List<Map<String, dynamic>> _salons = [];
  int? _selectedSalonId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadSalons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      if (user != null && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = '${user['name'] ?? ''} ${user['surname'] ?? ''}'
            .trim();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSalons() async {
    try {
      _salons = await _portal.listSalons();
    } catch (_) {
      _salons = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ismingizni kiriting'.tr)));
      return;
    }

    final isCodeTab = _tabs.index == 1;
    if (!isCodeTab && _selectedSalonId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Salonni tanlang'.tr)));
      return;
    }
    if (isCodeTab && _codeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Taklif kodini kiriting'.tr)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _portal.requestJoin(
        displayName: name,
        salonId: isCodeTab ? null : _selectedSalonId,
        inviteCode: isCodeTab ? _codeCtrl.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SalonPendingScreen(
            salonName: result['salon_name']?.toString() ?? 'Salon',
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Salonga qo\'shilish')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Ismingiz (mijozlar ko\'radi)',
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Salonni tanlash'),
                Tab(text: 'Taklif kodi'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _loading
                      ? Center(child: CircularProgressIndicator())
                      : _salons.isEmpty
                      ? Center(child: Text('Salonlar topilmadi'.tr))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _salons.length,
                          itemBuilder: (_, i) {
                            final s = _salons[i];
                            final id = s['id'] as int;
                            final selected = _selectedSalonId == id;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: selected ? const Color(0xFFEC4899) : null,
                              child: ListTile(
                                leading: Icon(
                                  LucideIcons.sparkles,
                                  color: selected
                                      ? const Color(0xFFEC4899)
                                      : null,
                                ),
                                title: Text(s['name']?.toString() ?? ''),
                                subtitle: Text(s['address']?.toString() ?? ''),
                                trailing: selected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFEC4899),
                                      )
                                    : null,
                                onTap: () =>
                                    setState(() => _selectedSalonId = id),
                              ),
                            );
                          },
                        ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Salon egasi bergan taklif kodini kiriting',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Taklif kodi'.tr,
                            prefixIcon: Icon(LucideIcons.link),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('So\'rov yuborish'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
