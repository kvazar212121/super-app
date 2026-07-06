import 'api_service.dart';

class BozorchiPortalService {
  final ApiService _api = ApiService();

  Future<void> register({
    required String name,
    required String phone,
    required String serviceArea,
    required String vehicleType,
  }) async {
    await _api.registerBozorchi(
      name: name,
      phone: phone,
      serviceArea: serviceArea,
      vehicleType: vehicleType,
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _api.getProviderMe('bozorchi');
  }
}
