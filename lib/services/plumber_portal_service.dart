import 'api_service.dart';

class PlumberPortalService {
  static final PlumberPortalService _instance = PlumberPortalService._();
  factory PlumberPortalService() => _instance;
  PlumberPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) =>
      _api.registerPlumberSolo(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
      );
}
