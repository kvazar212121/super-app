import '../services/api_service.dart';

class NannyPortalService {
  static final NannyPortalService _instance = NannyPortalService._();
  factory NannyPortalService() => _instance;
  NannyPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    int experienceYears = 0,
    List<String> ageGroups = const [],
    List<String> languages = const [],
    List<String> serviceTypes = const [],
    Map<String, dynamic>? documents,
  }) => _api.registerNanny(
    name: name,
    phone: phone,
    serviceArea: serviceArea,
    address: address,
    experienceYears: experienceYears,
    ageGroups: ageGroups,
    languages: languages,
    serviceTypes: serviceTypes,
    documents: documents,
  );
}
