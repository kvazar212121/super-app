class PaymentCard {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cardType; // visa, mastercard, uzcard, humo
  final double balance;
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cardType,
    this.balance = 0.0,
    this.isDefault = false,
  });

  String get maskedNumber {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    final expMonth = json['exp_month']?.toString().padLeft(2, '0') ?? '12';
    final expYrStr = json['exp_year']?.toString() ?? '26';
    final expYear = expYrStr.substring(expYrStr.length >= 2 ? expYrStr.length - 2 : 0);
    return PaymentCard(
      id: json['id']?.toString() ?? '',
      cardNumber: json['masked_number'] ?? '',
      cardHolder: json['bank'] ?? 'Bank',
      expiryDate: '$expMonth/$expYear',
      cardType: json['card_type'] ?? 'uzcard',
      balance: 150000.0,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final expParts = expiryDate.split('/');
    final month = int.tryParse(expParts[0]) ?? 12;
    final year = int.tryParse(expParts.length > 1 ? expParts[1] : '26') ?? 26;
    final fullYear = year < 100 ? 2000 + year : year;
    return {
      'masked_number': cardNumber,
      'bank': cardHolder,
      'card_type': cardType,
      'exp_month': month,
      'exp_year': fullYear,
    };
  }

  static List<PaymentCard> demoCards = [
    PaymentCard(
      id: '1',
      cardNumber: '8600123456789012',
      cardHolder: 'KUDRATULLOH RAHIMOV',
      expiryDate: '12/26',
      cardType: 'uzcard',
      balance: 250000,
      isDefault: true,
    ),
    PaymentCard(
      id: '2',
      cardNumber: '9860123456789012',
      cardHolder: 'KUDRATULLOH RAHIMOV',
      expiryDate: '08/25',
      cardType: 'humo',
      balance: 180000,
      isDefault: false,
    ),
  ];
}
