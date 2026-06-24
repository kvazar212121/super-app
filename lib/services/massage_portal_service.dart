import 'api_service.dart';

class MassagePortalService {
  static final MassagePortalService _instance = MassagePortalService._();
  factory MassagePortalService() => _instance;
  MassagePortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    double? lat,
    double? lng,
    String massageRole = 'solo',
    List<String> visitModes = const [],
    List<String> serviceTypes = const [],
    String gender = 'both',
    String? subCategory,
    int concurrentCapacity = 1,
  }) =>
      _api.registerMassage(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
        lat: lat,
        lng: lng,
        massageRole: massageRole,
        visitModes: visitModes,
        serviceTypes: serviceTypes,
        gender: gender,
        subCategory: subCategory,
        concurrentCapacity: concurrentCapacity,
      );
}
