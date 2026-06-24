/// Ilova konfiguratsiyasi — barcha ma'lumotlar backend API dan.
class AppConfig {
  /// Production — API va landing bir domen (SSL: hubservis.uz).
  /// So'rovlar: https://hubservis.uz/api/v1/...
  /// Android emulator: `http://10.0.2.2:8000`
  /// Lokal dev: `http://192.168.101.49:8000`
  static const String apiBaseUrl = 'http://127.0.0.1:8000';

  /// Rasm URL manzilini to'liq formatda qaytaradi (agar nisbiy yo'l bo'lsa apiBaseUrl ni biriktiradi).
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return '$apiBaseUrl$path';
  }
}
