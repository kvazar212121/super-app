import 'api_service.dart';

/// Tozalash — yakka tozalovchi yoki jamoa.
class CleaningPortalService {
  static final CleaningPortalService _instance = CleaningPortalService._();
  factory CleaningPortalService() => _instance;
  CleaningPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) =>
      _api.registerCleaningSolo(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
      );

  Future<Map<String, dynamic>> registerTeam({
    required String name,
    required String phone,
    required String address,
    required String serviceArea,
    required int teamSize,
    double lat = 41.2995,
    double lng = 69.2401,
  }) =>
      _api.registerCleaningTeam(
        name: name,
        phone: phone,
        address: address,
        serviceArea: serviceArea,
        teamSize: teamSize,
        lat: lat,
        lng: lng,
      );
}

enum CleaningRegistrationRole { solo, team }
