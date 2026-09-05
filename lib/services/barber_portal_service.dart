import 'api_service.dart';

/// Sartarosh — xona egasi, usta, mobil.
class BarberPortalService {
  static final BarberPortalService _instance = BarberPortalService._();
  factory BarberPortalService() => _instance;
  BarberPortalService._();

  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> listShops() => _api.getBarberShops();

  Future<Map<String, dynamic>> getMyStatus() => _api.getBarberMyStatus();

  Future<Map<String, dynamic>> registerShopOwner({
    required String name,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required bool alsoWorksAsBarber,
    String? hours,
    String? subCategory,
  }) => _api.registerBarberShopOwner(
    name: name,
    address: address,
    phone: phone,
    lat: lat,
    lng: lng,
    alsoWorksAsBarber: alsoWorksAsBarber,
    hours: hours,
    subCategory: subCategory,
  );

  Future<Map<String, dynamic>> registerMobile({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    String? subCategory,
  }) => _api.registerBarberMobile(
    name: name,
    phone: phone,
    serviceArea: serviceArea,
    address: address,
    subCategory: subCategory,
  );

  Future<Map<String, dynamic>> requestJoin({
    required String displayName,
    int? shopId,
    String? inviteCode,
  }) => _api.requestBarberJoin(
    displayName: displayName,
    shopId: shopId,
    inviteCode: inviteCode,
  );

  Future<List<Map<String, dynamic>>> getPendingMembers() async {
    final data = await _api.getBarberPendingMembers();
    return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> approveMember(int userId) => _api.approveBarberMember(userId);

  Future<void> rejectMember(int userId) => _api.rejectBarberMember(userId);

  Future<String> regenerateInvite() async {
    final data = await _api.regenerateBarberInvite();
    return data['invite_code']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> cancelJoin() => _api.cancelBarberJoin();
  Future<Map<String, dynamic>> leaveShop() => _api.leaveBarberShop();
}

enum BarberRegistrationRole { shopOwner, shopEmployee, mobile }
