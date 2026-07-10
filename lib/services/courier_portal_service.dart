import 'api_service.dart';

class CourierPortalService {
  static final CourierPortalService _instance = CourierPortalService._();
  factory CourierPortalService() => _instance;
  CourierPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    required String vehicleType,
    String? address,
  }) => _api.registerCourierSolo(
    name: name,
    phone: phone,
    serviceArea: serviceArea,
    vehicleType: vehicleType,
    address: address,
  );

  Future<Map<String, dynamic>> getMe() => _api.getProviderMe('kuryer');
}
