class UserProfile {
  final String name;
  final String surname;
  final String phone;
  final String? avatarUrl;
  final String? telegramUsername;
  final double balance;
  final double cashback;
  final bool isPremium;

  UserProfile({
    required this.name,
    required this.surname,
    required this.phone,
    this.avatarUrl,
    this.telegramUsername,
    this.balance = 0.0,
    this.cashback = 0.0,
    this.isPremium = false,
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
    );
  }
  static UserProfile demo = UserProfile(
    name: "Kudratulloh",
    surname: "Rahimov",
    phone: "+998 90 123 45 67",
    avatarUrl: null,
    telegramUsername: "@kudratulloh",
    balance: 150000,
    cashback: 12500,
    isPremium: true,
  );
}
