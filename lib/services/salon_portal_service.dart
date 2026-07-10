import 'api_service.dart';

/// Salon — egasi, xodim, mobil kosmetolog.
class SalonPortalService {
  static final SalonPortalService _instance = SalonPortalService._();
  factory SalonPortalService() => _instance;
  SalonPortalService._();

  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> listSalons() => _api.getSalonVenues();

  Future<Map<String, dynamic>> getMyStatus() => _api.getSalonMyStatus();

  Future<Map<String, dynamic>> registerOwner({
    required String name,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required bool alsoWorksAsStylist,
    String? hours,
  }) => _api.registerSalonOwner(
    name: name,
    address: address,
    phone: phone,
    lat: lat,
    lng: lng,
    alsoWorksAsStylist: alsoWorksAsStylist,
    hours: hours,
  );

  Future<Map<String, dynamic>> registerMobile({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
  }) => _api.registerSalonMobile(
    name: name,
    phone: phone,
    serviceArea: serviceArea,
    address: address,
  );

  Future<Map<String, dynamic>> requestJoin({
    required String displayName,
    int? salonId,
    String? inviteCode,
  }) => _api.requestSalonJoin(
    displayName: displayName,
    salonId: salonId,
    inviteCode: inviteCode,
  );

  Future<List<Map<String, dynamic>>> getPendingMembers() async {
    final data = await _api.getSalonPendingMembers();
    return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> approveMember(int userId) => _api.approveSalonMember(userId);

  Future<void> rejectMember(int userId) => _api.rejectSalonMember(userId);

  Future<String> regenerateInvite() async {
    final data = await _api.regenerateSalonInvite();
    return data['invite_code']?.toString() ?? '';
  }
}

enum SalonRegistrationRole { owner, employee, mobile }
