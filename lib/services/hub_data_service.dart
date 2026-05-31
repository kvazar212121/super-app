import '../models/barber_shop.dart';
import '../models/beauty_salon.dart';
import '../models/football_field.dart';
import '../models/master_worker.dart';
import '../models/auto_workshop.dart';
import '../models/education_center.dart';
import '../models/disinfection_service.dart';
import '../models/appliance_repair.dart';
import '../models/courier_service.dart';
import '../models/massage_hijoma.dart';
import '../models/nurse_service.dart';
import '../models/event_planning.dart';
import '../models/service_hub_kind.dart';
import 'api_service.dart';

/// API dan hub ma'lumotlarini yuklash.
class HubDataService {
  static final HubDataService _instance = HubDataService._();
  factory HubDataService() => _instance;
  HubDataService._();

  final ApiService _api = ApiService();
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  Future<List<Map<String, dynamic>>> fetchProviders(ServiceHubKind kind) async {
    final key = kind.name;
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final res = await _api.getProviders(categoryKey: key, perPage: 50);
      final items = (res['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _cache[key] = items;
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<List<BarberShop>> getBarberShops() async {
    final items = await fetchProviders(ServiceHubKind.sartarosh);
    return items.map(BarberShop.fromProviderJson).toList();
  }

  Future<List<BeautySalon>> getSalons() async {
    final items = await fetchProviders(ServiceHubKind.salon);
    return items.map(BeautySalon.fromProviderJson).toList();
  }

  Future<List<FootballField>> getFootballFields() async {
    final items = await fetchProviders(ServiceHubKind.futbol);
    return items.map(FootballField.fromProviderJson).toList();
  }

  Future<List<Master>> getMasters(ServiceHubKind kind) async {
    final items = await fetchProviders(kind);
    final masters = items.where((j) {
      final t = j['metadata']?['type'] ?? 'master';
      return t == 'master';
    }).toList();
    return masters.map((j) => Master.fromProviderJson(j, kind.title)).toList();
  }

  Future<List<Worker>> getWorkers() async {
    final items = await fetchProviders(ServiceHubKind.ishchi);
    return items.map(Worker.fromProviderJson).toList();
  }

  Future<List<AutoWorkshop>> getAutoWorkshops() async {
    final items = await fetchProviders(ServiceHubKind.avtoYordam);
    return items
        .where((j) => (j['metadata']?['type'] ?? '') == 'auto_workshop')
        .map(AutoWorkshop.fromProviderJson)
        .toList();
  }

  Future<List<EducationCenter>> getEducationCenters() async {
    final items = await fetchProviders(ServiceHubKind.repetitor);
    return items
        .where((j) => (j['metadata']?['type'] ?? '') == 'education_center')
        .map(EducationCenter.fromProviderJson)
        .toList();
  }

  Future<List<DisinfectionService>> getDisinfectionServices() async {
    final items = await fetchProviders(ServiceHubKind.dezinfeksiya);
    return items.map(DisinfectionService.fromProviderJson).toList();
  }

  Future<List<ApplianceRepair>> getApplianceRepairs() async {
    final items = await fetchProviders(ServiceHubKind.texnikaUstasi);
    return items.map(ApplianceRepair.fromProviderJson).toList();
  }

  Future<List<CourierService>> getCouriers() async {
    final items = await fetchProviders(ServiceHubKind.kuryerlik);
    return items.map(CourierService.fromProviderJson).toList();
  }

  Future<List<MassageHijoma>> getMassageCenters() async {
    final items = await fetchProviders(ServiceHubKind.massajHijoma);
    return items.map(MassageHijoma.fromProviderJson).toList();
  }

  Future<List<NurseService>> getNurseServices() async {
    final items = await fetchProviders(ServiceHubKind.hamshira);
    return items.map(NurseService.fromProviderJson).toList();
  }

  Future<List<EventPlanning>> getEventPlanners() async {
    final items = await fetchProviders(ServiceHubKind.tadbirlar);
    return items.map(EventPlanning.fromProviderJson).toList();
  }

  void clearCache() => _cache.clear();
}

class HubScreenData {
  List<BarberShop> barberShops = [];
  List<BeautySalon> salons = [];
  List<FootballField> footballFields = [];
  List<Master> masters = [];
  List<Worker> workers = [];
  List<AutoWorkshop> workshops = [];
  List<EducationCenter> educationCenters = [];
  List<DisinfectionService> disinfection = [];
  List<ApplianceRepair> appliance = [];
  List<CourierService> couriers = [];
  List<MassageHijoma> massage = [];
  List<NurseService> nurses = [];
  List<EventPlanning> events = [];
}

extension HubDataLoader on HubDataService {
  Future<HubScreenData> loadFor(ServiceHubKind kind) async {
    final d = HubScreenData();
    switch (kind) {
      case ServiceHubKind.sartarosh:
        d.barberShops = await getBarberShops();
      case ServiceHubKind.salon:
        d.salons = await getSalons();
      case ServiceHubKind.futbol:
        d.footballFields = await getFootballFields();
      case ServiceHubKind.ishchi:
        d.workers = await getWorkers();
      case ServiceHubKind.dezinfeksiya:
        d.disinfection = await getDisinfectionServices();
      case ServiceHubKind.texnikaUstasi:
        d.appliance = await getApplianceRepairs();
      case ServiceHubKind.kuryerlik:
        d.couriers = await getCouriers();
      case ServiceHubKind.massajHijoma:
        d.massage = await getMassageCenters();
      case ServiceHubKind.hamshira:
        d.nurses = await getNurseServices();
      case ServiceHubKind.tadbirlar:
        d.events = await getEventPlanners();
      case ServiceHubKind.avtoYordam:
        d.masters = await getMasters(kind);
        d.workshops = await getAutoWorkshops();
      case ServiceHubKind.repetitor:
        d.masters = await getMasters(kind);
        d.educationCenters = await getEducationCenters();
      case ServiceHubKind.usta:
        d.masters = await getMasters(kind);
        d.workshops = await getAutoWorkshops();
      default:
        d.masters = await getMasters(kind);
    }
    return d;
  }
}
