import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import 'calls/dm_chat_screen.dart';

/// Usta paneli: ochiq e'lonlar lentasi + taklif berish.
///
/// Foydalanuvchi talabi: "ustalar soha egasi panelida e'lonlarni ko'rish
/// joyi bo'lishi kerak va u yerda qilinadigan ishlarni ko'rib mijozga
/// takliflar berishadi".
class JobsFeedScreen extends StatefulWidget {
  /// Ustaning provayder ID'si (taklif shu nomdan beriladi).
  final int providerId;

  /// Faqat shu soha e'lonlari ko'rsatiladi.
  final int? categoryId;

  const JobsFeedScreen({
    super.key,
    required this.providerId,
    this.categoryId,
  });

  @override
  State<JobsFeedScreen> createState() => _JobsFeedScreenState();
}

class _JobsFeedScreenState extends State<JobsFeedScreen> {
  final ApiService _api = ApiService();
  List<JobPost> _jobs = [];
  Set<int> _myOfferJobIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.getJobsFeed(
        categoryId: widget.categoryId,
        // Hudud filtri: boshqa shahardagi e'lon ko'rinmasin
        providerId: widget.providerId,
      );
      // Qaysi e'longa allaqachon taklif berganimni bilish uchun
      Set<int> mine = {};
      try {
        final offers = await _api.getMyJobOffers();
        mine = offers
            .map((e) => (e as Map<String, dynamic>)['job_id'] as int)
            .toSet();
      } catch (_) {
        // Takliflar yuklanmasa ham lenta ko'rsatiladi
      }
      if (!mounted) return;
      setState(() {
        _jobs = raw
            .map((e) => JobPost.fromJson(e as Map<String, dynamic>))
            .toList();
        _myOfferJobIds = mine;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'E\'lonlarni yuklab bo\'lmadi';
        _loading = false;
      });
    }
  }

  Future<void> _offer(JobPost job) async {
    final priceCtrl = TextEditingController(
      text: job.budget != null ? job.budget!.toStringAsFixed(0) : '',
    );
    final durationCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Taklif berish',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(job.title, style: TextStyle(color: Theme.of(ctx).hintColor)),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Narxingiz *',
                suffixText: 'so\'m',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              decoration: const InputDecoration(
                labelText: 'Qancha vaqtda bajarasiz',
                hintText: 'Masalan: 2 kun, bugun kechqurun',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                hintText: 'Mijozga nima demoqchisiz?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                final p = double.tryParse(
                    priceCtrl.text.trim().replaceAll(' ', ''));
                if (p == null || p <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Narxni to\'g\'ri kiriting')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Yuborish'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (sent != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.createJobOffer(job.id, {
        'provider_id': widget.providerId,
        'price': double.parse(priceCtrl.text.trim().replaceAll(' ', '')),
        if (durationCtrl.text.trim().isNotEmpty)
          'duration_text': durationCtrl.text.trim(),
        if (messageCtrl.text.trim().isNotEmpty)
          'message': messageCtrl.text.trim(),
      });
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Taklif yuborildi!')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_offerError(e))));
    }
  }

  String _offerError(Object e) {
    final s = e.toString();
    if (s.contains('409')) return 'Siz bu e\'longa allaqachon taklif bergansiz';
    if (s.contains('403')) return 'Bu provayder sizga tegishli emas';
    if (s.contains('400')) {
      return 'Bu e\'longa taklif berib bo\'lmaydi (yopilgan yoki boshqa soha)';
    }
    return 'Taklif yuborib bo\'lmadi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ish e\'lonlari')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Icon(Icons.wifi_off, size: 52, color: theme.hintColor),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    Center(
                      child: FilledButton(
                        onPressed: _load,
                        child: const Text('Qayta urinish'),
                      ),
                    ),
                  ])
                : _jobs.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 120),
                        Icon(Icons.work_outline,
                            size: 56, color: theme.hintColor),
                        const SizedBox(height: 14),
                        Text(
                          'Hozircha ochiq e\'lon yo\'q.\n'
                          'Yangi ish paydo bo\'lsa shu yerda ko\'rinadi.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        itemBuilder: (_, i) => _jobCard(theme, _jobs[i]),
                      ),
      ),
    );
  }

  Widget _jobCard(ThemeData theme, JobPost job) {
    final alreadyOffered = _myOfferJobIds.contains(job.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              job.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 15, color: theme.hintColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.address,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                // Masofa — usta kelish-kelmaslikni shu bo'yicha hal qiladi
                if (job.distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${job.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (job.budget != null) ...[
                  Icon(Icons.payments_outlined,
                      size: 15, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${job.budget!.toStringAsFixed(0)} so\'m',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text('Narx kelishiladi',
                      style: TextStyle(color: theme.hintColor)),
                const SizedBox(width: 14),
                Icon(Icons.mark_email_unread_outlined,
                    size: 15, color: theme.hintColor),
                const SizedBox(width: 4),
                Text('${job.offersCount} taklif'),
                if (job.neededAt != null) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.event, size: 15, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('${job.neededAt!.day}.${job.neededAt!.month}'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: alreadyOffered
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Taklif berilgan'),
                    )
                  : FilledButton(
                      onPressed: () => _offer(job),
                      child: const Text('Taklif berish'),
                    ),
            ),
            const SizedBox(height: 8),
            // Mijoz bilan aniqlashtirish uchun: usta e'lon egasiga
            // to'g'ridan-to'g'ri yoza oladi. Xabar shu e'longa
            // bog'lanadi, mijozda "Bu e'lon bo'yicha" deb ko'rinadi.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DmChatScreen(
                      peerId: job.userId,
                      peerName: 'Mijoz',
                      jobId: job.id,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Mijozga yozish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
