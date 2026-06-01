import 'api_service.dart';

class EventPortalService {
  final _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    int teamSize = 3,
    List<String> organizerTypes = const [],
    List<String> eventTypes = const [],
    List<String> venueTypes = const [],
  }) {
    return _api.registerEventOrganizer(
      name: name,
      phone: phone,
      serviceArea: serviceArea,
      address: address,
      teamSize: teamSize,
      organizerTypes: organizerTypes,
      eventTypes: eventTypes,
      venueTypes: venueTypes,
    );
  }
}
