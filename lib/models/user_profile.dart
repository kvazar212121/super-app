class UserProfile {
  final String name;
  final String surname;
  final String phone;
  final String? avatarUrl;
  final String? telegramUsername;

  UserProfile({
    required this.name,
    required this.surname,
    required this.phone,
    this.avatarUrl,
    this.telegramUsername,
  });

  static UserProfile demo = UserProfile(
    name: "Kudratulloh",
    surname: "Rahimov",
    phone: "+998 90 123 45 67",
    avatarUrl: null,
    telegramUsername: "@kudratulloh",
  );
}
