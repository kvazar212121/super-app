import 'api_service.dart';

class NursePortalService {
  static final NursePortalService _instance = NursePortalService._();
  factory NursePortalService() => _instance;
  NursePortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    List<String> medicalTypes = const [],
    String? qualifications,
    String? documentUrl,
    String? passportUrl,
  }) =>
      _api.registerNurse(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
        medicalTypes: medicalTypes,
        qualifications: qualifications,
        documentUrl: documentUrl,
        passportUrl: passportUrl,
      );

  Future<Map<String, dynamic>> getMe(String categoryKey) =>
      _api.getMyProvider(categoryKey);
}
