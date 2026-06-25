import 'api_service.dart';

class BozorchiPortalService {
  final ApiService _api = ApiService();

  Future<void> register({
    required String name,
    required String phone,
    required String serviceArea,
    required String vehicleType,
  }) async {
    await _api.post('/providers/bozorchi/register', data: {
      'name': name,
      'phone': phone,
      'service_area': serviceArea,
      'vehicle_type': vehicleType,
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _api.getMyProvider('bozorchi');
  }
}
