import 'api_service.dart';

class DisinfectionPortalService {
  static final DisinfectionPortalService _instance = DisinfectionPortalService._();
  factory DisinfectionPortalService() => _instance;
  DisinfectionPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    List<String> areaTypes = const [],
    bool isCertified = false,
  }) =>
      _api.registerDisinfection(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
        areaTypes: areaTypes,
        isCertified: isCertified,
      );
}
