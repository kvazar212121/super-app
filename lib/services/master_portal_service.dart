import 'api_service.dart';

/// Usta chaqirish — yakka usta yoki brigada.
class MasterPortalService {
  static final MasterPortalService _instance = MasterPortalService._();
  factory MasterPortalService() => _instance;
  MasterPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) => _api.registerMasterSolo(
    name: name,
    phone: phone,
    serviceArea: serviceArea,
    address: address,
  );

  Future<Map<String, dynamic>> registerBrigade({
    required String name,
    required String phone,
    required String address,
    required String serviceArea,
    required int teamSize,
    double lat = 41.2995,
    double lng = 69.2401,
  }) => _api.registerMasterBrigade(
    name: name,
    phone: phone,
    address: address,
    serviceArea: serviceArea,
    teamSize: teamSize,
    lat: lat,
    lng: lng,
  );
}

enum MasterRegistrationRole { solo, brigade }
