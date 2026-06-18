/// Ilova konfiguratsiyasi — barcha ma'lumotlar backend API dan.
class AppConfig {
  /// Production — API va landing bir domen (SSL: hubservis.uz).
  /// So'rovlar: https://hubservis.uz/api/v1/...
  /// Android emulator: `http://10.0.2.2:8000`
  /// Lokal dev: `http://192.168.101.49:8000`
  static const String apiBaseUrl = 'https://hubservis.uz';
}
