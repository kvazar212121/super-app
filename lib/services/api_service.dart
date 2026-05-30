import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Markaziy API xizmati — barcha backend so'rovlari shu orqali o'tadi.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  // Callback: token muddati tugaganda auth providerga xabar berish
  void Function()? onTokenExpired;

  /// ⚠️ Development uchun: backend Docker'dagi host
  /// Android emulator: 10.0.2.2
  /// iOS simulator / Web / Physical device: localhost yoki real IP
  static const String baseUrl = 'http://localhost:8000';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor: token qo'shish va 401 ni ushlash
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            // Token yangilashga urinish
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Asl so'rovni qayta yuborish
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─────────────── Token Management ───────────────

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool get hasToken => _accessToken != null;

  Future<bool> _tryRefreshToken() async {
    try {
      final response = await Dio(
        BaseOptions(baseUrl: '$baseUrl/api/v1'),
      ).post('/auth/refresh', data: {'refresh_token': _refreshToken});

      if (response.statusCode == 200) {
        final data = response.data;
        await saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (_) {}

    // Refresh ham ishlamadi — logout
    await clearTokens();
    onTokenExpired?.call();
    return false;
  }

  // ─────────────── AUTH ───────────────

  /// Ro'yxatdan o'tish
  Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'surname': surname,
      'phone': phone,
      'password': password,
    });
    final data = response.data;
    await saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  /// Login
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    final data = response.data;
    await saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  /// Debug login (development only)
  Future<Map<String, dynamic>> debugLogin({String phone = 'admin'}) async {
    final response = await _dio.get('/auth/debug-login', queryParameters: {
      'phone': phone,
    });
    final data = response.data;
    await saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  // ─────────────── USERS ───────────────

  /// Joriy foydalanuvchi ma'lumotlari
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  /// Profilni yangilash
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/me', data: data);
    return response.data;
  }

  /// Balansni to'ldirish
  Future<Map<String, dynamic>> topUpBalance(double amount) async {
    final response = await _dio.post('/users/top-up', data: {
      'amount': amount,
    });
    return response.data;
  }

  /// Kartalar ro'yxati
  Future<List<dynamic>> getCards() async {
    final response = await _dio.get('/users/cards');
    return response.data;
  }

  /// Karta qo'shish
  Future<Map<String, dynamic>> addCard(Map<String, dynamic> data) async {
    final response = await _dio.post('/users/cards', data: data);
    return response.data;
  }

  /// Karta o'chirish
  Future<void> removeCard(int cardId) async {
    await _dio.delete('/users/cards/$cardId');
  }

  // ─────────────── CATEGORIES ───────────────

  /// Kategoriyalar ro'yxati
  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get('/categories');
    return response.data;
  }

  /// Bitta kategoriya
  Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await _dio.get('/categories/$id');
    return response.data;
  }

  /// Kategoriya variantlari
  Future<List<dynamic>> getCategoryVariants(int categoryId) async {
    final response = await _dio.get('/categories/$categoryId/variants');
    return response.data;
  }

  // ─────────────── PROVIDERS ───────────────

  /// Provayderlar ro'yxati
  Future<Map<String, dynamic>> getProviders({
    int? categoryId,
    String? categoryKey,
    int page = 1,
    int perPage = 20,
    double? lat,
    double? lng,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    if (categoryKey != null) params['category_key'] = categoryKey;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;

    final response = await _dio.get('/providers', queryParameters: params);
    return response.data;
  }

  /// Bitta provayder
  Future<Map<String, dynamic>> getProvider(int id) async {
    final response = await _dio.get('/providers/$id');
    return response.data;
  }

  /// Provayder sharhlari
  Future<Map<String, dynamic>> getProviderReviews(
    int providerId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/providers/$providerId/reviews',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data;
  }

  /// Sharh qo'shish
  Future<Map<String, dynamic>> addReview({
    required int providerId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('/providers/reviews', data: {
      'provider_id': providerId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    return response.data;
  }

  // ─────────────── ORDERS ───────────────

  /// Buyurtma yaratish
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final response = await _dio.post('/orders', data: data);
    return response.data;
  }

  /// Mening buyurtmalarim
  Future<Map<String, dynamic>> getMyOrders({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/orders/my',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data;
  }

  /// Bitta buyurtma
  Future<Map<String, dynamic>> getMyOrder(int orderId) async {
    final response = await _dio.get('/orders/my/$orderId');
    return response.data;
  }

  /// Buyurtma statusini o'zgartirish
  Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final response = await _dio.patch(
      '/orders/my/$orderId/status',
      data: {'status': status},
    );
    return response.data;
  }

  // ─────────────── UPLOAD ───────────────

  /// Avatar yuklash
  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/upload/avatar', data: formData);
    return response.data['url'];
  }

  /// Cover rasm yuklash
  Future<String> uploadCover(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/upload/cover', data: formData);
    return response.data['url'];
  }

  // ─────────────── NOTIFICATIONS ───────────────

  /// Bildirishnomalar
  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _dio.get('/notifications');
    return response.data;
  }

  /// O'qilmagan soni
  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    return response.data['count'] ?? 0;
  }

  /// O'qilgan deb belgilash
  Future<void> markNotificationRead(String id) async {
    await _dio.post('/notifications/$id/read');
  }

  // ─────────────── PROVIDER REGISTRATION ───────────────

  /// O'zini provayder sifatida ro'yxatdan o'tkazish
  Future<Map<String, dynamic>> registerAsProvider({
    required int categoryId,
    required String name,
    required String address,
    required String phone,
    double lat = 41.2995,
    double lng = 69.2401,
    String? coverImage,
    Map<String, dynamic>? metadata,
  }) async {
    final data = {
      'category_id': categoryId,
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
    };
    if (coverImage != null) data['cover_image'] = coverImage;
    if (metadata != null) data['metadata_json'] = metadata;

    // Admin API orqali yaratish (hozircha)
    final response = await _dio.post('/admin/providers', data: data);
    return response.data;
  }
}
