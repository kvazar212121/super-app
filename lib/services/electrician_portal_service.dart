import 'api_service.dart';

class ElectricianPortalService {
  static final ElectricianPortalService _instance = ElectricianPortalService._();
  factory ElectricianPortalService() => _instance;
  ElectricianPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) =>
      _api.registerElectricianSolo(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
      );
}
