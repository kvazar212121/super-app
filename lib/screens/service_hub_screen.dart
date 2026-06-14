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
      body: FutureBuilder<HubScreenData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? HubScreenData();
          return Column(
            children: [
              _MapSection(kind: widget.kind, accentColor: widget.accentColor, data: data),
              Expanded(child: _ActionList(kind: widget.kind, accentColor: widget.accentColor, data: data)),
            ],
          );
        },
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  final ServiceHubKind kind;
  final Color accentColor;
  final HubScreenData data;

  const _MapSection({required this.kind, required this.accentColor, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: HubMapPreview(
        center: const LatLng(41.311081, 69.240562),
        zoom: 13,
        markers: _buildMarkers(context),
        onExpand: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BarberMapScreen(shops: data.barberShops)),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: const LatLng(41.311081, 69.240562),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    ];

    switch (kind) {
      case ServiceHubKind.sartarosh:
        markers.addAll(data.barberShops.map((shop) => Marker(
          point: LatLng(shop.latitude, shop.longitude),
          child: _MapPin(
            icon: LucideIcons.scissors,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BarberBookingScreen(shop: shop))),
          ),
        )));
        break;
      case ServiceHubKind.salon:
        markers.addAll(data.salons.map((salon) => Marker(
          point: LatLng(salon.latitude, salon.longitude),
          child: _MapPin(
            icon: LucideIcons.sparkles,
            color: const Color(0xFFE91E63),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalonBookingScreen(salon: salon))),
          ),
        )));
        break;
      case ServiceHubKind.futbol:
        markers.addAll(data.footballFields.map((field) => Marker(
          point: LatLng(field.latitude, field.longitude),
          child: _MapPin(
            icon: LucideIcons.trophy,
            color: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FootballFieldBookingScreen(field: field))),
          ),
        )));
        break;
      case ServiceHubKind.avtoYordam:
        markers.addAll(data.autoMobile.map((unit) => Marker(
          point: LatLng(unit.latitude, unit.longitude),
          child: _MapPin(
            icon: unit.vehicleType.icon,
            color: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AutoHelpBookingScreen(service: unit)),
            ),
          ),
        )));
        markers.addAll(data.workshops.map((ws) => Marker(
          point: LatLng(ws.latitude, ws.longitude),
          child: _MapPin(
            icon: LucideIcons.home,
            color: const Color(0xFF334155),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AutoWorkshopBookingScreen(workshop: ws),
              ),
            ),
          ),
        )));
        break;
      case ServiceHubKind.usta:
      case ServiceHubKind.elektrik:
      case ServiceHubKind.santexnik:
      case ServiceHubKind.tozalash:
      case ServiceHubKind.konditsioner:
        final specialty = kind == ServiceHubKind.elektrik
            ? 'Elektrik' 
            : (kind == ServiceHubKind.santexnik 
                ? 'Santexnik' 
                : (kind == ServiceHubKind.tozalash 
                    ? 'Tozalash' 
                    : (kind == ServiceHubKind.konditsioner 
                        ? 'Konditsioner' 
                        : null)));
        final filteredMasters = specialty != null 
            ? data.masters.where((m) => m.specialty == specialty).toList() 
            : data.masters;
            
        markers.addAll(filteredMasters.map((master) => Marker(
          point: LatLng(master.latitude, master.longitude),
          child: _MapPin(
            icon: kind == ServiceHubKind.tozalash
                ? LucideIcons.sprayCan
                : (kind == ServiceHubKind.usta
                    ? LucideIcons.hammer
                    : (kind == ServiceHubKind.elektrik
                        ? LucideIcons.zap
                        : (kind == ServiceHubKind.santexnik
                            ? LucideIcons.droplet
                            : (kind == ServiceHubKind.konditsioner
                                ? LucideIcons.wind
                                : LucideIcons.wrench)))),
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderProfileScreen(master: master, category: kind))),
          ),
        )));

        // Add physical workshops for usta or education centers
        if (kind == ServiceHubKind.usta) {
          markers.addAll(data.workshops.map((ws) => Marker(
            point: LatLng(ws.latitude, ws.longitude),
            child: _MapPin(
              icon: LucideIcons.home,
              color: const Color(0xFF334155),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ws.name} ustaxonasi'))),
            ),
          )));
        }
        break;
      case ServiceHubKind.repetitor:
        markers.addAll(data.tutors.map((t) => Marker(
          point: LatLng(t.latitude, t.longitude),
          child: _MapPin(
            icon: LucideIcons.bookOpen,
            color: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: t)),
            ),
          ),
        )));
        markers.addAll(data.educationCenters.map((ec) => Marker(
          point: LatLng(ec.latitude, ec.longitude),
          child: _MapPin(
            icon: LucideIcons.graduationCap,
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EducationCenterBookingScreen(center: ec),
              ),
            ),
          ),
        )));
        break;
      case ServiceHubKind.enaga:
        markers.addAll(data.nannies.map((n) => Marker(
          point: LatLng(n.latitude, n.longitude),
          child: _MapPin(
            icon: LucideIcons.baby,
            color: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NannyProfileScreen(nanny: n)),
            ),
          ),
        )));
        break;
      case ServiceHubKind.ishchi:
        markers.addAll(data.workers.map((worker) => Marker(
          point: LatLng(worker.latitude, worker.longitude),
          child: _MapPin(
            icon: LucideIcons.users,
            color: Colors.orange[800]!,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${worker.name} chaqirilmoqda...'))),
          ),
        )));
        break;
      // 6 ta YANGI:
      case ServiceHubKind.dezinfeksiya:
        markers.addAll(data.disinfection.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.shieldCheck,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisinfectionBookingScreen(service: s))),
          ),
        )));
        break;
      case ServiceHubKind.texnikaUstasi:
        markers.addAll(data.appliance.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.monitor,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplianceBookingScreen(service: s))),
          ),
        )));
        break;
      case ServiceHubKind.kuryerlik:
        markers.addAll(data.couriers.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.bike,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourierBookingScreen(service: s))),
          ),
        )));
        break;
      case ServiceHubKind.massajHijoma:
        markers.addAll(data.massage.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.hand,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MassageBookingScreen(service: s))),
          ),
        )));
        break;
      case ServiceHubKind.hamshira:
        markers.addAll(data.nurses.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.heartPulse,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NurseBookingScreen(service: s))),
          ),
        )));
        break;
      case ServiceHubKind.stomatologiya:
        markers.addAll(data.dentalClinics.map((c) => Marker(
          point: LatLng(c.latitude, c.longitude),
          child: _MapPin(
            icon: LucideIcons.smile,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DentalBookingScreen(clinic: c))),
          ),
        )));
        break;
      case ServiceHubKind.tadbirlar:
        markers.addAll(data.events.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.partyPopper,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventBookingScreen(service: s))),
          ),
        )));
        break;
      case ServiceHubKind.bozorchi:
        markers.addAll(data.masters.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.shoppingCart,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: ServiceHubKind.bozorchi))),
          ),
        )));
        break;
      case ServiceHubKind.oshxona:
        markers.addAll(data.masters.map((s) => Marker(
          point: LatLng(s.latitude, s.longitude),
          child: _MapPin(
            icon: LucideIcons.utensils,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: ServiceHubKind.oshxona))),
          ),
        )));
        break;
      case ServiceHubKind.gameZona:
      case ServiceHubKind.sportMaydon:
      case ServiceHubKind.bozorchi:
      case ServiceHubKind.oshxona:
      case ServiceHubKind.kompUsta:
      case ServiceHubKind.boshqa:
        markers.addAll(data.genericProviders.map((p) => Marker(
          point: LatLng(p['lat'] as double? ?? 41.31, p['lng'] as double? ?? 69.24),
          child: _MapPin(
            icon: kind.icon,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SimpleCallBookingScreen(kind: kind, provider: p, accentColor: accentColor))),
          ),
        )));
        break;
      default: break;
    }
    return markers;
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MapPin({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final ServiceHubKind kind;
  final Color accentColor;
  final HubScreenData data;

  const _ActionList({required this.kind, required this.accentColor, required this.data});

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (kind == ServiceHubKind.sartarosh) ...[
          BarberHubSection(shops: data.barberShops, accentColor: accentColor),
          MobileBarberHubSection(barbers: data.mobileBarbers, accentColor: accentColor),
        ],
        if (kind == ServiceHubKind.salon) ...[
          SalonHubSection(salons: data.salons, accentColor: accentColor),
          MobileSalonHubSection(stylists: data.mobileStylists, accentColor: accentColor),
        ],
        if (kind == ServiceHubKind.futbol)
          FootballHubSection(fields: data.footballFields, accentColor: accentColor),
        if (kind == ServiceHubKind.tozalash)
          CleaningHubSection(cleaners: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.usta)
          MasterDispatchHubSection(masters: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.elektrik)
          ElectricianHubSection(electricians: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.santexnik)
          PlumberHubSection(plumbers: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.konditsioner)
          AcHubSection(technicians: data.masters, accentColor: accentColor),
        if (kind == ServiceHubKind.enaga)
          NannyHubSection(nannies: data.nannies, accentColor: accentColor),
        if (kind == ServiceHubKind.kuryerlik)
          CourierHubSection(couriers: data.couriers, accentColor: accentColor),
        if (kind == ServiceHubKind.avtoYordam)
          AutoHelpHubSection(units: data.autoMobile, accentColor: accentColor),
        if (kind == ServiceHubKind.avtoYordam)
          AutoWorkshopHubSection(workshops: data.workshops, accentColor: accentColor),
        if (kind == ServiceHubKind.repetitor) ...[
          TutorHubSection(tutors: data.tutors, accentColor: accentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Yaqin o'quv markazlari",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
            ),
          ),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: data.educationCenters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => EducationCenterSmallCard(center: data.educationCenters[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (kind == ServiceHubKind.usta) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Yaqin ustaxonalar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
            ),
          ),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: data.workshops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => WorkshopSmallCard(workshop: data.workshops[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (kind == ServiceHubKind.ishchi) _buildSection(context, "Yaqin ishchilar", data.workers.map((w) => WorkerSmallCard(worker: w)).toList()),
        if (kind == ServiceHubKind.dezinfeksiya) _buildSection(context, "Dezinfeksiya xizmatlari", data.disinfection.map((s) => DisinfectionSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.texnikaUstasi) _buildSection(context, "Texnika ustalari", data.appliance.map((s) => ApplianceSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.massajHijoma) _buildSection(context, "Massaj va Hijoma", data.massage.map((s) => MassageSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.hamshira) _buildSection(context, "Hamshira xizmatlari", data.nurses.map((s) => NurseSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.stomatologiya) _buildSection(context, "Stomatologiya klinikalari", data.dentalClinics.map((c) => DentalSmallCard(clinic: c)).toList()),
        if (kind == ServiceHubKind.tadbirlar) _buildSection(context, "Tadbir tashkilotchilar", data.events.map((s) => EventSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.bozorchi) _buildSection(context, "Bozorchi va kuryerlar", data.masters.map((m) => MasterSmallCard(master: m)).toList()),
        if (kind == ServiceHubKind.oshxona) _buildSection(context, "Oshxona va Restoranlar", data.masters.map((m) => MasterSmallCard(master: m)).toList()),
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: actions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HubActionCard(title: a.title, subtitle: a.subtitle, icon: a.icon, accentColor: accentColor, onTap: a.onTap),
            )).toList(),
          ),
        ),
      ],
    );
  }

  List<Master> _filteredMasters() {
    if (kind == ServiceHubKind.usta) return data.masters;
    final specialty = switch (kind) {
      ServiceHubKind.elektrik => 'Elektrik',
      ServiceHubKind.santexnik => 'Santexnik',
      ServiceHubKind.tozalash => 'Tozalash',
      ServiceHubKind.konditsioner => 'Konditsioner',
      ServiceHubKind.enaga => 'Enaga',
      ServiceHubKind.repetitor => 'Repetitor',
      _ => null,
    };
    if (specialty != null) {
      return data.masters.where((m) => m.specialty == specialty).toList();
    }
    return data.masters;
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GlassTokens.primaryText(context),
            ),
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => items[i],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<_HubActionSpec> _actions(BuildContext context) {
    void toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    void openEvent({OrganizerServiceType? organizer, EventType? eventType}) {
      if (data.events.isEmpty) {
        toast('Tadbir guruhlari tez orada qo\'shiladi.');
        return;
      }
      EventPlanning target = data.events.first;
      if (organizer != null) {
        target = data.events.firstWhere(
          (s) => s.organizerTypes.contains(organizer),
          orElse: () => data.events.first,
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventBookingScreen(
            service: target,
            initialOrganizerType: organizer,
            initialEventType: eventType,
          ),
        ),
      );
    }

    void openNurse(MedicalService? medical) {
      if (data.nurses.isEmpty) {
        toast('Hamshira xizmatlari tez orada qo\'shiladi.');
        return;
      }
      final target = medical == null
          ? data.nurses.first
          : data.nurses.firstWhere(
              (s) => s.medicalServices.contains(medical),
              orElse: () => data.nurses.first,
            );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NurseBookingScreen(
            service: target,
            initialMedicalService: medical,
          ),
        ),
      );
    }

    void openMobileBarbers() {
      if (data.mobileBarbers.isEmpty) {
        toast('Hozircha mobil sartaroshlar yo\'q. Tez orada qo\'shiladi.');
        return;
      }
      if (data.mobileBarbers.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.mobileBarbers.first,
              category: ServiceHubKind.sartarosh,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Mobil sartarosh tanlang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...data.mobileBarbers.map((b) => ListTile(
                    leading: const Icon(LucideIcons.scissors),
                    title: Text(b.name),
                    subtitle: Text(b.serviceArea ?? 'Uyga xizmat'),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderProfileScreen(
                            master: b,
                            category: ServiceHubKind.sartarosh,
                          ),
                        ),
                      );
                    },
                  )),
            ],
          ),
        ),
      );
    }

    void openCleaningTeams() {
      final teams = data.masters.where((m) => m.isCleaningTeam).toList();
      if (teams.isEmpty) {
        if (data.masters.isEmpty) {
          toast('Hozircha tozalash xizmatlari yo\'q.');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.masters.first,
              category: ServiceHubKind.tozalash,
            ),
          ),
        );
        return;
      }
      if (teams.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: teams.first,
              category: ServiceHubKind.tozalash,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('General tozalash jamoasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...teams.map((m) => ListTile(
                leading: const Icon(LucideIcons.users),
                title: Text(m.name),
                subtitle: Text(m.teamSize != null ? '${m.teamSize} kishilik jamoa' : 'Tozalash jamoasi'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: m,
                        category: ServiceHubKind.tozalash,
                      ),
                    ),
                  );
                },
              )),
            ],
          ),
        ),
      );
    }

    void openMasterBrigades() {
      final brigades = data.masters.where((m) => m.isMasterBrigade).toList();
      if (brigades.isEmpty) {
        if (data.masters.isEmpty) {
          toast('Hozircha ustalar yo\'q.');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.masters.first,
              category: ServiceHubKind.usta,
            ),
          ),
        );
        return;
      }
      if (brigades.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: brigades.first,
              category: ServiceHubKind.usta,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Ustalar brigadasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...brigades.map((m) => ListTile(
                leading: const Icon(LucideIcons.users),
                title: Text(m.name),
                subtitle: Text(m.teamSize != null ? '${m.teamSize} kishilik brigada' : 'Ustalar brigadasi'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: m,
                        category: ServiceHubKind.usta,
                      ),
                    ),
                  );
                },
              )),
            ],
          ),
        ),
      );
    }

    void openMobileStylists() {
      if (data.mobileStylists.isEmpty) {
        toast('Hozircha mobil kosmetologlar yo\'q. Tez orada qo\'shiladi.');
        return;
      }
      if (data.mobileStylists.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              master: data.mobileStylists.first,
              category: ServiceHubKind.salon,
            ),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Mobil kosmetolog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...data.mobileStylists.map((s) => ListTile(
                leading: const Icon(LucideIcons.sparkles),
                title: Text(s.name),
                subtitle: Text(s.serviceArea ?? 'Uyga xizmat'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: s,
                        category: ServiceHubKind.salon,
                      ),
                    ),
                  );
                },
              )),
            ],
          ),
        ),
      );
    }

    return switch (kind) {
      ServiceHubKind.sartarosh => [
        _HubActionSpec(LucideIcons.home, 'Sartaroshni uyga chaqirish', 'Vaqt belgilab bron qiling', openMobileBarbers),
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan joylar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
      ],
      ServiceHubKind.salon => [
        _HubActionSpec(LucideIcons.home, 'Kosmetologni uyga chaqirish', 'Fen, manikyur, makiyaj', openMobileStylists),
        _HubActionSpec(LucideIcons.sparkles, 'Salonda xizmat', 'Yaqin salonlardan tanlang', () {
          if (data.salons.isEmpty) {
            toast('Salonlar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SalonBookingScreen(salon: data.salons.first)),
          );
        }),
      ],
      ServiceHubKind.bozorchi => [
        _HubActionSpec(LucideIcons.shoppingCart, 'Kuryer orqali xarid', 'Oziq-ovqat yetkazib berish', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversalBookingScreen(kind: ServiceHubKind.bozorchi)));
        }),
      ],
      ServiceHubKind.oshxona => [
        _HubActionSpec(LucideIcons.utensils, 'Stol bron qilish', 'Oshxonadan joy band qilish', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversalBookingScreen(kind: ServiceHubKind.oshxona)));
        }),
      ],
      ServiceHubKind.futbol => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan polyalar', 'Tez orada', () => toast('Saqlangan polyalar — tez orada')),
        _HubActionSpec(LucideIcons.users, 'Jamoa o‘yini', 'Bir necha soat bandlov', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.elektrik => [
        _HubActionSpec(LucideIcons.zap, 'Elektrikni chaqirish', 'Uyga boradigan usta', () {
          if (data.masters.isEmpty) {
            toast('Elektriklar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(
                master: data.masters.first,
                category: ServiceHubKind.elektrik,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.alertTriangle, 'Favqulodda yordam', 'Shoshilinch chaqiruv', () {
          final urgent = data.masters.where((m) =>
              m.services.any((s) => s.toLowerCase().contains('shoshil'))).toList();
          final target = urgent.isNotEmpty ? urgent.first : (data.masters.isNotEmpty ? data.masters.first : null);
          if (target == null) {
            toast('Elektriklar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(master: target, category: ServiceHubKind.elektrik),
            ),
          );
        }),
      ],
      ServiceHubKind.santexnik => [
        _HubActionSpec(LucideIcons.droplet, 'Santexnikni chaqirish', 'Uyga boradigan usta', () {
          if (data.masters.isEmpty) {
            toast('Santexniklar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(
                master: data.masters.first,
                category: ServiceHubKind.santexnik,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.alertTriangle, 'Suv oqishi / favqulodda', 'Shoshilinch chaqiruv', () {
          final urgent = data.masters.where((m) =>
              m.services.any((s) => s.toLowerCase().contains('shoshil'))).toList();
          final target = urgent.isNotEmpty ? urgent.first : (data.masters.isNotEmpty ? data.masters.first : null);
          if (target == null) {
            toast('Santexniklar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(master: target, category: ServiceHubKind.santexnik),
            ),
          );
        }),
      ],
      ServiceHubKind.tozalash => [
        _HubActionSpec(LucideIcons.user, 'Yakka tozalovchi', '1–2 xonali kvartira', () {
          final solo = data.masters.where((m) => m.isCleaningSolo).toList();
          if (solo.isEmpty) {
            toast('Yakka tozalovchilar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(
                master: solo.first,
                category: ServiceHubKind.tozalash,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.sprayCan, 'General tozalash', 'Katta ko‘lamli ishlar — jamoa', openCleaningTeams),
      ],
      ServiceHubKind.avtoYordam => [
        _HubActionSpec(LucideIcons.truck, 'Evakuator chaqirish', 'Mashinani ko\'chirish', () {
          final units = data.autoMobile.where((u) => u.offersService('evak')).toList();
          final target = units.isNotEmpty ? units.first : (data.autoMobile.isNotEmpty ? data.autoMobile.first : null);
          if (target == null) {
            toast('Mobil avto-yordam tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutoHelpBookingScreen(service: target, preselectedService: 'Evakuator'),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.fuel, 'Benzin yetkazish', 'AI-92, AI-95 (10L)', () {
          final units = data.autoMobile.where((u) => u.offersService('benzin')).toList();
          final target = units.isNotEmpty ? units.first : (data.autoMobile.isNotEmpty ? data.autoMobile.first : null);
          if (target == null) {
            toast('Benzin yetkazish tez orada qo\'shiladi.');
            return;
          }
          final fuelService = target.services.firstWhere(
            (s) => s.toLowerCase().contains('benzin'),
            orElse: () => target.services.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutoHelpBookingScreen(service: target, preselectedService: fuelService),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.wrench, 'Joyida ta\'mirlash', 'Yo\'lda muammoni bartaraf etish', () {
          final units = data.autoMobile.where((u) => u.offersService('ta\'mir') || u.offersService('tamir')).toList();
          final target = units.isNotEmpty ? units.first : (data.autoMobile.isNotEmpty ? data.autoMobile.first : null);
          if (target == null) {
            toast('Mobil usta tez orada qo\'shiladi.');
            return;
          }
          final repairService = target.services.firstWhere(
            (s) => s.toLowerCase().contains('ta\'mir') || s.toLowerCase().contains('tamir'),
            orElse: () => target.services.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutoHelpBookingScreen(service: target, preselectedService: repairService),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.home, 'Ustaxona bron qilish', 'Diagnostika, remont, shinopompa', () {
          if (data.workshops.isEmpty) {
            toast('Ustaxonalar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutoWorkshopBookingScreen(workshop: data.workshops.first),
            ),
          );
        }),
      ],
      ServiceHubKind.konditsioner => [
        _HubActionSpec(LucideIcons.wind, 'Profilaktika xizmati', 'Tozalash va tekshirish', () {
          if (data.masters.isEmpty) {
            toast('Konditsioner ustalar tez orada qo\'shiladi.');
            return;
          }
          final target = data.masters.firstWhere(
            (m) => m.services.any((s) => s.toLowerCase().contains('profil') || s.toLowerCase().contains('tozal')),
            orElse: () => data.masters.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(master: target, category: ServiceHubKind.konditsioner),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.snowflake, 'Freon / gaz quyish', 'Gaz to\'ldirish xizmati', () {
          if (data.masters.isEmpty) {
            toast('Konditsioner ustalar tez orada qo\'shiladi.');
            return;
          }
          final target = data.masters.firstWhere(
            (m) => m.services.any((s) =>
                s.toLowerCase().contains('gaz') ||
                s.toLowerCase().contains('freon') ||
                s.toLowerCase().contains('toldir')),
            orElse: () => data.masters.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(master: target, category: ServiceHubKind.konditsioner),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.settings, 'Montaj / demontaj', 'Konditsioner o\'rnatish', () {
          if (data.masters.isEmpty) {
            toast('Konditsioner ustalar tez orada qo\'shiladi.');
            return;
          }
          final target = data.masters.firstWhere(
            (m) => m.services.any((s) => s.toLowerCase().contains('montaj')),
            orElse: () => data.masters.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(master: target, category: ServiceHubKind.konditsioner),
            ),
          );
        }),
      ],
      ServiceHubKind.enaga => [
        _HubActionSpec(LucideIcons.clock, 'Soatbay enaga', 'Bir necha soatga qarash', () {
          if (data.nannies.isEmpty) {
            toast('Enagalar tez orada qo\'shiladi.');
            return;
          }
          final hourly = data.nannies.where((n) =>
              n.serviceTypes.contains(nanny_model.NannyServiceType.hourly) ||
              n.services.any((s) => s.toLowerCase().contains('soat'))).toList();
          final target = hourly.isNotEmpty ? hourly.first : data.nannies.first;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NannyProfileScreen(
                nanny: target,
                preselectedType: nanny_model.NannyServiceType.hourly,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.home, 'Doimiy enaga', 'Haftalik yoki oylik ish', () {
          if (data.nannies.isEmpty) {
            toast('Enagalar tez orada qo\'shiladi.');
            return;
          }
          final permanent = data.nannies.where((n) =>
              n.serviceTypes.contains(nanny_model.NannyServiceType.weekly) ||
              n.serviceTypes.contains(nanny_model.NannyServiceType.monthly) ||
              n.services.any((s) => s.toLowerCase().contains('hafta') || s.toLowerCase().contains('oylik'))).toList();
          final target = permanent.isNotEmpty ? permanent.first : data.nannies.first;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NannyProfileScreen(
                nanny: target,
                preselectedType: nanny_model.NannyServiceType.weekly,
              ),
            ),
          );
        }),
      ],
      ServiceHubKind.repetitor => [
        _HubActionSpec(LucideIcons.bookOpen, 'Individual darslar', 'Uyga chaqirish yoki onlayn', () {
          if (data.tutors.isEmpty) {
            toast('Repetitorlar tez orada qo\'shiladi.');
            return;
          }
          final online = data.tutors.where((t) => t.supportsOnline).toList();
          final target = online.isNotEmpty ? online.first : data.tutors.first;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: target)),
          );
        }),
        _HubActionSpec(LucideIcons.graduationCap, 'O‘quv markazlari', 'Guruh darslari va kurslar', () {
          if (data.educationCenters.isEmpty) {
            toast('O\'quv markazlari tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationCenterBookingScreen(center: data.educationCenters.first),
            ),
          );
        }),
      ],
      ServiceHubKind.ishchi => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan ustalar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.package, 'Yuk ko‘tarish', 'Kunlik yordamchi', () => toast('Yuk xizmati — tez orada')),
      ],
      ServiceHubKind.usta => [
        _HubActionSpec(LucideIcons.user, 'Yakka usta', 'Kichik ta\'mirlash ishlar', () {
          final solo = data.masters.where((m) => m.isMasterSolo).toList();
          if (solo.isEmpty) {
            toast('Yakka ustalar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderProfileScreen(
                master: solo.first,
                category: ServiceHubKind.usta,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.users, 'Ustalar brigadasi', 'Katta montaj va ta\'mirlash', openMasterBrigades),
      ],
      // 6 ta YANGI:
      ServiceHubKind.dezinfeksiya => [
        _HubActionSpec(LucideIcons.shieldCheck, 'Uy dezinfeksiyasi', 'Kvartira, ofis, maktab', () {
          if (data.disinfection.isEmpty) {
            toast('Dezinfeksiya xizmatlari tez orada qo\'shiladi.');
            return;
          }
          final target = data.disinfection.firstWhere(
            (s) => s.areaTypes.contains(AreaType.apartment) || s.areaTypes.contains(AreaType.office),
            orElse: () => data.disinfection.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DisinfectionBookingScreen(
                service: target,
                initialAreaType: AreaType.apartment,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.car, 'Mashina dezinfeksiyasi', 'Antibakterial ishlov', () {
          if (data.disinfection.isEmpty) {
            toast('Dezinfeksiya xizmatlari tez orada qo\'shiladi.');
            return;
          }
          final target = data.disinfection.firstWhere(
            (s) => s.areaTypes.contains(AreaType.vehicle),
            orElse: () => data.disinfection.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DisinfectionBookingScreen(
                service: target,
                initialAreaType: AreaType.vehicle,
              ),
            ),
          );
        }),
      ],
      ServiceHubKind.texnikaUstasi => [
        _HubActionSpec(LucideIcons.monitor, 'Texnika tamlash', 'Kir yuvish, muzlatgich, TV', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.wrench, 'Diagnostika', 'Muammoni aniqlash', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.kuryerlik => [
        _HubActionSpec(LucideIcons.bike, 'Tezkor yetkazish', 'Hujjat, paket, sovga', () {
          if (data.couriers.isEmpty) {
            toast('Kuryerlar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourierBookingScreen(service: data.couriers.first),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.package, 'Yuk yetkazish', 'Katta yuk, vazn bilan', () {
          final cargo = data.couriers.where((c) =>
              c.deliveryTypes.contains(DeliveryType.cargo) ||
              c.deliveryTypes.contains(DeliveryType.package)).toList();
          final target = cargo.isNotEmpty ? cargo.first : (data.couriers.isNotEmpty ? data.couriers.first : null);
          if (target == null) {
            toast('Kuryerlar tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourierBookingScreen(service: target),
            ),
          );
        }),
      ],
      ServiceHubKind.massajHijoma => [
        _HubActionSpec(LucideIcons.home, 'Uyga chaqirish', 'Mutaxassis sizning uyingizga keladi', () {
          if (data.massage.isEmpty) {
            toast('Massaj xizmatlari tez orada qo\'shiladi.');
            return;
          }
          final target = data.massage.firstWhere(
            (s) => s.supportsHomeVisit,
            orElse: () => data.massage.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MassageBookingScreen(
                service: target,
                initialVisitMode: MassageVisitMode.homeVisit,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.building2, 'Salonga borish', 'Markazga tashrif buyuring', () {
          if (data.massage.isEmpty) {
            toast('Massaj xizmatlari tez orada qo\'shiladi.');
            return;
          }
          final target = data.massage.firstWhere(
            (s) => s.supportsAtCenter,
            orElse: () => data.massage.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MassageBookingScreen(
                service: target,
                initialVisitMode: MassageVisitMode.atCenter,
              ),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.droplets, 'Hijoma', 'An\'anaviy hijoma', () {
          if (data.massage.isEmpty) {
            toast('Hijoma xizmatlari tez orada qo\'shiladi.');
            return;
          }
          final target = data.massage.firstWhere(
            (s) => s.serviceTypes.contains(ServiceType.hijoma),
            orElse: () => data.massage.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MassageBookingScreen(service: target)),
          );
        }),
      ],
      ServiceHubKind.hamshira => [
        _HubActionSpec(LucideIcons.syringe, 'Ukol (in\'ektsiya)', 'Uyga chiqish — manzil bilan', () {
          openNurse(MedicalService.injection);
        }),
        _HubActionSpec(LucideIcons.flaskConical, 'Qon tahlili', 'Uyda olinadi', () {
          openNurse(MedicalService.bloodTest);
        }),
        _HubActionSpec(LucideIcons.droplet, 'Tomchilatma', 'Uyga hamshira chaqirish', () {
          openNurse(MedicalService.drip);
        }),
        _HubActionSpec(LucideIcons.heartPulse, 'Boshqa tibbiy xizmat', 'Yara parvarishi, EKG va boshqalar', () {
          openNurse(null);
        }),
      ],
      ServiceHubKind.stomatologiya => [
        _HubActionSpec(LucideIcons.smile, 'Klinikada qabul', 'Shifokor va vaqt tanlash', () {
          if (data.dentalClinics.isEmpty) {
            toast('Stomatologiya klinikalari tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DentalBookingScreen(clinic: data.dentalClinics.first),
            ),
          );
        }),
        _HubActionSpec(LucideIcons.calendarClock, 'Vaqt bron qilish', 'Sana va soatni tanlang', () {
          if (data.dentalClinics.isEmpty) {
            toast('Stomatologiya klinikalari tez orada qo\'shiladi.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DentalBookingScreen(clinic: data.dentalClinics.first),
            ),
          );
        }),
      ],
      ServiceHubKind.tadbirlar => [
        _HubActionSpec(LucideIcons.tent, 'Sahna o\'rnatish', 'Qishloq va ochiq maydon', () {
          openEvent(organizer: OrganizerServiceType.stageSetup);
        }),
        _HubActionSpec(LucideIcons.volume2, 'Ovoz va yoritish', 'Kolonka, lyuka, mikrofon', () {
          openEvent(organizer: OrganizerServiceType.soundLight);
        }),
        _HubActionSpec(LucideIcons.trees, 'Qishloq tadbirlari', 'Hovli, maydon, viloyat', () {
          openEvent(organizer: OrganizerServiceType.villageEvents);
        }),
        _HubActionSpec(LucideIcons.heart, 'To\'y — to\'liq tashkilot', 'Sahna, ovoz, dekor', () {
          openEvent(organizer: OrganizerServiceType.fullOrganization, eventType: EventType.wedding);
        }),
      ],
      ServiceHubKind.gameZona || ServiceHubKind.sportMaydon || ServiceHubKind.bozorchi || ServiceHubKind.oshxona || ServiceHubKind.kompUsta || ServiceHubKind.boshqa => [
        _HubActionSpec(kind.icon, '${kind.title} tanlash', 'Ro\'yxatdan kerakli joyni tanlang', () {
          if (data.genericProviders.isEmpty) {
            toast('${kind.title} hozircha mavjud emas.');
            return;
          }
          if (data.genericProviders.length == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SimpleCallBookingScreen(kind: kind, provider: data.genericProviders.first, accentColor: accentColor)));
            return;
          }
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('${kind.title} tanlang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...data.genericProviders.map((p) => ListTile(
                    leading: Icon(kind.icon, color: accentColor),
                    title: Text(p['name'] ?? 'Nomsiz'),
                    subtitle: Text(p['address'] ?? ''),
                    trailing: const Icon(LucideIcons.phoneCall, color: Colors.green),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SimpleCallBookingScreen(kind: kind, provider: p, accentColor: accentColor)));
                    },
                  )),
                ],
              ),
            ),
          );
        }),
      ],
      _ => [
        _HubActionSpec(LucideIcons.calendarCheck, '${kind.title} bron qilish', 'Variant, manzil va vaqt', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
    } + [
      _HubActionSpec(LucideIcons.layoutGrid, 'Barcha xizmatlar', 'To‘liq katalog', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllCategoriesScreen()))),
      _HubActionSpec(LucideIcons.headphones, 'Qo‘llab-quvvatlash', 'Chat yoki qo‘ng‘iroq', () => toast('Support — tez orada')),
    ];
  }
}

class _HubActionSpec {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _HubActionSpec(this.icon, this.title, this.subtitle, this.onTap);
}
