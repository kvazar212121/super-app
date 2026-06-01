import 'api_service.dart';

/// Provayderning kunlik band/bo'sh vaqt slotlari.
class ProviderAvailability {
  final String date;
  final List<String> slots;
  final List<String> booked;

  const ProviderAvailability({
    required this.date,
    required this.slots,
    required this.booked,
  });

  factory ProviderAvailability.fromJson(Map<String, dynamic> json) {
    return ProviderAvailability(
      date: json['date']?.toString() ?? '',
      slots: (json['slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      booked: (json['booked'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static const defaultSlots = [
    '09:00', '10:00', '11:00', '12:00',
    '14:00', '15:00', '16:00', '17:00', '18:00',
  ];

  /// API ishlamasa — barcha slotlar ochiq.
  factory ProviderAvailability.fallback(DateTime day) {
    return ProviderAvailability(
      date: _formatDate(day),
      slots: defaultSlots,
      booked: const [],
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Band slotlarni API dan olish — barcha booking ekranlari uchun.
class ProviderAvailabilityService {
  static final ProviderAvailabilityService _instance =
      ProviderAvailabilityService._();
  factory ProviderAvailabilityService() => _instance;
  ProviderAvailabilityService._();

  final ApiService _api = ApiService();

  Future<ProviderAvailability> fetch({
    required int providerId,
    required DateTime date,
  }) async {
    if (providerId <= 0) {
      return ProviderAvailability.fallback(date);
    }
    try {
      final data = await _api.getProviderAvailability(
        providerId,
        date: date,
      );
      return ProviderAvailability.fromJson(data);
    } catch (_) {
      return ProviderAvailability.fallback(date);
    }
  }
}
