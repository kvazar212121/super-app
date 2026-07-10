/// O'zbekiston telefon raqamini +998XXXXXXXXX formatiga keltirish.
String normalizeUzPhone(String digits) {
  var d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('998') && d.length >= 12) {
    d = d.substring(0, 12);
  } else if (d.length == 9) {
    d = '998$d';
  }
  if (d.length != 12 || !d.startsWith('998')) {
    return '+$d';
  }
  return '+$d';
}

/// O'zbekiston mobil operator kodlari (9 xonali raqamning dastlabki 2 tasi).
const uzMobilePrefixes = <String>{
  '20',
  '33',
  '50',
  '55',
  '77',
  '88',
  '90',
  '91',
  '93',
  '94',
  '95',
  '97',
  '98',
  '99',
};

/// 9 xonali mahalliy raqamni tekshirish (+998 dan keyingi qism).
String? validateUzMobileDigits(String? value) {
  final d = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (d.length != 9) {
    return '9 ta raqam kiriting (masalan: 901234567 yoki 200163068)';
  }
  if (!uzMobilePrefixes.contains(d.substring(0, 2))) {
    return 'Noto\'g\'ri mobil raqam';
  }
  return null;
}
