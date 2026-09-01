import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/lux_tokens.dart';
import '../../l10n/locale_controller.dart';
import '../../services/todo_local_service.dart';

class WaterTrackerWidget extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onChanged;

  const WaterTrackerWidget({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  State<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget> {
  final TodoLocalService _service = TodoLocalService();
  Map<String, dynamic>? _waterData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant WaterTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.getWaterForDate(widget.selectedDate);
    if (mounted) {
      setState(() {
        _waterData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _addWater(int amountMl) async {
    await _service.addWaterIntake(widget.selectedDate, amountMl);
    await _loadData();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || _waterData == null) {
      return const Center(child: CircularProgressIndicator(color: LuxTokens.gold));
    }

    final int currentMl = _waterData!['current_ml'] ?? 0;
    final int targetMl = _waterData!['target_ml'] ?? 2200;
    final double percent = (currentMl / targetMl).clamp(0.0, 1.0);
    final List history = _waterData!['history'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KATTA 24K OLTIN SUV KARTASI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? LuxTokens.surface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: LuxTokens.gold.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: LuxTokens.gold.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Icon(
                            LucideIcons.droplets,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suv Balansi'.tr,
                              style: TextStyle(
                                fontFamily: LuxTokens.body,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Kunlik me\'yor: ${(targetMl / 1000).toStringAsFixed(1)} Litr',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${(percent * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: LuxTokens.body,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 14,
                    backgroundColor: const Color(0xFFDBEAFE),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentMl ml ichildi',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Qoldi: ${(targetMl - currentMl).clamp(0, 9999)} ml',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. TEZKOR SUV QO'SHISH TUGMALARI
          Text(
            'Tezkor suv qo\'shish:'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildAddBtn('+200 ml', 200, isDark),
              const SizedBox(width: 8),
              _buildAddBtn('+350 ml', 350, isDark),
              const SizedBox(width: 8),
              _buildAddBtn('+500 ml', 500, isDark),
            ],
          ),
          const SizedBox(height: 22),

          // 3. SUV TARIXI RO'YXATI
          Text(
            'Bugungi suv tarixi:'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? LuxTokens.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LuxTokens.border),
              ),
              child: Center(
                child: Text(
                  'Hali suv ichilganligi belgilanmadi',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            Column(
              children: history.reversed.map<Widget>((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? LuxTokens.surface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.droplets, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${entry['amount']} ml suv ichildi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry['time'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddBtn(String label, int amount, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addWater(amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
          ),
          child: Column(
            children: [
              const Icon(LucideIcons.plus, color: Color(0xFF2563EB), size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
