import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Markaziy API xizmati — barcha backend so'rovlari shu orqali o'tadi.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  // Callback: token muddati tugaganda auth providerga xabar berish
  void Function()? onTokenExpired;

  static String get baseUrl => AppConfig.apiBaseUrl;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
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

  /// SMS OTP yuborish
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String purpose = 'auth',
  }) async {
    final response = await _dio.post('/auth/otp/send', data: {
      'phone': phone,
      'purpose': purpose,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// SMS OTP tasdiqlash
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['access_token'] != null && data['refresh_token'] != null) {
      await saveTokens(data['access_token'], data['refresh_token']);
    }
    return data;
  }

  /// Ro'yxatdan o'tish
  Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String phone,
    required String password,
    required String verificationToken,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'surname': surname,
      'phone': phone,
      'password': password,
      'verification_token': verificationToken,
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
    String? search,
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
    if (search != null && search.isNotEmpty) params['search'] = search;
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

  /// Provayder band/bo'sh vaqt slotlari
  Future<Map<String, dynamic>> getProviderAvailability(
    int providerId, {
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      '/providers/$providerId/availability',
      queryParameters: {'date': dateStr},
    );
    return response.data as Map<String, dynamic>;
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

  /// Soha egasi sifatida ro'yxatdan o'tish
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

    final response = await _dio.post('/provider/register', data: data);
    return response.data;
  }

  // ─────────────── PROVIDER PORTAL ───────────────

  Future<List<Map<String, dynamic>>> getMyProviders() async {
    final response = await _dio.get('/provider/mine');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getProviderMe(String categoryKey) async {
    final response = await _dio.get(
      '/provider/me',
      queryParameters: {'category_key': categoryKey},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProviderStats(String categoryKey) async {
    final response = await _dio.get(
      '/provider/stats',
      queryParameters: {'category_key': categoryKey},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProviderCalendar(
    String categoryKey,
    DateTime day,
  ) async {
    final d =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      '/provider/calendar',
      queryParameters: {'category_key': categoryKey, 'day': d},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProviderReport(
    String categoryKey,
    String period,
  ) async {
    final response = await _dio.get(
      '/provider/reports',
      queryParameters: {'category_key': categoryKey, 'period': period},
    );
    return response.data;
  }

  Future<void> setProviderActive(String categoryKey, bool active) async {
    await _dio.patch(
      '/provider/me',
      queryParameters: {'category_key': categoryKey},
      data: {'is_active': active},
    );
  }

  Future<void> updateProviderOrderStatus(
    String categoryKey,
    int orderId,
    String status,
  ) async {
    await _dio.patch(
      '/provider/orders/$orderId/status',
      queryParameters: {'category_key': categoryKey},
      data: {'status': status},
    );
  }

  Future<List<Map<String, dynamic>>> getProviderOrders(
    String categoryKey, {
    String? status,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/provider/orders',
      queryParameters: {
        'category_key': categoryKey,
        if (status != null) 'status': status,
        'per_page': perPage,
      },
    );
    return (response.data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateProviderMetadata(
    String categoryKey,
    Map<String, dynamic> metadata,
  ) async {
    final response = await _dio.patch(
      '/provider/me',
      queryParameters: {'category_key': categoryKey},
      data: {'metadata_json': metadata},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── BARBER PORTAL ───────────────

  Future<List<Map<String, dynamic>>> getBarberShops() async {
    final response = await _dio.get('/provider/barber/shops');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBarberMyStatus() async {
    final response = await _dio.get('/provider/barber/my-status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerBarberShopOwner({
    required String name,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required bool alsoWorksAsBarber,
    String? hours,
  }) async {
    final response = await _dio.post('/provider/barber/register/shop-owner', data: {
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'also_works_as_barber': alsoWorksAsBarber,
      if (hours != null) 'hours': hours,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerBarberMobile({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/barber/register/mobile', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestBarberJoin({
    required String displayName,
    int? shopId,
    String? inviteCode,
  }) async {
    final response = await _dio.post('/provider/barber/join-request', data: {
      'display_name': displayName,
      if (shopId != null) 'shop_id': shopId,
      if (inviteCode != null && inviteCode.isNotEmpty) 'invite_code': inviteCode,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBarberPendingMembers() async {
    final response = await _dio.get('/provider/barber/pending-members');
    return response.data as Map<String, dynamic>;
  }

  Future<void> approveBarberMember(int userId) async {
    await _dio.post('/provider/barber/pending-members/$userId/approve');
  }

  Future<void> rejectBarberMember(int userId) async {
    await _dio.post('/provider/barber/pending-members/$userId/reject');
  }

  Future<Map<String, dynamic>> regenerateBarberInvite() async {
    final response = await _dio.post('/provider/barber/regenerate-invite');
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── CLEANING PORTAL ───────────────

  Future<Map<String, dynamic>> registerCleaningSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/cleaning/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerCleaningTeam({
    required String name,
    required String phone,
    required String address,
    required String serviceArea,
    required int teamSize,
    double lat = 41.2995,
    double lng = 69.2401,
  }) async {
    final response = await _dio.post('/provider/cleaning/register/team', data: {
      'name': name,
      'phone': phone,
      'address': address,
      'service_area': serviceArea,
      'team_size': teamSize,
      'lat': lat,
      'lng': lng,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── MASTER PORTAL (Usta chaqirish) ───────────────

  Future<Map<String, dynamic>> registerMasterSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/master/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerMasterBrigade({
    required String name,
    required String phone,
    required String address,
    required String serviceArea,
    required int teamSize,
    double lat = 41.2995,
    double lng = 69.2401,
  }) async {
    final response = await _dio.post('/provider/master/register/brigade', data: {
      'name': name,
      'phone': phone,
      'address': address,
      'service_area': serviceArea,
      'team_size': teamSize,
      'lat': lat,
      'lng': lng,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── SALON PORTAL ───────────────

  Future<List<Map<String, dynamic>>> getSalonVenues() async {
    final response = await _dio.get('/provider/salon/venues');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getSalonMyStatus() async {
    final response = await _dio.get('/provider/salon/my-status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerSalonOwner({
    required String name,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required bool alsoWorksAsStylist,
    String? hours,
  }) async {
    final response = await _dio.post('/provider/salon/register/owner', data: {
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'also_works_as_stylist': alsoWorksAsStylist,
      if (hours != null) 'hours': hours,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerSalonMobile({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/salon/register/mobile', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestSalonJoin({
    required String displayName,
    int? salonId,
    String? inviteCode,
  }) async {
    final response = await _dio.post('/provider/salon/join-request', data: {
      'display_name': displayName,
      if (salonId != null) 'salon_id': salonId,
      if (inviteCode != null && inviteCode.isNotEmpty) 'invite_code': inviteCode,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSalonPendingMembers() async {
    final response = await _dio.get('/provider/salon/pending-members');
    return response.data as Map<String, dynamic>;
  }

  Future<void> approveSalonMember(int userId) async {
    await _dio.post('/provider/salon/pending-members/$userId/approve');
  }

  Future<void> rejectSalonMember(int userId) async {
    await _dio.post('/provider/salon/pending-members/$userId/reject');
  }

  Future<Map<String, dynamic>> regenerateSalonInvite() async {
    final response = await _dio.post('/provider/salon/regenerate-invite');
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── ELECTRICIAN PORTAL ───────────────

  Future<Map<String, dynamic>> registerElectricianSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/electrician/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── PLUMBER PORTAL ───────────────

  Future<Map<String, dynamic>> registerPlumberSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/plumber/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── COURIER PORTAL ───────────────

  Future<Map<String, dynamic>> registerCourierSolo({
    required String name,
    required String phone,
    required String serviceArea,
    required String vehicleType,
    String? address,
  }) async {
    final response = await _dio.post('/provider/courier/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      'vehicle_type': vehicleType,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── AUTO HELP PORTAL ───────────────

  Future<Map<String, dynamic>> registerAutoMobile({
    required String name,
    required String phone,
    required String serviceArea,
    required String vehicleType,
    String? address,
  }) async {
    final response = await _dio.post('/provider/auto-help/register/mobile', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      'vehicle_type': vehicleType,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerAutoWorkshop({
    required String name,
    required String phone,
    required String address,
    List<String>? specializations,
  }) async {
    final response = await _dio.post('/provider/auto-help/register/workshop', data: {
      'name': name,
      'phone': phone,
      'address': address,
      if (specializations != null && specializations.isNotEmpty)
        'specializations': specializations,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── AC PORTAL ───────────────

  Future<Map<String, dynamic>> registerAcSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) async {
    final response = await _dio.post('/provider/ac/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── NANNY PORTAL ───────────────

  Future<Map<String, dynamic>> registerNanny({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    int experienceYears = 0,
    List<String> ageGroups = const [],
    List<String> languages = const [],
    List<String> serviceTypes = const [],
    Map<String, dynamic>? documents,
  }) async {
    final response = await _dio.post('/provider/nanny/register', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
      'experience_years': experienceYears,
      if (ageGroups.isNotEmpty) 'age_groups': ageGroups,
      if (languages.isNotEmpty) 'languages': languages,
      if (serviceTypes.isNotEmpty) 'service_types': serviceTypes,
      if (documents != null) 'documents': documents,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── TUTOR PORTAL ───────────────

  Future<Map<String, dynamic>> registerTutorSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    List<String> subjects = const [],
    List<String> lessonModes = const [],
    int experienceYears = 0,
  }) async {
    final response = await _dio.post('/provider/tutor/register/solo', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
      if (subjects.isNotEmpty) 'subjects': subjects,
      if (lessonModes.isNotEmpty) 'lesson_modes': lessonModes,
      'experience_years': experienceYears,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerTutorCenter({
    required String name,
    required String phone,
    required String address,
    List<String> courses = const [],
  }) async {
    final response = await _dio.post('/provider/tutor/register/center', data: {
      'name': name,
      'phone': phone,
      'address': address,
      if (courses.isNotEmpty) 'courses': courses,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── DISINFECTION PORTAL ───────────────

  Future<Map<String, dynamic>> registerDisinfection({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    List<String> areaTypes = const [],
    bool isCertified = false,
  }) async {
    final response = await _dio.post('/provider/disinfection/register', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
      if (areaTypes.isNotEmpty) 'area_types': areaTypes,
      'is_certified': isCertified,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── MASSAGE PORTAL ───────────────

  Future<Map<String, dynamic>> registerMassage({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    String massageRole = 'solo',
    List<String> visitModes = const [],
    List<String> serviceTypes = const [],
    String gender = 'both',
  }) async {
    final response = await _dio.post('/provider/massage/register', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
      'massage_role': massageRole,
      if (visitModes.isNotEmpty) 'visit_modes': visitModes,
      if (serviceTypes.isNotEmpty) 'service_types': serviceTypes,
      'gender': gender,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── NURSE PORTAL ───────────────

  Future<Map<String, dynamic>> registerNurse({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    List<String> medicalTypes = const [],
    String? qualifications,
  }) async {
    final response = await _dio.post('/provider/nurse/register', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
      if (medicalTypes.isNotEmpty) 'medical_types': medicalTypes,
      if (qualifications != null) 'qualifications': qualifications,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── DENTAL PORTAL ───────────────

  Future<Map<String, dynamic>> registerDentalClinic({
    required String name,
    required String phone,
    required String address,
    List<String> services = const [],
  }) async {
    final response = await _dio.post('/provider/dental/register', data: {
      'name': name,
      'phone': phone,
      'address': address,
      if (services.isNotEmpty) 'services': services,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─────────────── EVENT PORTAL ───────────────

  Future<Map<String, dynamic>> registerEventOrganizer({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    int teamSize = 3,
    List<String> organizerTypes = const [],
    List<String> eventTypes = const [],
    List<String> venueTypes = const [],
  }) async {
    final response = await _dio.post('/provider/event/register', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      if (address != null) 'address': address,
      'team_size': teamSize,
      if (organizerTypes.isNotEmpty) 'organizer_types': organizerTypes,
      if (eventTypes.isNotEmpty) 'event_types': eventTypes,
      if (venueTypes.isNotEmpty) 'venue_types': venueTypes,
    });
    return response.data as Map<String, dynamic>;
  }
}
