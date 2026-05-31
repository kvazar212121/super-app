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
