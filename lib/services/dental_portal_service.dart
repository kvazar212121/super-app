import 'api_service.dart';

class DentalPortalService {
  static final DentalPortalService _instance = DentalPortalService._();
  factory DentalPortalService() => _instance;
  DentalPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String address,
    List<String> services = const [],
  }) =>
      _api.registerDentalClinic(
        name: name,
        phone: phone,
        address: address,
        services: services,
      );
}
