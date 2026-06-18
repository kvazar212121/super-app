class UserProfile {
  final String name;
  final String surname;
  final String phone;
  final String? avatarUrl;
  final String? telegramUsername;
  final double balance;
  final double cashback;
  final bool isPremium;
  final int reminderOffsetMinutes;
  final bool isProvider;

  UserProfile({
    required this.name,
    required this.surname,
    required this.phone,
    this.avatarUrl,
    this.telegramUsername,
    this.balance = 0.0,
    this.cashback = 0.0,
    this.isPremium = false,
    this.reminderOffsetMinutes = 10,
    this.isProvider = false,
  });

  UserProfile copyWith({
    String? name,
    String? surname,
    String? phone,
    String? avatarUrl,
    String? telegramUsername,
    double? balance,
    double? cashback,
    bool? isPremium,
    int? reminderOffsetMinutes,
    bool? isProvider,
  }) {
    return UserProfile(
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      balance: balance ?? this.balance,
      cashback: cashback ?? this.cashback,
      isPremium: isPremium ?? this.isPremium,
      reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      isProvider: isProvider ?? this.isProvider,
    );
  }
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      telegramUsername: json['telegram_username'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      cashback: (json['cashback'] as num?)?.toDouble() ?? 0.0,
      isPremium: json['is_premium'] ?? false,
      reminderOffsetMinutes: json['reminder_offset_minutes'] ?? 10,
      isProvider: json['is_provider'] ?? false,
    );
  }
}
