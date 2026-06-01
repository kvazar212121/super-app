import 'api_service.dart';

class AcPortalService {
  static final AcPortalService _instance = AcPortalService._();
  factory AcPortalService() => _instance;
  AcPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) =>
      _api.registerAcSolo(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
      );
}
