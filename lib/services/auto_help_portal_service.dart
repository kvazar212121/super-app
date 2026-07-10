import 'api_service.dart';

class AutoHelpPortalService {
  static final AutoHelpPortalService _instance = AutoHelpPortalService._();
  factory AutoHelpPortalService() => _instance;
  AutoHelpPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerMobile({
    required String name,
    required String phone,
    required String serviceArea,
    required String vehicleType,
    String? address,
  }) => _api.registerAutoMobile(
    name: name,
    phone: phone,
    serviceArea: serviceArea,
    vehicleType: vehicleType,
    address: address,
  );

  Future<Map<String, dynamic>> registerWorkshop({
    required String name,
    required String phone,
    required String address,
    List<String>? specializations,
  }) => _api.registerAutoWorkshop(
    name: name,
    phone: phone,
    address: address,
    specializations: specializations,
  );
}
