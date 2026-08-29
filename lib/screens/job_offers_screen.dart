import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import 'calls/dm_chat_screen.dart';
import '../theme/lux_tokens.dart';
import '../l10n/locale_controller.dart';

/// E'longa kelgan takliflar (mijoz ko'radi).
class JobOffersScreen extends StatefulWidget {
  final JobPost job;

  const JobOffersScreen({super.key, required this.job});

  @override
  State<JobOffersScreen> createState() => _JobOffersScreenState();
}

class _JobOffersScreenState extends State<JobOffersScreen> {
  final ApiService _api = ApiService();
  late JobPost _job;
  List<JobOffer> _offers = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await _api.getJobOffers(_job.id);
      if (!mounted) return;
      setState(() {
        _offers = raw
            .map((e) => JobOffer.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _accept(JobOffer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: LuxTokens.gold.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        title: Text(
          'Ustani tanlash'.tr,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: Text(
          '${offer.providerName ?? "Bu usta".tr} ${'tanlansinmi?'.tr}\n\n'
          '${'Narx:'.tr} ${offer.price.toStringAsFixed(0)} ${'so\'m'.tr}\n\n'
          '${'Diqqat: boshqa takliflar avtomatik rad etiladi.'.tr}',
          style: const TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Bekor qilish'.tr,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxTokens.gold,
              foregroundColor: const Color(0xFF140D02),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ha, tanlayman'.tr,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final updated = await _api.acceptJobOffer(_job.id, offer.id);
      if (!mounted) return;
      setState(() => _job = JobPost.fromJson(updated));
      messenger.showSnackBar(
        SnackBar(content: Text('Usta tanlandi! Endi u bilan bog\'laning.'.tr)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Tanlab bo\'lmadi'.tr)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final updated = await _api.completeJob(_job.id);
      if (!mounted) return;
      setState(() => _job = JobPost.fromJson(updated));
      messenger.showSnackBar(
        SnackBar(content: Text('Ish yakunlandi'.tr)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Yakunlab bo\'lmadi'.tr)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openChat(JobOffer offer) {
    final peerId = offer.providerOwnerUserId;
    if (peerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu usta bilan yozishib bo\'lmaydi'.tr)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DmChatScreen(
          peerId: peerId,
          peerName: offer.providerName ?? 'Usta'.tr,
          jobId: widget.job.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_job.title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: _job.status == JobStatus.assigned
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _complete,
                    icon: const Icon(LucideIcons.circleCheck, color: Color(0xFF140D02), size: 20),
                    label: Text(
                      'Ish bajarildi'.tr,
                      style: const TextStyle(
                        color: Color(0xFF140D02),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        color: LuxTokens.gold,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _jobSummary(),
                  const SizedBox(height: 20),
                  Text(
                    '${'Takliflar'.tr} (${_offers.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_offers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Hali taklif yo\'q.\nUstalar ko\'rib chiqishmoqda.'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ..._offers.map((o) => _offerCard(o)),
                ],
              ),
      ),
    );
  }

  Widget _jobSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuxTokens.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _job.description,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF0F172A),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _job.address,
                  style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (_job.budget != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.banknote, size: 15, color: Color(0xFF8A5D0B)),
                const SizedBox(width: 6),
                Text(
                  '${'Taxminiy:'.tr} ${_job.budget!.toStringAsFixed(0)} ${'so\'m'.tr}',
                  style: const TextStyle(color: Color(0xFF8A5D0B), fontWeight: FontWeight.w900, fontSize: 13.5),
                ),
              ],
            ),
          ],
          if (_job.neededAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  '${'Kerak:'.tr} ${_job.neededAt!.day}.${_job.neededAt!.month}.${_job.neededAt!.year}',
                  style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _offerCard(JobOffer o) {
    final chosen = o.isAccepted;
    final dimmed = o.isRejected || o.isWithdrawn;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chosen
                ? LuxTokens.gold
                : const Color(0xFFCBD5E1),
            width: chosen ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: chosen
                  ? LuxTokens.gold.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
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
                Expanded(
                  child: Text(
                    o.providerName ?? 'Usta'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (o.providerRating != null) ...[
                  const Icon(LucideIcons.star, size: 16, color: Color(0xFFC9A227)),
                  const SizedBox(width: 3),
                  Text(
                    o.providerRating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF8A5D0B)),
                  ),
                  if (o.providerReviewCount != null)
                    Text(
                      ' (${o.providerReviewCount})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${o.price.toStringAsFixed(0)} ${'so\'m'.tr}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8A5D0B),
                  ),
                ),
                if (o.durationText != null) ...[
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.clock, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    o.durationText!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            if (o.message != null && o.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                o.message!,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (chosen) ...[
                  const Icon(LucideIcons.circleCheck, size: 18, color: Color(0xFF15803D)),
                  const SizedBox(width: 6),
                  Text(
                    'Tanlangan'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A5D0B),
                      side: const BorderSide(color: LuxTokens.gold),
                    ),
                    onPressed: () => _openChat(o),
                    icon: const Icon(LucideIcons.messageSquare, size: 16),
                    label: Text('Yozish'.tr),
                  ),
                ] else if (o.isRejected) ...[
                  Text(
                    'Rad etilgan'.tr,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                  ),
                ] else if (o.isWithdrawn) ...[
                  Text(
                    'Usta qaytarib oldi'.tr,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A5D0B),
                      side: const BorderSide(color: LuxTokens.gold),
                    ),
                    onPressed: () => _openChat(o),
                    icon: const Icon(LucideIcons.messageSquare, size: 16),
                    label: Text('Yozish'.tr),
                  ),
                  const Spacer(),
                  if (_job.isOpen)
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LuxTokens.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: _busy ? null : () => _accept(o),
                        child: Text(
                          'Tanlash'.tr,
                          style: const TextStyle(
                            color: Color(0xFF140D02),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
