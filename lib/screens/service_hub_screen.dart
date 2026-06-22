import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/barber_shop.dart';
import '../models/beauty_salon.dart';
import '../models/football_field.dart';
import '../models/master_worker.dart';
import '../models/auto_workshop.dart';
import '../models/education_center.dart';
import '../models/disinfection_service.dart';
import '../models/appliance_repair.dart';
import '../models/courier_service.dart';
import '../models/nanny_service.dart' as nanny_model;
import '../models/auto_mobile_service.dart';
import '../models/massage_hijoma.dart';
import '../models/nurse_service.dart';
import '../models/dental_clinic.dart';
import '../models/event_planning.dart';
import '../models/service_hub_kind.dart';
import '../services/hub_data_service.dart';
import '../widgets/hub_map_preview.dart';
import '../widgets/hub_listing_widgets.dart';
import '../widgets/service_hub_widgets.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import '../widgets/hub/massage_sections.dart';
import '../config/provider_category_config.dart';
import '../widgets/hub_category_chips.dart';
import 'all_categories_screen.dart';
import 'barber_booking_screen.dart';
import 'barber_map_screen.dart';
import 'salon_booking_screen.dart';
import 'master_dispatch_screen.dart';
import 'provider_profile_screen.dart';
import 'football_field_booking_screen.dart';
import 'universal_booking_screen.dart';
import 'disinfection_booking_screen.dart';
import 'appliance_booking_screen.dart';
import 'courier_booking_screen.dart';
import 'auto_help_booking_screen.dart';
import 'auto_workshop_booking_screen.dart';
import 'massage_booking_screen.dart';
import 'nurse_booking_screen.dart';
import 'dental_booking_screen.dart';
import 'event_booking_screen.dart';
import 'nanny_profile_screen.dart';
import 'tutor_profile_screen.dart';
import 'education_center_booking_screen.dart';
import 'simple_call_booking_screen.dart';
import 'service_hub/saved_places_screen.dart';

part 'service_hub/service_hub_map_section.dart';
part 'service_hub/service_hub_action_list.dart';

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
  late Future<HubScreenData> _dataFuture;
  String? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    _dataFuture = HubDataService().loadFor(widget.kind);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: widget.kind.title,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: FutureBuilder<HubScreenData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? HubScreenData();
              final config = ProviderCategoryConfig.byCategoryKey(widget.kind.name);
              final subCategories = config?.subCategories ?? [];
              
              final filteredData = _filterData(data);

              return Column(
                children: [
                  _MapSection(kind: widget.kind, accentColor: widget.accentColor, data: filteredData),
                  if (subCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    HubCategoryChips(
                      categories: subCategories,
                      selectedCategory: _selectedSubCategory,
                      onCategorySelected: (val) {
                        setState(() {
                          _selectedSubCategory = val;
                        });
                      },
                      accentColor: widget.accentColor,
                    ),
                  ],
                  Expanded(child: _ActionList(kind: widget.kind, accentColor: widget.accentColor, data: filteredData)),
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
    // Copy and filter lists where applicable
    filtered.barberShops = data.barberShops.where((e) => e.subCategory == _selectedSubCategory).toList();
    filtered.mobileBarbers = data.mobileBarbers.where((e) => e.subCategory == _selectedSubCategory).toList();
    filtered.massage = data.massage.where((e) => e.subCategory == _selectedSubCategory).toList();
    
    // Pass other lists unchanged (we only filter those that support subCategory right now)
    filtered.salons = data.salons;
    filtered.footballFields = data.footballFields;
    filtered.masters = data.masters;
    filtered.workers = data.workers;
    filtered.workshops = data.workshops;
    filtered.autoMobile = data.autoMobile;
    filtered.educationCenters = data.educationCenters;
    filtered.disinfection = data.disinfection;
    filtered.appliance = data.appliance;
    filtered.couriers = data.couriers;
    filtered.nannies = data.nannies;
    filtered.tutors = data.tutors;
    filtered.nurses = data.nurses;
    filtered.dentalClinics = data.dentalClinics;
    filtered.events = data.events;
    filtered.mobileStylists = data.mobileStylists;
    filtered.genericProviders = data.genericProviders;

    return filtered;
  }
}

