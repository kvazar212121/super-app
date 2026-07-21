import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../utils/call_helper.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/order_status_timeline.dart';
import 'package:super_app/l10n/locale_controller.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _cancelling = false;
  Map<String, dynamic>? _checkinStatus;
  bool _loadingCheckin = true;

  @override
  void initState() {
    super.initState();
    _fetchCheckinStatus();
  }

  Future<void> _fetchCheckinStatus() async {
    try {
      final app = context.read<AppProvider>();
      final res = await app.api.getCheckinStatus(int.parse(widget.orderId));
      if (mounted) {
        setState(() {
          _checkinStatus = res;
          _loadingCheckin = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCheckin = false);
    }
  }

  Future<void> _submitCheckin(String response) async {
    try {
      final app = context.read<AppProvider>();
      await app.api.submitCheckin(
        int.parse(widget.orderId),
        side: 'user',
        response: response,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Javobingiz qabul qilindi'.tr)));
      }
      await _fetchCheckinStatus();
      await app.fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  ServiceOrder? _findOrder(AppProvider p) {
    for (final o in p.orders) {
      if (o.id == widget.orderId) return o;
    }
    return null;
  }

  Future<void> _cancelOrder(AppProvider p, ServiceOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buyurtmani bekor qilish'.tr),
        content: Text('Haqiqatan ham buyurtmani bekor qilmoqchimisiz?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Yo\'q'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Bekor qilish'.tr),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await p.cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Buyurtma bekor qilindi'.tr)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bekor qilib bo\'lmadi'.tr)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _confirmCompletion(
    AppProvider p,
    ServiceOrder order,
    bool confirm,
  ) async {
    setState(() => _cancelling = true);
    try {
      await p.api.confirmCompletion(int.parse(order.id), confirm: confirm);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirm ? 'Tasdiqlandi!'.tr : 'Shikoyat yuborildi'.tr,
            ),
          ),
        );
      }
      await p.fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'Xatolik'.tr}: $e')));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _rateProvider(AppProvider p, ServiceOrder order) async {
    int rating = 5;
    String comment = '';
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Ustani baholang'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Xizmat sifati qanday bo\'ldi?'.tr),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Izoh (ixtiyoriy)'.tr,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => comment = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Yopish'.tr,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      try {
                        await p.api.submitReview(
                          order.providerId!,
                          rating,
                          comment,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Baho yuborildi! Rahmat!'.tr),
                            ),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Xatolik yuz berdi'.tr)),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => submitting = false);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Yuborish'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus s) => switch (s) {
    OrderStatus.pending => const Color(0xFFF59E0B),
    OrderStatus.accepted => const Color(0xFF3B82F6),
    OrderStatus.inProgress => const Color(0xFFA855F7),
    OrderStatus.completed => const Color(0xFF10B981),
    OrderStatus.cancelled => const Color(0xFFEF4444),
    _ => const Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final order = _findOrder(app);

    if (order == null) {
      return GlassScaffold(
        showBackButton: true,
        title: 'Buyurtma'.tr,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => app.fetchOrders(),
                child: Text('Yangilash'.tr),
              ),
            ],
          ),
        ),
      );
    }

    final accent = order.category.accent;
    final statusColor = _statusColor(order.status);
    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(order.date.day)}.${two(order.date.month)}.${order.date.year}  '
        '${two(order.date.hour)}:${two(order.date.minute)}';
    final canCancel = order.status == OrderStatus.pending;

    return GlassScaffold(
      showBackButton: true,
      title: '${'Buyurtma'.tr} #${order.id}',
      body: RefreshIndicator(
        onRefresh: () async {
          await app.fetchOrders();
          await _fetchCheckinStatus();
        },
        color: accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: GlassTokens.radiusLg,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(order.category.icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.serviceName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          order.providerName,
                          style: TextStyle(
                            color: GlassTokens.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order.providerId != null)
                    IconButton(
                      icon: const Icon(LucideIcons.phone, color: Colors.green),
                      onPressed: () {
                        CallHelper.startCallWithPurposeCheck(
                          context,
                          order.providerId!,
                          order.providerName,
                        );
                      },
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: GlassTokens.radiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holat'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OrderStatusTimeline(status: order.status, accent: accent),
                ],
              ),
            ),
            if (order.status == OrderStatus.accepted && !_loadingCheckin) ...[
              if (_checkinStatus?['user'] == null) ...[
                const SizedBox(height: 16),
                GlassSurface(
                  padding: const EdgeInsets.all(18),
                  borderRadius: GlassTokens.radiusLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasdiqlash'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buyurtma vaqti yaqin. Yetib keldingizmi?'.tr,
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _submitCheckin('arrived'),
                              child: Text(
                                'Keldim'.tr,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _submitCheckin('delayed'),
                              child: Text(
                                'Kechikaman'.tr,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _submitCheckin('cant_come'),
                          child: Text(
                            'Bora olmayman'.tr,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                GlassSurface(
                  padding: const EdgeInsets.all(18),
                  borderRadius: GlassTokens.radiusLg,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Siz javob bergansiz. Usta tasdiqlashi kutilmoqda...'
                              .tr,
                          style: TextStyle(
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (order.status == OrderStatus.awaitingConfirmation) ...[
              const SizedBox(height: 16),
              GlassSurface(
                padding: const EdgeInsets.all(18),
                borderRadius: GlassTokens.radiusLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ishni yakunlash tasdig\'i'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usta o\'z ishini yakunlaganini xabar qildi. Buni tasdiqlaysizmi?'
                          .tr,
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: _cancelling
                                ? null
                                : () => _confirmCompletion(app, order, true),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              'Ha, bajardi'.tr,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: _cancelling
                            ? null
                            : () => _confirmCompletion(app, order, false),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(
                          'Yo\'q, usta kelmadi'.tr,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: GlassTokens.radiusLg,
              child: Column(
                children: [
                  _infoRow(context, LucideIcons.calendar, 'Vaqt'.tr, dateStr),
                  if (order.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(
                      context,
                      LucideIcons.mapPin,
                      'Manzil'.tr,
                      order.address,
                    ),
                  ],
                  if (order.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(
                      context,
                      LucideIcons.messageSquare,
                      'Izoh'.tr,
                      order.notes,
                    ),
                  ],
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jami',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(order.price)} so\'m',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelling
                      ? null
                      : () => _cancelOrder(app, order),
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(LucideIcons.xCircle),
                  label: Text('Buyurtmani bekor qilish'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            if (order.status == OrderStatus.completed &&
                order.providerId != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _rateProvider(app, order),
                  icon: Icon(Icons.star, color: Colors.amber),
                  label: Text('Ustani baholash'.tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: GlassTokens.secondaryText(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
