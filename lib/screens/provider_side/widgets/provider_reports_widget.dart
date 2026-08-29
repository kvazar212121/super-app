import 'package:flutter/material.dart';
import 'package:super_app/l10n/locale_controller.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';
import '../../../theme/lux_tokens.dart';

class ProviderReportsWidget extends StatefulWidget {
  final String categoryKey;
  const ProviderReportsWidget({super.key, required this.categoryKey});

  @override
  State<ProviderReportsWidget> createState() => _ProviderReportsWidgetState();
}

class _ProviderReportsWidgetState extends State<ProviderReportsWidget> {
  final _portal = ProviderPortalService();
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      _report = await _portal.getReport(widget.categoryKey, 'yearly');
    } catch (_) {
      _report = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_report == null) {
      return Center(child: Text('Ma\'lumot yuklanmadi'.tr));
    }

    final totalLeads = _report!['total_leads'] as int? ?? 0;
    final balance = (_report!['balance'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Umumiy statistika',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Colors.black),
                onPressed: _loadAll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Tizim orqali kelganlar',
                '$totalLeads ta',
                LucideIcons.users,
                LuxTokens.goldDim,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Hisob balansi',
                '${NumberFormat('#,###').format(balance)} so\'m',
                LucideIcons.wallet,
                balance < 0 ? Colors.red.shade900 : LuxTokens.goldDim,
                subtitle: balance < 0 ? 'Balans manfiy!' : 'Balans yetarli',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LuxTokens.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LuxTokens.gold.withValues(alpha: 0.30)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: LuxTokens.gold, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Ma'lumot: Tizim orqali kelgan har bir mijoz uchun hisobingizdan admin paneldan belgilangan miqdorda xizmat haqi yechib olinadi.",
                  style: TextStyle(
                    color: LuxTokens.text,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: () => _showTopUpDialog(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LucideIcons.creditCard),
            label: const Text(
              "Hisobni to'ldirish",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showTopUpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hisobni to'ldirish",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "To'lov usulini tanlang",
                style: TextStyle(color: LuxTokens.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              _payMethodTile("Payme", const Color(0xFF33C4D8)),
              const SizedBox(height: 12),
              _payMethodTile("Click", const Color(0xFF0098EA)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Onlayn to'lov (Payme, Click) yaqin orada ochiladi.",
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Tushunarli",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// To'lov usuli (Payme/Click) — hozircha "Tez orada" belgisi bilan (ishlamaydi).
  Widget _payMethodTile(String name, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxTokens.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.creditCard,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Tez orada",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: LuxTokens.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
