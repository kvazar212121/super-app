import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Bu import `part` fayllar (service_hub/*.dart) uchun ham amal qiladi —
// ular alohida import yoza olmaydi.
import '../theme/lux_tokens.dart';

import '../models/master_worker.dart';
import '../models/auto_mobile_service.dart';
import '../models/courier_service.dart';
import '../models/massage_hijoma.dart';
import '../models/service_hub_kind.dart';
import '../services/hub_data_service.dart';
import '../services/api_service.dart';
import '../widgets/hub_map_preview.dart';
import '../widgets/hub_listing_widgets.dart';
import '../widgets/service_hub_widgets.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../theme/glass_tokens.dart';
import '../widgets/hub/massage_sections.dart';
import '../config/provider_category_config.dart';
import 'barber_booking_screen.dart';
import 'salon_booking_screen.dart';
import 'provider_profile_screen.dart';
import 'football_field_booking_screen.dart';
import 'universal_booking_screen.dart';
import 'disinfection_profile_screen.dart';
import 'appliance_dispatch_screen.dart';
import 'courier_dispatch_screen.dart';
import 'auto_mobile_profile_screen.dart';
import 'auto_workshop_profile_screen.dart';
import 'massage_booking_screen.dart';
import 'nurse_booking_screen.dart';
import 'dental_booking_screen.dart';
import 'event_booking_screen.dart';
import 'nanny_profile_screen.dart';
import 'tutor_profile_screen.dart';
import 'education_center_booking_screen.dart';
import 'simple_call_booking_screen.dart';
import 'service_hub/saved_places_screen.dart';
import 'service_hub/service_catalog_screen.dart';
import 'service_hub/service_list_screen.dart';
import 'auto_mobile_dispatch_screen.dart';
import 'auto_workshop_dispatch_screen.dart';
import 'worker_profile_screen.dart';
import 'appliance_profile_screen.dart';
import 'game_zone_booking_screen.dart';
import 'sport_facility_booking_screen.dart';
import 'event_venue_booking_screen.dart';
import 'event_team_profile_screen.dart';
import 'oshxona_profile_screen.dart';
import '../models/game_zone.dart';
import '../models/sport_facility.dart';
import '../models/event_venue.dart';
import '../utils/geo_utils.dart';
import '../utils/working_hours.dart';
import '../widgets/enhanced_service_map.dart';
import 'package:super_app/l10n/locale_controller.dart';

part 'service_hub/service_hub_map_section.dart';
part 'service_hub/service_hub_action_list.dart';

/// Yangi dizayn (qidiruv + vertikal qatorlar + alohida xarita ekrani) YOQILGAN
/// xizmat turlari. Sartaroshda sinovdan o'tkazilib, keyin qolganlariga
/// bosqichma-bosqich tarqatiladi. Ro'yxatda bo'lmagan xizmatlar eski
/// ko'rinishda (xarita + gorizontal kartalar) qoladi.
const Set<ServiceHubKind> kNewHubDesignKinds = {
  ServiceHubKind.sartarosh,
  ServiceHubKind.salon,
  ServiceHubKind.futbol,
  ServiceHubKind.ishchi,
  ServiceHubKind.usta,
  ServiceHubKind.elektrik,
  ServiceHubKind.santexnik,
  ServiceHubKind.tozalash,
  ServiceHubKind.avtoYordam,
  ServiceHubKind.enaga,
  ServiceHubKind.repetitor,
  ServiceHubKind.dezinfeksiya,
  ServiceHubKind.texnikaUstasi,
  ServiceHubKind.kuryerlik,
  ServiceHubKind.massajHijoma,
  ServiceHubKind.hamshira,
  ServiceHubKind.stomatologiya,
  ServiceHubKind.tadbirlar,
  ServiceHubKind.bozorchi,
  ServiceHubKind.oshxona,
  ServiceHubKind.gameZona,
  ServiceHubKind.sportMaydon,
  ServiceHubKind.telefonUsta,
  ServiceHubKind.kompyuterUsta,
  ServiceHubKind.itXizmat,
  // Toifaga kirmaydigan qolgan barcha xizmatlar shu yerda.
  ServiceHubKind.boshqa,
};

class ServiceHubScreen extends StatefulWidget {
  final ServiceHubKind kind;
  final Color accentColor;

  const ServiceHubScreen({
    super.key,
    required this.kind,
    required this.accentColor,
  });

  @override
  State<ServiceHubScreen> createState() => _ServiceHubScreenState();
}

class _ServiceHubScreenState extends State<ServiceHubScreen> {
  late Future<Map<String, dynamic>> _initFuture;
  String? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final d = await HubDataService().loadFor(widget.kind);
    List<dynamic> cats = [];
    try {
      cats = await ApiService().getCategories();
    } catch (_) {}
    return {'data': d, 'cats': cats};
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: widget.kind.title.tr,
      body: Container(
        decoration: BoxDecoration(color: Colors.transparent),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final resultMap = snapshot.data ?? {};
              final data =
                  resultMap['data'] as HubScreenData? ?? HubScreenData();
              final cats = resultMap['cats'] as List<dynamic>? ?? [];

              final config = ProviderCategoryConfig.byCategoryKey(
                widget.kind.name,
              );
              List<String> subCategories = config?.subCategories ?? [];

              // Ba'zi xizmatlarда config.categoryKey enum nomiga teng emas
              // (game_zona ≠ gameZona) — subkategoriyani shu yerда beramiz.
              if (subCategories.isEmpty) {
                subCategories = const {
                  ServiceHubKind.gameZona: [
                    'PS5',
                    'Kompyuter',
                    'VR',
                    'Bolalar zonasi',
                  ],
                  ServiceHubKind.sportMaydon: [
                    'Basketbol',
                    'Tennis',
                    'Voleybol',
                    'Yugurish',
                  ],
                }[widget.kind] ??
                    [];
              }

              for (final c in cats) {
                if (c['key'] == widget.kind.name) {
                  final variants = c['variants'] as List<dynamic>? ?? [];
                  if (variants.isNotEmpty) {
                    subCategories = variants
                        .map((v) => v['label_uz']?.toString() ?? '')
                        .where((s) => s.isNotEmpty)
                        .toList();
                  }
                  break;
                }
              }

              final filteredData = _filterData(data);

              // ── YANGI DIZAYN ──
              // Qidiruv + "xaritadan" tugmasi + to'liq enli vertikal qatorlar,
              // pastda "saqlanganlar"/"filtrlar". Xarita alohida ekranda.
              if (kNewHubDesignKinds.contains(widget.kind)) {
                final entries = _ActionList(
                  kind: widget.kind,
                  accentColor: widget.accentColor,
                  data: filteredData,
                ).catalogEntries(context);

                return ServiceListScreen(
                  kind: widget.kind,
                  accent: widget.accentColor,
                  entries: entries,
                  categories: subCategories,
                  selectedCategory: _selectedSubCategory,
                  onCategorySelected: (val) =>
                      setState(() => _selectedSubCategory = val),
                  embedded: true,
                );
              }

              return Column(
                children: [
                  // Filtr endi HAR DOIM xarita OSTIDA — bo'lim sarlavhasida
                  // (yuqorida alohida filtr qatori yo'q). Xarita katta qism,
                  // ro'yxat qolganini — ikkalasi Expanded, pastda bo'sh joy qolmaydi.
                  Expanded(
                    flex: 8,
                    child: _MapSection(
                      kind: widget.kind,
                      accentColor: widget.accentColor,
                      data: filteredData,
                    ),
                  ),
                  Expanded(
                    flex: 12,
                    child: _ActionList(
                      kind: widget.kind,
                      accentColor: widget.accentColor,
                      data: filteredData,
                      categories: subCategories,
                      selectedCategory: _selectedSubCategory,
                      onCategorySelected: (val) =>
                          setState(() => _selectedSubCategory = val),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  HubScreenData _filterData(HubScreenData data) {
    if (_selectedSubCategory == null) return data;

    final filtered = HubScreenData();
    final query = _selectedSubCategory!.toLowerCase();

    // Match if any of the salon/barber services contain the selected category, or if the subCategory matches
    filtered.barberShops = data.barberShops.where((e) {
      final hasService = e.services.any((s) => s.toLowerCase().contains(query));
      return hasService || e.subCategory == _selectedSubCategory;
    }).toList();

    filtered.salons = data.salons.where((e) {
      final hasService = e.services.any((s) => s.toLowerCase().contains(query));
      return hasService || e.subCategory == _selectedSubCategory;
    }).toList();

    filtered.mobileBarbers = data.mobileBarbers
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.massage = data.massage
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.masters = data.masters
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.footballFields = data.footballFields
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.workers = data.workers
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.workshops = data.workshops
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.autoMobile = data.autoMobile
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.educationCenters = data.educationCenters
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.disinfection = data.disinfection
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.appliance = data.appliance
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.couriers = data.couriers
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.nannies = data.nannies
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.tutors = data.tutors
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.nurses = data.nurses
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.dentalClinics = data.dentalClinics
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.events = data.events
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();
    filtered.mobileStylists = data.mobileStylists
        .where((e) => e.subCategory == _selectedSubCategory)
        .toList();

    filtered.genericProviders = data.genericProviders.where((e) {
      if (e is Map<String, dynamic>) {
        final meta = e['metadata'] as Map<String, dynamic>?;
        if (meta == null) return false;
        return meta['sub_category'] == _selectedSubCategory;
      }
      return true;
    }).toList();

    return filtered;
  }
}
