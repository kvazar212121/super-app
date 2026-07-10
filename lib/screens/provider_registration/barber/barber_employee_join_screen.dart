import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/barber_portal_service.dart';
import '../../provider_side/provider_theme.dart';
import 'barber_pending_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class BarberEmployeeJoinScreen extends StatefulWidget {
  const BarberEmployeeJoinScreen({super.key});

  @override
  State<BarberEmployeeJoinScreen> createState() =>
      _BarberEmployeeJoinScreenState();
}

class _BarberEmployeeJoinScreenState extends State<BarberEmployeeJoinScreen>
    with SingleTickerProviderStateMixin {
  final _portal = BarberPortalService();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  late TabController _tabs;
  List<Map<String, dynamic>> _shops = [];
  int? _selectedShopId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadShops();
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

  Future<void> _loadShops() async {
    try {
      _shops = await _portal.listShops();
    } catch (_) {
      _shops = [];
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
    if (!isCodeTab && _selectedShopId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sartaroshxonani tanlang'.tr)));
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
        shopId: isCodeTab ? null : _selectedShopId,
        inviteCode: isCodeTab ? _codeCtrl.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BarberPendingScreen(
            shopName: result['shop_name']?.toString() ?? 'Sartaroshxona',
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
        appBar: AppBar(title: Text('Xonaga qo\'shilish'.tr)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Ismingiz (mijozlar ko\'radi)'.tr,
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Xonani tanlash'),
                Tab(text: 'Taklif kodi'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _shops.isEmpty
                      ? Center(child: Text('Sartaroshxonalar topilmadi'.tr))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shops.length,
                          itemBuilder: (_, i) {
                            final s = _shops[i];
                            final id = s['id'] as int;
                            final selected = _selectedShopId == id;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: selected ? Colors.black : null,
                              child: ListTile(
                                leading: Icon(
                                  LucideIcons.store,
                                  color: selected ? Colors.black : null,
                                ),
                                title: Text(s['name']?.toString() ?? ''),
                                subtitle: Text(s['address']?.toString() ?? ''),
                                trailing: selected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.black,
                                      )
                                    : null,
                                onTap: () =>
                                    setState(() => _selectedShopId = id),
                              ),
                            );
                          },
                        ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xona egasi bergan taklif kodini kiriting'.tr,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Taklif kodi'.tr,
                            hintText: 'Masalan: STYLE2024'.tr,
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
                      : Text('So\'rov yuborish'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
