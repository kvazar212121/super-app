/// Ish e'lonlari modellari (mijoz e'loni + usta taklifi).
///
/// Backend: /api/v1/jobs/*
library;

enum JobStatus { open, assigned, completed, cancelled, expired, unknown }

JobStatus jobStatusFrom(String? raw) {
  switch (raw) {
    case 'open':
      return JobStatus.open;
    case 'assigned':
      return JobStatus.assigned;
    case 'completed':
      return JobStatus.completed;
    case 'cancelled':
      return JobStatus.cancelled;
    case 'expired':
      return JobStatus.expired;
    default:
      return JobStatus.unknown;
  }
}

String jobStatusLabel(JobStatus s) {
  switch (s) {
    case JobStatus.open:
      return 'Takliflar kutilmoqda';
    case JobStatus.assigned:
      return 'Usta tanlandi';
    case JobStatus.completed:
      return 'Yakunlandi';
    case JobStatus.cancelled:
      return 'Bekor qilindi';
    case JobStatus.expired:
      return 'Muddati o\'tdi';
    case JobStatus.unknown:
      return '—';
  }
}

class JobPost {
  final int id;
  final int userId;
  final int categoryId;
  final String title;
  final String description;
  final List<String> photos;
  final String address;
  final double? budget;
  final DateTime? neededAt;
  final DateTime? expiresAt;
  final JobStatus status;
  final int? assignedProviderId;
  final int offersCount;

  /// E'lon ustadan qancha uzoqda (km). Faqat usta lentasida keladi
  /// va ikkala tomonda koordinata bo'lgandagina hisoblanadi.
  final double? distanceKm;
  final DateTime? createdAt;

  const JobPost({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    this.photos = const [],
    this.budget,
    this.neededAt,
    this.expiresAt,
    this.assignedProviderId,
    this.offersCount = 0,
    this.distanceKm,
    this.createdAt,
  });

  bool get isOpen => status == JobStatus.open;

  factory JobPost.fromJson(Map<String, dynamic> json) => JobPost(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        categoryId: json['category_id'] as int,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        photos: (json['photos'] as List?)?.cast<String>() ?? const [],
        address: json['address'] as String? ?? '',
        budget: (json['budget'] as num?)?.toDouble(),
        neededAt: json['needed_at'] != null
            ? DateTime.tryParse(json['needed_at'] as String)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        status: jobStatusFrom(json['status'] as String?),
        assignedProviderId: json['assigned_provider_id'] as int?,
        offersCount: (json['offers_count'] as int?) ?? 0,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class JobOffer {
  final int id;
  final int jobId;
  final int providerId;
  final String? providerName;
  final double? providerRating;
  final int? providerReviewCount;
  final String? providerPhone;

  /// Chat ochish uchun: mijoz shu foydalanuvchiga yozadi.
  final int? providerOwnerUserId;

  final double price;
  final String? durationText;
  final String? message;
  final String status;
  final DateTime? createdAt;

  const JobOffer({
    required this.id,
    required this.jobId,
    required this.providerId,
    required this.price,
    required this.status,
    this.providerName,
    this.providerRating,
    this.providerReviewCount,
    this.providerPhone,
    this.providerOwnerUserId,
    this.durationText,
    this.message,
    this.createdAt,
  });

  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';

  factory JobOffer.fromJson(Map<String, dynamic> json) => JobOffer(
        id: json['id'] as int,
        jobId: json['job_id'] as int,
        providerId: json['provider_id'] as int,
        providerName: json['provider_name'] as String?,
        providerRating: (json['provider_rating'] as num?)?.toDouble(),
        providerReviewCount: json['provider_review_count'] as int?,
        providerPhone: json['provider_phone'] as String?,
        providerOwnerUserId: json['provider_owner_user_id'] as int?,
        price: (json['price'] as num).toDouble(),
        durationText: json['duration_text'] as String?,
        message: json['message'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
