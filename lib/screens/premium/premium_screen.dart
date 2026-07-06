import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/feature_service.dart';

/// Premium obuna ekrani — narx, imkoniyatlar va obuna bo'lish.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = true;
  bool _busy = false;
  double _price = 0;
  int _days = 30;
  double _balance = 0;
  bool _isPremium = false;
  String? _until;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService().getPremiumStatus();
      _price = (s['price'] is num) ? (s['price'] as num).toDouble() : 0;
      _days = (s['duration_days'] is num) ? (s['duration_days'] as num).toInt() : 30;
      _balance = (s['balance'] is num) ? (s['balance'] as num).toDouble() : 0;
      _isPremium = s['is_premium'] == true;
      _until = s['premium_until'] as String?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _subscribe(String method) async {
    setState(() => _busy = true);
    try {
      final res = await ApiService().subscribePremium(method);
      final status = res['status'];
      await FeatureService().refreshPremium();
      if (!mounted) return;
      if (status == 'confirmed') {
        _showMsg('Premium ochildi! 🎉', success: true);
        await _load();
      } else {
        _showMsg(res['message'] ?? 'So\'rov yuborildi. Tasdiqlanishini kuting.', success: true);
        await _load();
      }
    } catch (e) {
      String msg = 'Xatolik';
      // Dio error detail
      final d = e.toString();
      if (d.contains('yetarli emas')) msg = 'Balansда mablag\' yetarli emas. Balansni to\'ldiring.';
      _showMsg(msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMsg(String m, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: success ? Colors.green.shade700 : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium obuna')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.white, size: 44),
                      const SizedBox(height: 12),
                      const Text('HubServis Premium',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        _isPremium
                            ? 'Siz premium obunachisiz ✅'
                            : 'Barcha premium funksiyalarni oching',
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isPremium) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text('Obuna faol'),
                      subtitle: Text(_until != null ? 'Amal qiladi: ${_until!.substring(0, 10)} gacha' : ''),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Text('${_price.toStringAsFixed(0)} so\'m',
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                        Text('$_days kunlik obuna', style: TextStyle(color: Theme.of(context).hintColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Balansingiz: ${_balance.toStringAsFixed(0)} so\'m',
                      textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy || _price <= 0 ? null : () => _subscribe('balance'),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: Text(_busy ? 'Kuting...' : 'Balansdan to\'lash'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy || _price <= 0 ? null : () => _subscribe('manual'),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('To\'lov so\'rovi yuborish (admin tasdiqlaydi)'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  if (_price <= 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Premium hozircha sozlanmagan.', textAlign: TextAlign.center),
                    ),
                ],
              ],
            ),
    );
  }
}
