/// Ilova konfiguratsiyasi — barcha ma'lumotlar backend API dan.
class AppConfig {
  /// Production — API va landing bir domen (SSL: hubservis.uz).
  /// So'rovlar: https://hubservis.uz/api/v1/...
  /// Android emulator: `http://10.0.2.2:8000`
  /// Lokal dev: `http://192.168.101.49:8000`
  static const String apiBaseUrl = 'https://hubservis.uz';

  /// Rasm URL manzilini to'liq formatda qaytaradi (agar nisbiy yo'l bo'lsa apiBaseUrl ni biriktiradi).
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return '$apiBaseUrl$path';
  }

  /// Provayder rasmini (banner/karta uchun) topib beradi. Backend rasmni
  /// yuqori darajali `cover_image` ustunda yoki `metadata` ichida turli
  /// kalitlar bilan qaytarishi mumkin — barchasini tekshiramiz.
  static String? resolveCoverImage(Map<String, dynamic>? json) {
    if (json == null) return null;
    final meta = json['metadata'] as Map<String, dynamic>?;
    final candidates = [
      json['cover_image'],
      json['cover_url'],
      json['image_url'],
      json['avatar_url'],
      meta?['cover_url'],
      meta?['cover_image'],
      meta?['image_url'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c;
    }
    return null;
  }
}
