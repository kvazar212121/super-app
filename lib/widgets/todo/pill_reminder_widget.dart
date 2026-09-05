import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/lux_tokens.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import '../../services/todo_local_service.dart';

class PillReminderWidget extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onChanged;

  const PillReminderWidget({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  State<PillReminderWidget> createState() => _PillReminderWidgetState();
}

class _PillReminderWidgetState extends State<PillReminderWidget> {
  final TodoLocalService _service = TodoLocalService();
  List<Map<String, dynamic>> _pills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant PillReminderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _service.getPillsForDate(widget.selectedDate);
    if (mounted) {
      setState(() {
        _pills = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePill(String pillId, String timeSlot) async {
    await _service.togglePillTaken(pillId, timeSlot, widget.selectedDate);
    await _loadData();
    widget.onChanged();
  }

  Future<void> _showAddPillDialog() async {
    final titleCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTokens.glassFill(ctx),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: GlassTokens.glassBorder(ctx), width: 1.5),
        ),
        title: Text(
          'Dori / Vitamin eslatmasi qo\'shish'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: GlassTokens.primaryText(ctx),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: TextStyle(
                color: GlassTokens.primaryText(ctx),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Dori nomi (masalan: C Vitamini)',
                hintStyle: TextStyle(color: GlassTokens.secondaryText(ctx)),
                filled: true,
                fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: GlassTokens.glassBorder(ctx)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dosageCtrl,
              style: TextStyle(
                color: GlassTokens.primaryText(ctx),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Dozasi (masalan: 1 kapsula ovqatdan so\'ng)',
                hintStyle: TextStyle(color: GlassTokens.secondaryText(ctx)),
                filled: true,
                fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: GlassTokens.glassBorder(ctx)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF102A43),
            ),
            child: Text('Bekor qilish'.tr),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await _service.addPill(
                  titleCtrl.text.trim(),
                  dosageCtrl.text.trim().isNotEmpty ? dosageCtrl.text.trim() : '1 kapsula',
                  ['08:00', '20:00'],
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
                widget.onChanged();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF102A43),
              foregroundColor: Colors.white,
            ),
            child: Text('Qo\'shish'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = _service.formatDate(widget.selectedDate);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: GlassTokens.primaryText(context)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dori-Darmon va Vitaminlar:'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.plusCircle, color: GlassTokens.primaryText(context), size: 24),
                onPressed: _showAddPillDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_pills.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GlassTokens.glassFill(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GlassTokens.glassBorder(context)),
              ),
              child: Center(
                child: Text(
                  'Hali dorilar qo\'shilmadi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
              ),
            )
          else
            Column(
              children: _pills.map<Widget>((pill) {
                final List times = pill['times'] ?? [];
                final List takenLogs = pill['taken_logs'] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GlassTokens.glassFill(context),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: GlassTokens.glassBorder(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Icon(
                              LucideIcons.pill,
                              color: Color(0xFF102A43),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pill['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pill['dosage'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Time Slots Badges
                      Wrap(
                        spacing: 8,
                        children: times.map<Widget>((timeSlot) {
                          final key = "${dateStr}_$timeSlot";
                          final bool isTaken = takenLogs.contains(key);

                          return GestureDetector(
                            onTap: () => _togglePill(pill['id'], timeSlot),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isTaken ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isTaken ? const Color(0xFF102A43) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isTaken ? LucideIcons.checkCircle : LucideIcons.clock,
                                    size: 15,
                                    color: isTaken ? const Color(0xFF102A43) : const Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$timeSlot - ${isTaken ? "Ichildi" : "Kutilmoqda"}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isTaken ? const Color(0xFF102A43) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
}
