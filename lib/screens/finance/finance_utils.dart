String financeMonthNameUz(int month) {
  const months = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'Iyun',
    'Iyul',
    'Avgust',
    'Sentabr',
    'Oktabr',
    'Noyabr',
    'Dekabr',
  ];
  return months[month - 1];
}

String formatFinanceCurrency(double amount) {
  final isNeg = amount < 0;
  final absAmt = amount.abs().toInt();
  final str = absAmt.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    buffer.write(str[i]);
    if ((str.length - 1 - i) % 3 == 0 && i != str.length - 1) {
      buffer.write(' ');
    }
  }
  return "${isNeg ? '-' : ''}${buffer.toString()} UZS";
}
