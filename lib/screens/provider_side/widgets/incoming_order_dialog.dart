import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';

class IncomingOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final String categoryKey;
  final Color accent;

  const IncomingOrderDialog({
    super.key,
    required this.order,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<IncomingOrderDialog> createState() => _IncomingOrderDialogState();
}

class _IncomingOrderDialogState extends State<IncomingOrderDialog> {
  final _portal = ProviderPortalService();
  bool _acting = false;

  Future<void> _respond(String status) async {
    setState(() => _acting = true);
    try {
      final id = widget.order['id'] as int;
      await _portal.updateOrderStatus(widget.categoryKey, id, status);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmed'
                  ? 'Buyurtma qabul qilindi'
                  : 'Buyurtma rad etildi',
            ),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amal bajarilmadi')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = widget.order['date'] != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(widget.order['date'] as String))
        : '—';
    final price = (widget.order['price'] as num?) ?? 0;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.bellRing, size: 48, color: widget.accent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yangi buyurtma!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  _row(LucideIcons.user, 'Mijoz:', widget.order['user_name'] as String? ?? 'Noma\'lum'),
                  const Divider(height: 24),
                  _row(LucideIcons.briefcase, 'Xizmat:', widget.order['service_name'] as String? ?? ''),
                  const Divider(height: 24),
                  _row(LucideIcons.calendar, 'Vaqti:', time),
                  const Divider(height: 24),
                  _row(LucideIcons.banknote, 'Narxi:', '${NumberFormat('#,###').format(price)} so\'m', isBold: true),
                  if ((widget.order['notes'] as String?)?.isNotEmpty == true) ...[
                    const Divider(height: 24),
                    _row(LucideIcons.messageSquare, 'Izoh:', widget.order['notes'] as String),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _acting ? null : () => _respond('cancelled'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Rad etish', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _acting ? null : () => _respond('confirmed'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _acting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          )
                        : const Text('Qabul qilish', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
