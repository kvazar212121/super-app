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

/// API dan hub ma'lumotlarini yuklash (demo fallback bilan)
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
      if (items.isNotEmpty) {
        _cache[key] = items;
        return items;
      }
    } catch (e) {
      // API ishlamasa demo fallback
    }
    return [];
  }

  Future<List<BarberShop>> getBarberShops() async {
    final items = await fetchProviders(ServiceHubKind.sartarosh);
    if (items.isEmpty) return BarberShop.demoShops;
    return items.map(BarberShop.fromProviderJson).toList();
  }

  Future<List<BeautySalon>> getSalons() async {
    final items = await fetchProviders(ServiceHubKind.salon);
    if (items.isEmpty) return BeautySalon.demoSalons;
    return items.map(BeautySalon.fromProviderJson).toList();
  }

  Future<List<FootballField>> getFootballFields() async {
    final items = await fetchProviders(ServiceHubKind.futbol);
    if (items.isEmpty) return FootballField.demoFields;
    return items.map(FootballField.fromProviderJson).toList();
  }

  Future<List<Master>> getMasters(ServiceHubKind kind) async {
    final items = await fetchProviders(kind);
    final masters = items.where((j) {
      final t = j['metadata']?['type'] ?? 'master';
      return t == 'master';
    }).toList();
    if (masters.isEmpty) {
      return Master.demoMasters.where((m) {
        if (kind == ServiceHubKind.usta) return true;
        if (kind == ServiceHubKind.avtoYordam) return m.specialty == 'Avto-yordam';
        return m.specialty.toLowerCase().contains(kind.title.toLowerCase().split(' ').first);
      }).toList();
    }
    return masters.map((j) => Master.fromProviderJson(j, kind.title)).toList();
  }

  Future<List<Worker>> getWorkers() async {
    final items = await fetchProviders(ServiceHubKind.ishchi);
    if (items.isEmpty) return Worker.demoWorkers;
    return items.map(Worker.fromProviderJson).toList();
  }

  Future<List<AutoWorkshop>> getAutoWorkshops() async {
    final items = await fetchProviders(ServiceHubKind.avtoYordam);
    if (items.isEmpty) return AutoWorkshop.demoWorkshops;
    return items
        .where((j) => (j['metadata']?['type'] ?? '') == 'auto_workshop')
        .map(AutoWorkshop.fromProviderJson)
        .toList();
  }

  Future<List<EducationCenter>> getEducationCenters() async {
    final items = await fetchProviders(ServiceHubKind.repetitor);
    if (items.isEmpty) return EducationCenter.demoCenters;
    return items
        .where((j) => (j['metadata']?['type'] ?? '') == 'education_center')
        .map(EducationCenter.fromProviderJson)
        .toList();
  }

  Future<List<DisinfectionService>> getDisinfectionServices() async {
    final items = await fetchProviders(ServiceHubKind.dezinfeksiya);
    if (items.isEmpty) return DisinfectionService.demoServices;
    return items.map(DisinfectionService.fromProviderJson).toList();
  }

  Future<List<ApplianceRepair>> getApplianceRepairs() async {
    final items = await fetchProviders(ServiceHubKind.texnikaUstasi);
    if (items.isEmpty) return ApplianceRepair.demoRepairs;
    return items.map(ApplianceRepair.fromProviderJson).toList();
  }

  Future<List<CourierService>> getCouriers() async {
    final items = await fetchProviders(ServiceHubKind.kuryerlik);
    if (items.isEmpty) return CourierService.demoCouriers;
    return items.map(CourierService.fromProviderJson).toList();
  }

  Future<List<MassageHijoma>> getMassageCenters() async {
    final items = await fetchProviders(ServiceHubKind.massajHijoma);
    if (items.isEmpty) return MassageHijoma.demoCenters;
    return items.map(MassageHijoma.fromProviderJson).toList();
  }

  Future<List<NurseService>> getNurseServices() async {
    final items = await fetchProviders(ServiceHubKind.hamshira);
    if (items.isEmpty) return NurseService.demoServices;
    return items.map(NurseService.fromProviderJson).toList();
  }

  Future<List<EventPlanning>> getEventPlanners() async {
    final items = await fetchProviders(ServiceHubKind.tadbirlar);
    if (items.isEmpty) return EventPlanning.demoPlanners;
    return items.map(EventPlanning.fromProviderJson).toList();
  }

  void clearCache() => _cache.clear();
}

/// Ekranda ko'rsatish uchun yig'ilgan ma'lumotlar
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
