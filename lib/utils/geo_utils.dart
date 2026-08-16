import 'dart:math' as math;

/// Foydalanuvchi joylashuvi (demo — Toshkent markazi).
const kDefaultUserLat = 41.311081;
const kDefaultUserLng = 69.240562;

/// Ikki nuqta orasidagi masofa (km).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * math.pi / 180;

String formatDistanceKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

/// Marshrut davomiyligini inson o'qiydigan ko'rinishga o'giradi.
///
/// Xarita preview kartasida "5614 daqiqa" kabi tushunarsiz qiymat
/// chiqmasligi uchun: 45 daqiqa · 2 soat 15 daq · 3 kun 21 soat.
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes daq';

  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours < 24) {
    return mins == 0 ? '$hours soat' : '$hours soat $mins daq';
  }

  final days = hours ~/ 24;
  final restHours = hours % 24;
  return restHours == 0 ? '$days kun' : '$days kun $restHours soat';
}
