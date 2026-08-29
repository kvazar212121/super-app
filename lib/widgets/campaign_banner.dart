import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../screens/campaign_rating_screen.dart';
import '../services/api_service.dart';

/// Bosh sahifadagi sovrinli reyting banneri.
///
/// Doimiy reytingdan alohida: bu VAQT BILAN CHEGARALANGAN musobaqa.
/// Faol aksiya bo'lmasa banner UMUMAN ko'rsatilmaydi (joy ham egallamaydi).
class CampaignBanner extends StatefulWidget {
  /// Tayyor aksiya berilsa tarmoqqa chiqilmaydi. Testda foydalanuvchi
  /// ekranda AYNAN nima ko'rishini tekshirish uchun kerak.
  final Campaign? initialCampaign;

  const CampaignBanner({super.key, this.initialCampaign});

  @override
  State<CampaignBanner> createState() => _CampaignBannerState();
}

class _CampaignBannerState extends State<CampaignBanner> {
  Campaign? _campaign;

  @override
  void initState() {
    super.initState();
    if (widget.initialCampaign != null) {
      _campaign = widget.initialCampaign!.isRunning
          ? widget.initialCampaign
          : null;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiService().getActiveCampaign();
      if (!mounted || raw == null) return;
      final c = Campaign.fromJson(raw);
      if (c.isRunning) setState(() => _campaign = c);
    } catch (_) {
      // Aksiya bo'lmasa yoki tarmoq yo'q bo'lsa banner ko'rsatilmaydi —
      // bosh sahifa baribir ishlayveradi.
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaign = _campaign;
    if (campaign == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CampaignRatingScreen()),
          );
          // Qaytgach yangilaymiz (ovoz bergan bo'lishi mumkin)
          _load();
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC9A227), Color(0xFFE3C766)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ovoz bering · ${campaign.remainingLabel}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
