import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import 'calls/dm_chat_screen.dart';

/// E'longa kelgan takliflar (mijoz ko'radi).
///
/// Mijoz ustani tanlaydi -> qolgan takliflar avtomatik rad etiladi.
/// Tanlangach usta bilan chat ochish mumkin.
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
        title: const Text('Ustani tanlash'),
        content: Text(
          '${offer.providerName ?? "Bu usta"} tanlansinmi?\n\n'
          'Narx: ${offer.price.toStringAsFixed(0)} so\'m\n\n'
          'Diqqat: boshqa takliflar avtomatik rad etiladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, tanlayman'),
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
        const SnackBar(content: Text('Usta tanlandi! Endi u bilan bog\'laning.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Tanlab bo\'lmadi')),
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
        const SnackBar(content: Text('Ish yakunlandi')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Yakunlab bo\'lmadi')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openChat(JobOffer offer) {
    final peerId = offer.providerOwnerUserId;
    if (peerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu usta bilan yozishib bo\'lmaydi')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DmChatScreen(
          peerId: peerId,
          peerName: offer.providerName ?? 'Usta',
          // Xabar shu e'longa bog'lanadi
          jobId: widget.job.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_job.title)),
      bottomNavigationBar: _job.status == JobStatus.assigned
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _complete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Ish bajarildi'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _jobSummary(theme),
                  const SizedBox(height: 20),
                  Text(
                    'Takliflar (${_offers.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_offers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Hali taklif yo\'q.\nUstalar ko\'rib chiqishmoqda.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                    )
                  else
                    ..._offers.map((o) => _offerCard(theme, o)),
                ],
              ),
      ),
    );
  }

  Widget _jobSummary(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_job.description),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 16, color: theme.hintColor),
                const SizedBox(width: 4),
                Expanded(child: Text(_job.address)),
              ],
            ),
            if (_job.budget != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 16, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('Taxminiy: ${_job.budget!.toStringAsFixed(0)} so\'m'),
                ],
              ),
            ],
            if (_job.neededAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('Kerak: ${_job.neededAt!.day}.'
                      '${_job.neededAt!.month}.${_job.neededAt!.year}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _offerCard(ThemeData theme, JobOffer o) {
    final chosen = o.isAccepted;
    final dimmed = o.isRejected || o.isWithdrawn;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: chosen
              ? BorderSide(color: theme.colorScheme.primary, width: 1.6)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.providerName ?? 'Usta',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (o.providerRating != null) ...[
                    const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(
                      o.providerRating!.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (o.providerReviewCount != null)
                      Text(' (${o.providerReviewCount})',
                          style: TextStyle(
                              fontSize: 12, color: theme.hintColor)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${o.price.toStringAsFixed(0)} so\'m',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (o.durationText != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 15, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(o.durationText!),
                  ],
                ],
              ),
              if (o.message != null && o.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(o.message!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (chosen) ...[
                    Icon(Icons.check_circle,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text('Tanlangan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _openChat(o),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Yozish'),
                    ),
                  ] else if (o.isRejected) ...[
                    Text('Rad etilgan',
                        style: TextStyle(color: theme.hintColor)),
                  ] else if (o.isWithdrawn) ...[
                    Text('Usta qaytarib oldi',
                        style: TextStyle(color: theme.hintColor)),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _openChat(o),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Yozish'),
                    ),
                    const Spacer(),
                    if (_job.isOpen)
                      FilledButton(
                        onPressed: _busy ? null : () => _accept(o),
                        child: const Text('Tanlash'),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
