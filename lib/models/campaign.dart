/// Sovrinli sezonli reyting (aksiya) modellari.
///
/// Doimiy reytingdan (BarberShop.rating) FARQI:
///  - yulduz soni ahamiyatsiz: har bir odam 1 ta OVOZ beradi
///  - bir foydalanuvchi butun aksiya davomida FAQAT BITTA provayderni
///    tanlaydi
///  - aksiya belgilangan kundan boshlanadi va tugaydi
///
/// Backend mos endpointlari:
///   GET  /api/v1/campaigns/active
///   GET  /api/v1/campaigns/{id}/leaderboard
///   GET  /api/v1/campaigns/{id}/my-vote
///   POST /api/v1/campaigns/{id}/vote
library;

enum CampaignStatus { upcoming, running, finished, disabled }

CampaignStatus campaignStatusFrom(String? raw) {
  switch (raw) {
    case 'running':
      return CampaignStatus.running;
    case 'upcoming':
      return CampaignStatus.upcoming;
    case 'finished':
      return CampaignStatus.finished;
    default:
      return CampaignStatus.disabled;
  }
}

class Campaign {
  final int id;
  final String title;
  final String? description;
  final int? categoryId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? prize;
  final CampaignStatus status;

  /// True bo'lsa faqat o'sha provayderda yakunlangan buyurtmasi bor
  /// foydalanuvchi ovoz bera oladi (soxta ovozga qarshi).
  final bool requireCompletedOrder;

  const Campaign({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.description,
    this.categoryId,
    this.prize,
    this.requireCompletedOrder = true,
  });

  bool get isRunning => status == CampaignStatus.running;

  /// Tugashiga qancha qoldi (tugagan bo'lsa Duration.zero).
  Duration get remaining {
    final left = endsAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String get remainingLabel {
    if (status == CampaignStatus.finished) return 'Yakunlandi';
    if (status == CampaignStatus.upcoming) return 'Tez orada';
    if (status == CampaignStatus.disabled) return "To'xtatilgan";
    final d = remaining;
    if (d.inDays > 0) return '${d.inDays} kun qoldi';
    if (d.inHours > 0) return '${d.inHours} soat qoldi';
    return '${d.inMinutes} daqiqa qoldi';
  }

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        categoryId: json['category_id'] as int?,
        startsAt: DateTime.parse(json['starts_at'] as String),
        endsAt: DateTime.parse(json['ends_at'] as String),
        prize: json['prize'] as String?,
        status: campaignStatusFrom(json['status'] as String?),
        requireCompletedOrder:
            json['require_completed_order'] as bool? ?? true,
      );

}

/// Reyting qatori: provayder + shu aksiyadagi ovozlar soni.
class CampaignRanking {
  final int providerId;
  final String name;
  final String address;
  final int votes;
  final int position;

  const CampaignRanking({
    required this.providerId,
    required this.name,
    required this.address,
    required this.votes,
    required this.position,
  });

  factory CampaignRanking.fromJson(Map<String, dynamic> json) =>
      CampaignRanking(
        providerId: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        votes: json['votes'] as int,
        position: json['position'] as int,
      );

}
