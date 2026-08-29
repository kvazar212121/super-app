import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../services/feature_service.dart';

import '../../widgets/crystal_diamond_widget.dart';

/// Premium obuna ekrani — narx, imkoniyatlar va obuna bo'lish (Balans / Payme / Click).
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with WidgetsBindingObserver {
  bool _loading = true;
  bool _busy = false;
  double _price = 0;
  int _days = 30;
  bool _isPremium = false;
  bool _paymeEnabled = false;
  bool _clickEnabled = false;
  String? _until;

  // Onlayn to'lov ochilganda holatni tekshirib turish uchun
  Timer? _pollTimer;
  bool _awaitingPayment = false;

  static const _features = [
    ('Barcha mini-ilovalar cheksiz', Icons.apps_rounded),
    ('Reklamasiz tajriba', Icons.block_rounded),
    ('Ustuvor qo\'llab-quvvatlash', Icons.support_agent_rounded),
    ('Maxsus premium belgisi', Icons.verified_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Foydalanuvchi to'lovdan qaytganda holatni yangilaymiz
    if (state == AppLifecycleState.resumed && _awaitingPayment) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final s = await ApiService().getPremiumStatus();
      _price = (s['price'] is num) ? (s['price'] as num).toDouble() : 0;
      _days = (s['duration_days'] is num) ? (s['duration_days'] as num).toInt() : 30;
      _isPremium = s['is_premium'] == true;
      _paymeEnabled = s['payme_enabled'] == true;
      _clickEnabled = s['click_enabled'] == true;
      _until = s['premium_until'] as String?;
      if (_isPremium && _awaitingPayment) {
        _awaitingPayment = false;
        _pollTimer?.cancel();
        await FeatureService().refreshPremium();
        if (mounted) _showMsg('Premium ochildi! 🎉'.tr, success: true);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// Onlayn to'lov (payme/click) — checkout sahifasini ochadi va holatni kuzatadi.
  Future<void> _payOnline(String method) async {
    setState(() => _busy = true);
    try {
      final res = await ApiService().subscribePremium(method);
      final url = res['checkout_url'] as String?;
      if (url == null || url.isEmpty) {
        _showMsg('To\'lov havolasi olinmadi. Qayta urinib ko\'ring.'.tr);
        return;
      }
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) {
        _showMsg('To\'lov sahifasini ochib bo\'lmadi.'.tr);
        return;
      }
      // To'lov kutilmoqda — holatni har 4 soniyada tekshiramiz
      _awaitingPayment = true;
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_awaitingPayment) return;
        _load(silent: true);
      });
      // 3 daqiqadan keyin pollingni to'xtatamiz
      Future.delayed(const Duration(minutes: 3), () {
        _awaitingPayment = false;
        _pollTimer?.cancel();
      });
    } catch (e) {
      final d = e.toString();
      _showMsg(d.contains('ulanmagan')
          ? 'Bu to\'lov usuli hozircha ulanmagan.'.tr
          : 'Xatolik'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMsg(String m, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: success ? Colors.green.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Premium obuna'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _headerCard(),
                const SizedBox(height: 20),
                _featuresCard(),
                const SizedBox(height: 20),
                if (_isPremium)
                  _activeCard()
                else
                  _purchaseSection(),
              ],
            ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8921F), Color(0xFFC9A227)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CrystalDiamondWidget(size: 54),
          const SizedBox(height: 12),
          Text(
            'HubServis Premium'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isPremium
                ? 'Siz premium obunachisiz ✅'.tr
                : 'Barcha premium funksiyalarni oching'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _featuresCard() {
    return Column(
      children: _features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8921F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.$2, color: const Color(0xFFB8921F), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  f.$1.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _activeCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text('Obuna faol'.tr),
        subtitle: Text(
          _until != null
              ? '${'Amal qiladi:'.tr} ${_until!.substring(0, 10)} ${'gacha'.tr}'
              : '',
        ),
      ),
    );
  }

  Widget _purchaseSection() {
    if (_price <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Premium hozircha sozlanmagan.'.tr, textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Text(
                '${_price.toStringAsFixed(0)} ${'so\'m'.tr}',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              Text(
                '$_days ${'kunlik obuna'.tr}',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Payme
        if (_paymeEnabled)
          _payButton(
            label: 'Payme orqali to\'lash'.tr,
            icon: Icons.credit_card,
            color: const Color(0xFF00CFCB),
            onTap: () => _payOnline('payme'),
          ),
        // Click
        if (_clickEnabled)
          _payButton(
            label: 'Click orqali to\'lash'.tr,
            icon: Icons.credit_card,
            color: const Color(0xFF0098EB),
            onTap: () => _payOnline('click'),
          ),
        if (!_paymeEnabled && !_clickEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Onlayn to\'lov (Payme/Click) tez orada ulanadi.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _payButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final child = outlined
        ? OutlinedButton.icon(
            onPressed: _busy ? null : onTap,
            icon: Icon(icon, color: color),
            label: Text(_busy ? 'Kuting...'.tr : label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )
        : FilledButton.icon(
            onPressed: _busy ? null : onTap,
            icon: Icon(icon),
            label: Text(_busy ? 'Kuting...'.tr : label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}
