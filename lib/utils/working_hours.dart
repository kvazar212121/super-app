/// Provayderning ish vaqti bo'yicha "hozir ochiqmi" ni aniqlash.
///
/// Backend `metadata.hours` maydonida ish vaqtini ERKIN MATN sifatida saqlaydi
/// (registratsiyada "Ish vaqti (ixtiyoriy)" maydoni). Shuning uchun uni
/// bardoshli tahlil qilamiz va tushunarsiz bo'lsa xizmat turiga xos standart
/// oraliqqa qaytamiz.
///
/// Qo'llab-quvvatlanadigan ko'rinishlar:
///   "9:00-21:00", "09:00 - 21:00", "9-21", "09.00–21.00", "24/7"
library;

/// `hours` matnidan ochilish/yopilish soatini ajratadi.
/// Tushunib bo'lmasa null qaytaradi.
({int open, int close})? parseWorkingHours(String? hours) {
  if (hours == null) return null;
  final s = hours.trim().toLowerCase();
  if (s.isEmpty) return null;

  // Kechayu kunduz ishlaydiganlar.
  if (s.contains('24/7') || s.contains('24 soat') || s.contains('kruglosutochno')) {
    return (open: 0, close: 24);
  }

  // Birinchi ikkita soat qiymatini olamiz: "9:00-21:00", "9-21", "09.00–21.00".
  final matches = RegExp(r'(\d{1,2})(?:[:.](\d{2}))?').allMatches(s).toList();
  if (matches.length < 2) return null;

  final open = int.tryParse(matches[0].group(1) ?? '');
  var close = int.tryParse(matches[1].group(1) ?? '');
  if (open == null || close == null) return null;
  if (open < 0 || open > 24 || close < 0 || close > 24) return null;

  // "09:00 - 00:00" — yarim tunda yopiladi degani.
  if (close == 0) close = 24;
  if (close <= open) return null;

  return (open: open, close: close);
}

/// Hozir ish vaqti ichidamizmi.
///
/// [hours] — backenddan kelgan erkin matn (bo'lmasligi mumkin).
/// [defaultOpen] / [defaultClose] — matn tushunarsiz bo'lganda ishlatiladigan,
/// xizmat turiga xos standart oraliq.
bool isOpenAt({
  String? hours,
  required int defaultOpen,
  required int defaultClose,
  DateTime? now,
}) {
  final parsed = parseWorkingHours(hours);
  final open = parsed?.open ?? defaultOpen;
  final close = parsed?.close ?? defaultClose;
  final h = (now ?? DateTime.now()).hour;
  return h >= open && h < close;
}

/// `rawJson` (provayder JSON) ichidan ish vaqti matnini topadi.
String? workingHoursFrom(Map<String, dynamic>? json) {
  if (json == null) return null;
  // Backend `metadata` ni har xil turda qaytarishi mumkin (Map<dynamic,
  // dynamic>, String, null...). Qattiq cast crash beradi, shuning uchun
  // faqat Map bo'lsa o'qiymiz.
  final rawMeta = json['metadata'];
  final meta = rawMeta is Map ? rawMeta : const {};
  final candidates = [
    meta['hours'],
    meta['working_hours'],
    json['hours'],
    json['working_hours'],
  ];
  for (final c in candidates) {
    if (c is String && c.trim().isNotEmpty) return c;
  }
  return null;
}
