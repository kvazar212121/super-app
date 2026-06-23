import '../services/api_service.dart';

/// Soha egasi paneli API.
class ProviderPortalService {
  static final ProviderPortalService _instance = ProviderPortalService._();
  factory ProviderPortalService() => _instance;
  ProviderPortalService._();

  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> listMine() => _api.getMyProviders();

  Future<Map<String, dynamic>> getMe(String categoryKey) =>
      _api.getProviderMe(categoryKey);

  Future<Map<String, dynamic>> getStats(String categoryKey) =>
      _api.getProviderStats(categoryKey);

  Future<List<Map<String, dynamic>>> getTodayOrders(String categoryKey) async {
    final data = await _api.getProviderCalendar(categoryKey, DateTime.now());
    return (data['orders'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getCalendar(String categoryKey, DateTime day) =>
      _api.getProviderCalendar(categoryKey, day);

  Future<Map<String, dynamic>> getReport(String categoryKey, String period) =>
      _api.getProviderReport(categoryKey, period);

  Future<void> setActive(String categoryKey, bool active) =>
      _api.setProviderActive(categoryKey, active);

  Future<void> setPaused(String categoryKey, bool isPaused) =>
      _api.setProviderPaused(categoryKey, isPaused);

  Future<List<Map<String, dynamic>>> getBlockedTimes(String categoryKey) =>
      _api.getProviderBlockedTimes(categoryKey);

  Future<Map<String, dynamic>> addBlockedTime(String categoryKey, Map<String, dynamic> data) =>
      _api.addProviderBlockedTime(categoryKey, data);

  Future<void> removeBlockedTime(String categoryKey, int blockedTimeId) =>
      _api.removeProviderBlockedTime(categoryKey, blockedTimeId);

  Future<void> updateOrderStatus(
    String categoryKey,
    int orderId,
    String status, {
    bool? notifiedClient,
  }) => _api.updateProviderOrderStatus(categoryKey, orderId, status, notifiedClient: notifiedClient);

  Future<List<Map<String, dynamic>>> getPendingOrders(String categoryKey) =>
      _api.getProviderOrders(categoryKey, status: 'pending');

  Future<List<Map<String, dynamic>>> getOrders(
    String categoryKey, {
    String? status,
  }) => _api.getProviderOrders(categoryKey, status: status);

  Future<Map<String, dynamic>> updateMetadata(
    String categoryKey,
    Map<String, dynamic> metadata,
  ) => _api.updateProviderMetadata(categoryKey, metadata);

  Future<Map<String, dynamic>> register({
    required int categoryId,
    required String name,
    required String address,
    required String phone,
    Map<String, dynamic>? metadata,
  }) => _api.registerAsProvider(
        categoryId: categoryId,
        name: name,
        address: address,
        phone: phone,
        metadata: metadata,
      );
}
