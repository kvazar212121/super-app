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
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
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
