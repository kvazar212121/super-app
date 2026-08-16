import 'package:flutter/material.dart';

import '../models/campaign.dart';

/// Sovrinli sezonli reyting ekrani.
///
/// Doimiy reytingdan farqi: bu yerda YULDUZ emas, OVOZ sanaladi.
/// Har bir foydalanuvchi butun aksiya davomida faqat BITTA provayderni
/// tanlay oladi — tanlagach tugmalar bloklanadi.
///
/// DIQQAT: ilova hozircha backendga ulanmagan (demo ma'lumot). Backend
/// tayyor: /api/v1/campaigns/* endpointlari mavjud. Ulash uchun
/// `_load()` ichidagi izohga qarang.
class CampaignRatingScreen extends StatefulWidget {
  const CampaignRatingScreen({super.key});

  @override
  State<CampaignRatingScreen> createState() => _CampaignRatingScreenState();
}

class _CampaignRatingScreenState extends State<CampaignRatingScreen> {
  late Campaign _campaign;
  late List<CampaignRanking> _rankings;

  /// Foydalanuvchi qaysi provayderga ovoz bergani (null = bermagan).
  int? _votedProviderId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Backendga ulanganda shu joy quyidagicha bo'ladi:
    //   final c = await api.get('/campaigns/active');
    //   final board = await api.get('/campaigns/${c.id}/leaderboard');
    //   final mine = await api.get('/campaigns/${c.id}/my-vote');
    _campaign = Campaign.demo;
    _rankings = List.of(CampaignRanking.demo);
  }

  Future<void> _vote(CampaignRanking item) async {
    if (_votedProviderId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ovoz berish'),
        content: Text(
          '"${item.name}" uchun ovoz berasizmi?\n\n'
          'Diqqat: aksiya davomida faqat BITTA ovoz bera olasiz va uni '
          'keyin o\'zgartirib bo\'lmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, ovoz beraman'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Backend: POST /campaigns/{id}/vote  {provider_id: ...}
    // Takroriy ovoz 409 qaytaradi — DB darajasida ham qo'riqlanadi.
    setState(() {
      _votedProviderId = item.providerId;
      final i = _rankings.indexWhere((r) => r.providerId == item.providerId);
      if (i != -1) {
        final r = _rankings[i];
        _rankings[i] = CampaignRanking(
          providerId: r.providerId,
          name: r.name,
          address: r.address,
          votes: r.votes + 1,
          position: r.position,
        );
        _rankings.sort((a, b) => b.votes.compareTo(a.votes));
        for (var k = 0; k < _rankings.length; k++) {
          final r2 = _rankings[k];
          _rankings[k] = CampaignRanking(
            providerId: r2.providerId,
            name: r2.name,
            address: r2.address,
            votes: r2.votes,
            position: k + 1,
          );
        }
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ovozingiz qabul qilindi: ${item.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVotes =
        _rankings.fold<int>(0, (sum, r) => sum + r.votes);

    return Scaffold(
      appBar: AppBar(title: const Text('Sovrinli reyting')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _header(theme, totalVotes),
          const SizedBox(height: 20),
          Text(
            'Reyting',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Yulduz emas, OVOZ sanaladi. Har bir foydalanuvchi 1 ta ovoz.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          ..._rankings.map((r) => _rankTile(theme, r)),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, int totalVotes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _campaign.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_campaign.description != null) ...[
            const SizedBox(height: 8),
            Text(
              _campaign.description!,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
          if (_campaign.prize != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _campaign.prize!,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                _campaign.remainingLabel,
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              const Icon(Icons.how_to_vote, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '$totalVotes ovoz',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankTile(ThemeData theme, CampaignRanking r) {
    final isMine = _votedProviderId == r.providerId;
    final canVote = _votedProviderId == null && _campaign.isRunning;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isMine
            ? BorderSide(color: theme.colorScheme.primary, width: 1.6)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _medal(theme, r.position),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.address,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.how_to_vote,
                          size: 15, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${r.votes} ovoz',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 8),
                        const Text('· Sizning ovozingiz',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (canVote)
              FilledButton(
                onPressed: () => _vote(r),
                child: const Text('Ovoz'),
              )
            else if (isMine)
              Icon(Icons.check_circle, color: theme.colorScheme.primary)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _medal(ThemeData theme, int position) {
    const colors = {
      1: Color(0xFFFFD700),
      2: Color(0xFFC0C0C0),
      3: Color(0xFFCD7F32),
    };
    final c = colors[position];
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c ?? theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$position',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: c != null ? Colors.black87 : theme.hintColor,
        ),
      ),
    );
  }
}
