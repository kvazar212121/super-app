import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../services/api_service.dart';
import '../theme/lux_tokens.dart';

/// Sovrinli sezonli reyting ekrani.
///
/// Doimiy reytingdan farqi: bu yerda YULDUZ emas, OVOZ sanaladi.
/// Har bir foydalanuvchi butun aksiya davomida faqat BITTA provayderni
/// tanlay oladi — tanlagach tugmalar bloklanadi.
///
/// Backend: /api/v1/campaigns/* endpointlari.
class CampaignRatingScreen extends StatefulWidget {
  const CampaignRatingScreen({super.key});

  @override
  State<CampaignRatingScreen> createState() => _CampaignRatingScreenState();
}

class _CampaignRatingScreenState extends State<CampaignRatingScreen> {
  final ApiService _api = ApiService();

  Campaign? _campaign;
  List<CampaignRanking> _rankings = [];

  /// Foydalanuvchi qaysi provayderga ovoz bergani (null = bermagan).
  int? _votedProviderId;

  bool _loading = true;
  String? _error;
  bool _voting = false;

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
      final raw = await _api.getActiveCampaign();
      if (raw == null) {
        if (!mounted) return;
        setState(() {
          _campaign = null;
          _rankings = [];
          _loading = false;
        });
        return;
      }
      final campaign = Campaign.fromJson(raw);

      final board = await _api.getCampaignLeaderboard(campaign.id);
      final rankings = board
          .map((e) => CampaignRanking.fromJson(e as Map<String, dynamic>))
          .toList();

      int? voted;
      try {
        final mine = await _api.getMyCampaignVote(campaign.id);
        if (mine['has_voted'] == true) {
          voted = mine['provider_id'] as int?;
        }
      } catch (_) {
        // Tizimga kirmagan bo'lsa ovoz holati noma'lum — reyting baribir
        // ko'rsatiladi.
      }

      if (!mounted) return;
      setState(() {
        _campaign = campaign;
        _rankings = rankings;
        _votedProviderId = voted;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ma\'lumotni yuklab bo\'lmadi';
        _loading = false;
      });
    }
  }

  Future<void> _vote(CampaignRanking item) async {
    final campaign = _campaign;
    if (campaign == null || _votedProviderId != null || _voting) return;

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

    // Messenger'ni await'dan OLDIN olamiz (context eskirmasligi uchun).
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _voting = true);
    try {
      await _api.voteInCampaign(campaign.id, item.providerId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Ovozingiz qabul qilindi: ${item.name}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      // Backend aniq sabab qaytaradi: allaqachon ovoz berilgan (409),
      // buyurtma yo'q (403), aksiya tugagan (400).
      messenger.showSnackBar(
        SnackBar(content: Text(_voteErrorText(e))),
      );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  String _voteErrorText(Object e) {
    final s = e.toString();
    if (s.contains('409')) return 'Siz bu aksiyada allaqachon ovoz bergansiz';
    if (s.contains('403')) {
      return 'Ovoz berish uchun bu provayderda yakunlangan buyurtmangiz '
          'bo\'lishi kerak';
    }
    if (s.contains('400')) return 'Aksiya hozir ovoz qabul qilmayapti';
    return 'Ovoz berib bo\'lmadi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sovrinli reyting')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _messageView(theme, Icons.wifi_off, _error!, retry: true);
    }
    final campaign = _campaign;
    if (campaign == null) {
      return _messageView(
        theme,
        Icons.emoji_events_outlined,
        'Hozircha faol aksiya yo\'q.\nTez orada e\'lon qilinadi.',
      );
    }

    final totalVotes = _rankings.fold<int>(0, (sum, r) => sum + r.votes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _header(theme, campaign, totalVotes),
        const SizedBox(height: 20),
        Text(
          'Reyting',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          campaign.requireCompletedOrder
              ? 'Yulduz emas, OVOZ sanaladi. Ovoz berish uchun o\'sha yerda '
                  'yakunlangan buyurtmangiz bo\'lishi kerak.'
              : 'Yulduz emas, OVOZ sanaladi. Har bir foydalanuvchi 1 ta ovoz.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 12),
        if (_rankings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Hali hech kim ovoz bermagan.\nBirinchi bo\'ling!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor),
            ),
          )
        else
          ..._rankings.map((r) => _rankTile(theme, campaign, r)),
      ],
    );
  }

  Widget _messageView(ThemeData theme, IconData icon, String text,
      {bool retry = false}) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: theme.hintColor),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
        ),
        if (retry) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _load,
              child: const Text('Qayta urinish'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(ThemeData theme, Campaign campaign, int totalVotes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC9A227), Color(0xFFE3C766)],
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
                  campaign.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (campaign.description != null) ...[
            const SizedBox(height: 8),
            Text(
              campaign.description!,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
          if (campaign.prize != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      campaign.prize!,
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
                campaign.remainingLabel,
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

  Widget _rankTile(ThemeData theme, Campaign campaign, CampaignRanking r) {
    final isMine = _votedProviderId == r.providerId;
    final canVote =
        _votedProviderId == null && campaign.isRunning && !_voting;

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
          color: c != null ? LuxTokens.text : theme.hintColor,
        ),
      ),
    );
  }
}
