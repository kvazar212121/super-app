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
import '../models/massage_hijoma.dart';
import '../models/nurse_service.dart';
import '../models/event_planning.dart';
import '../models/service_hub_kind.dart';
import '../services/hub_data_service.dart';
import '../widgets/hub_map_preview.dart';
import '../widgets/service_hub_widgets.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import 'all_categories_screen.dart';
import 'barber_booking_screen.dart';
import 'barber_map_screen.dart';
import 'salon_booking_screen.dart';
import 'master_dispatch_screen.dart';
import 'football_field_booking_screen.dart';
import 'universal_booking_screen.dart';
import 'disinfection_booking_screen.dart';
import 'appliance_booking_screen.dart';
import 'courier_booking_screen.dart';
import 'massage_booking_screen.dart';
import 'nurse_booking_screen.dart';
import 'event_booking_screen.dart';

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
      case ServiceHubKind.usta:
      case ServiceHubKind.elektrik:
      case ServiceHubKind.santexnik:
      case ServiceHubKind.tozalash:
      case ServiceHubKind.avtoYordam:
      case ServiceHubKind.konditsioner:
      case ServiceHubKind.enaga:
      case ServiceHubKind.repetitor:
        final specialty = kind == ServiceHubKind.elektrik 
            ? 'Elektrik' 
            : (kind == ServiceHubKind.santexnik 
                ? 'Santexnik' 
                : (kind == ServiceHubKind.tozalash 
                    ? 'Tozalash' 
                    : (kind == ServiceHubKind.avtoYordam 
                        ? 'Avto-yordam' 
                        : (kind == ServiceHubKind.konditsioner 
                            ? 'Konditsioner' 
                            : (kind == ServiceHubKind.enaga 
                                ? 'Enaga' 
                                : (kind == ServiceHubKind.repetitor ? 'Repetitor' : null))))));
        final filteredMasters = specialty != null 
            ? data.masters.where((m) => m.specialty == specialty).toList() 
            : data.masters;
            
        markers.addAll(filteredMasters.map((master) => Marker(
          point: LatLng(master.latitude, master.longitude),
          child: _MapPin(
            icon: LucideIcons.wrench,
            color: accentColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDispatchScreen(master: master))),
          ),
        )));

        // Add physical workshops for auto/master or education centers
        if (kind == ServiceHubKind.avtoYordam || kind == ServiceHubKind.usta) {
          markers.addAll(data.workshops.map((ws) => Marker(
            point: LatLng(ws.latitude, ws.longitude),
            child: _MapPin(
              icon: LucideIcons.home,
              color: const Color(0xFF334155),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ws.name} ustaxonasi'))),
            ),
          )));
        } else if (kind == ServiceHubKind.repetitor) {
          markers.addAll(data.educationCenters.map((ec) => Marker(
            point: LatLng(ec.latitude, ec.longitude),
            child: _MapPin(
              icon: LucideIcons.graduationCap,
              color: const Color(0xFF6366F1),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ec.name} o‘quv markazi'))),
            ),
          )));
        }
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
        if (kind == ServiceHubKind.sartarosh) _buildSection(context, "Yaqin sartaroshxonalar", data.barberShops.map((s) => ShopSmallCard(shop: s, accentColor: accentColor)).toList()),
        if (kind == ServiceHubKind.salon) _buildSection(context, "Yaqin salonlar", data.salons.map((s) => SalonSmallCard(salon: s)).toList()),
        if (kind == ServiceHubKind.futbol) _buildSection(context, "Yaqin futbol maydonlari", data.footballFields.map((f) => FieldSmallCard(field: f)).toList()),
        if (kind == ServiceHubKind.usta || kind == ServiceHubKind.elektrik || kind == ServiceHubKind.santexnik || kind == ServiceHubKind.tozalash || kind == ServiceHubKind.avtoYordam || kind == ServiceHubKind.konditsioner || kind == ServiceHubKind.enaga || kind == ServiceHubKind.repetitor) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "Yaqin mutaxassislar va jamoalar",
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
              itemCount: _filteredMasters().length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => MasterSmallCard(master: _filteredMasters()[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (kind == ServiceHubKind.repetitor) ...[
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
        
        if (kind == ServiceHubKind.avtoYordam || kind == ServiceHubKind.usta) ...[
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
        if (kind == ServiceHubKind.kuryerlik) _buildSection(context, "Kuryer xizmatlari", data.couriers.map((s) => CourierSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.massajHijoma) _buildSection(context, "Massaj va Hijoma", data.massage.map((s) => MassageSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.hamshira) _buildSection(context, "Hamshira xizmatlari", data.nurses.map((s) => NurseSmallCard(service: s)).toList()),
        if (kind == ServiceHubKind.tadbirlar) _buildSection(context, "Tadbir tashkilotchilar", data.events.map((s) => EventSmallCard(service: s)).toList()),
        
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
    if (kind == ServiceHubKind.avtoYordam) {
      return data.masters.where((m) => m.specialty == 'Avto-yordam' || m.specialty == "Ko'chirish").toList();
    }
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

    return switch (kind) {
      ServiceHubKind.sartarosh => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan joylar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.home, 'Sartaroshni uyga chaqirish', 'Premium xizmat', () => toast('Uyga chaqirish — tez orada')),
      ],
      ServiceHubKind.salon => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan joylar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.sparkles, 'Kosmetik xizmatlar', 'Manikyur, fen...', () => toast('Kosmetik — tez orada')),
      ],
      ServiceHubKind.futbol => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan polyalar', 'Tez orada', () => toast('Saqlangan polyalar — tez orada')),
        _HubActionSpec(LucideIcons.users, 'Jamoa o‘yini', 'Bir necha soat bandlov', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.elektrik => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan elektriklar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.zap, 'Favqulodda yordam', 'Qisqa tutashuv va h.k.', () => toast('SOS — tez orada')),
      ],
      ServiceHubKind.santexnik => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan santexniklar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.droplet, 'Suv oqishi', 'Tezkor bartaraf etish', () => toast('SOS — tez orada')),
      ],
      ServiceHubKind.tozalash => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan xizmatlar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.sprayCan, 'General tozalash', 'Katta ko‘lamli ishlar', () => toast('Tozalash — tez orada')),
      ],
      ServiceHubKind.avtoYordam => [
        _HubActionSpec(LucideIcons.car, 'Evakuator chaqirish', 'Eng yaqin texnika', () => toast('Evakuator yo‘lda — tez orada')),
        _HubActionSpec(LucideIcons.fuel, 'Benzin yetkazish', 'AI-92, AI-95 va h.k.', () => toast('Benzin buyurtma qilindi — tez orada')),
        _HubActionSpec(LucideIcons.wrench, 'Joyida ta’mirlash', 'Mobil usta jamoasi', () => toast('Usta jamoasi chaqirildi — tez orada')),
      ],
      ServiceHubKind.konditsioner => [
        _HubActionSpec(LucideIcons.wind, 'Profilaktika xizmati', 'Tozalash va tekshirish', () => toast('Profilaktika — tez orada')),
        _HubActionSpec(LucideIcons.snowflake, 'Freon quyish', 'Gaz to‘ldirish xizmati', () => toast('Gaz quyish — tez orada')),
      ],
      ServiceHubKind.enaga => [
        _HubActionSpec(LucideIcons.clock, 'Soatbay enaga', 'Bir necha soatga qarash', () => toast('Soatbay — tez orada')),
        _HubActionSpec(LucideIcons.home, 'Doimiy enaga', 'Haftalik yoki oylik ish', () => toast('Hiring — tez orada')),
      ],
      ServiceHubKind.repetitor => [
        _HubActionSpec(LucideIcons.bookOpen, 'Individual darslar', 'Uyga chaqirish yoki onlayn', () => toast('Repetitor — tez orada')),
        _HubActionSpec(LucideIcons.graduationCap, 'O‘quv markazlari', 'Guruh darslari va kurslar', () => toast('Markazlar — tez orada')),
      ],
      ServiceHubKind.ishchi => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan ustalar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.package, 'Yuk ko‘tarish', 'Kunlik yordamchi', () => toast('Yuk xizmati — tez orada')),
      ],
      ServiceHubKind.usta => [
        _HubActionSpec(LucideIcons.bookmark, 'Saqlangan ustalar', 'Tez orada', () => toast('Saqlanganlar — tez orada')),
        _HubActionSpec(LucideIcons.hammer, 'Uy-rozgor tamirlash', 'Mebel, eshik...', () => toast('Tamirlash — tez orada')),
      ],
      // 6 ta YANGI:
      ServiceHubKind.dezinfeksiya => [
        _HubActionSpec(LucideIcons.shieldCheck, 'Uy dezinfeksiyasi', 'Kvartira, ofis, maktab', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.car, 'Mashina dezinfeksiyasi', 'Antibakterial ishlov', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.texnikaUstasi => [
        _HubActionSpec(LucideIcons.monitor, 'Texnika tamlash', 'Kir yuvish, muzlatgich, TV', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.wrench, 'Diagnostika', 'Muammoni aniqlash', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.kuryerlik => [
        _HubActionSpec(LucideIcons.bike, 'Tezkor yetkazish', 'Hujjat, sovga', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.package, 'Yuk yetkazish', 'Kichik va katta yuk', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.massajHijoma => [
        _HubActionSpec(LucideIcons.hand, 'Massaj', 'Klassik, Tailand, Sport', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.heart, 'Hijoma', 'Erkaklar va Ayollar', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.hamshira => [
        _HubActionSpec(LucideIcons.heartPulse, 'Uyga hamshira', 'In`ektsiya, tahlil, tomchi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.clock, 'Tun bo`yi hamshira', '24 soat kuzatuv', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
      ],
      ServiceHubKind.tadbirlar => [
        _HubActionSpec(LucideIcons.partyPopper, 'To\'y va marosim', 'Rejissyorlik xizmati', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
        _HubActionSpec(LucideIcons.mapPin, 'Dam olish joyi bron', 'Bog\'s, damlanma', () => Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalBookingScreen(kind: kind)))),
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
