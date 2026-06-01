import '../services/api_service.dart';

class TutorPortalService {
  static final TutorPortalService _instance = TutorPortalService._();
  factory TutorPortalService() => _instance;
  TutorPortalService._();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> registerSolo({
    required String name,
    required String phone,
    required String serviceArea,
    String? address,
    List<String> subjects = const [],
    List<String> lessonModes = const [],
    int experienceYears = 0,
  }) =>
      _api.registerTutorSolo(
        name: name,
        phone: phone,
        serviceArea: serviceArea,
        address: address,
        subjects: subjects,
        lessonModes: lessonModes,
        experienceYears: experienceYears,
      );

  Future<Map<String, dynamic>> registerCenter({
    required String name,
    required String phone,
    required String address,
    List<String> courses = const [],
  }) =>
      _api.registerTutorCenter(
        name: name,
        phone: phone,
        address: address,
        courses: courses,
      );
}
