part of '../service_hub_screen.dart';

class _MapSection extends StatefulWidget {
  final ServiceHubKind kind;
  final Color accentColor;
  final HubScreenData data;

  const _MapSection({
    required this.kind,
    required this.accentColor,
    required this.data,
  });

  @override
  State<_MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<_MapSection> {
  LatLng _userLocation = const LatLng(41.311081, 69.240562);

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: HubMapPreview(
        key: ValueKey(_userLocation),
        center: _userLocation,
        zoom: 13,
        markers: _buildMarkers(context),
        onExpand: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text("Xarita".tr),
                backgroundColor: widget.accentColor,
              ),
              body: HubMapPreview(
                center: _userLocation,
                zoom: 13,
                markers: _buildMarkers(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final data = widget.data;
    final kind = widget.kind;
    final accentColor = widget.accentColor;
    final markers = <Marker>[
      Marker(
        point: _userLocation,
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white, size: 26),
          ),
        ),
      ),
    ];

    switch (widget.kind) {
      case ServiceHubKind.sartarosh:
        markers.addAll(
          data.barberShops.map(
            (shop) => Marker(
              point: LatLng(shop.latitude, shop.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.scissors,
                color: accentColor,
                label: shop.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BarberBookingScreen(shop: shop),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.salon:
        markers.addAll(
          data.salons.map(
            (salon) => Marker(
              point: LatLng(salon.latitude, salon.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.sparkles,
                color: const Color(0xFFE91E63),
                label: salon.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalonBookingScreen(salon: salon),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.futbol:
        markers.addAll(
          data.footballFields.map(
            (field) => Marker(
              point: LatLng(field.latitude, field.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.trophy,
                color: const Color(0xFF4CAF50),
                label: field.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FootballFieldBookingScreen(field: field),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.avtoYordam:
        markers.addAll(
          data.autoMobile.map(
            (unit) => Marker(
              point: LatLng(unit.latitude, unit.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: unit.vehicleType.icon,
                color: accentColor,
                label: unit.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutoMobileProfileScreen(service: unit),
                  ),
                ),
              ),
            ),
          ),
        );
        markers.addAll(
          data.workshops.map(
            (ws) => Marker(
              point: LatLng(ws.latitude, ws.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.home,
                color: const Color(0xFF334155),
                label: ws.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutoWorkshopProfileScreen(workshop: ws),
                  ),
                ),
              ),
            ),
          ),
        );
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

        markers.addAll(
          filteredMasters.map(
            (master) => Marker(
              point: LatLng(master.latitude, master.longitude),
              width: 120,
              height: 55,
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
                label: master.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProviderProfileScreen(master: master, category: kind),
                  ),
                ),
              ),
            ),
          ),
        );

        // Add physical workshops for usta or education centers
        if (kind == ServiceHubKind.usta) {
          markers.addAll(
            data.workshops.map(
              (ws) => Marker(
                point: LatLng(ws.latitude, ws.longitude),
                width: 120,
                height: 55,
                child: _MapPin(
                  icon: LucideIcons.home,
                  color: const Color(0xFF334155),
                  label: ws.name,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${ws.name} ${'ustaxonasi'.tr}')),
                  ),
                ),
              ),
            ),
          );
        }
        break;
      case ServiceHubKind.repetitor:
        markers.addAll(
          data.tutors.map(
            (t) => Marker(
              point: LatLng(t.latitude, t.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.bookOpen,
                color: accentColor,
                label: t.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TutorProfileScreen(tutor: t),
                  ),
                ),
              ),
            ),
          ),
        );
        markers.addAll(
          data.educationCenters.map(
            (ec) => Marker(
              point: LatLng(ec.latitude, ec.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.graduationCap,
                color: const Color(0xFF6366F1),
                label: ec.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EducationCenterBookingScreen(center: ec),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.enaga:
        markers.addAll(
          data.nannies.map(
            (n) => Marker(
              point: LatLng(n.latitude, n.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.baby,
                color: accentColor,
                label: n.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NannyProfileScreen(nanny: n),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.ishchi:
        markers.addAll(
          data.workers.map(
            (worker) => Marker(
              point: LatLng(worker.latitude, worker.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.users,
                color: Colors.orange[800]!,
                label: worker.name,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${worker.name} ${'chaqirilmoqda...'.tr}'),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      // 6 ta YANGI:
      case ServiceHubKind.dezinfeksiya:
        markers.addAll(
          data.disinfection.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.shieldCheck,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DisinfectionProfileScreen(service: s),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.texnikaUstasi:
        markers.addAll(
          data.appliance.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.monitor,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplianceDispatchScreen(service: s),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.kuryerlik:
        markers.addAll(
          data.couriers.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.bike,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourierDispatchScreen(service: s),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.massajHijoma:
        markers.addAll(
          data.massage.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.hand,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MassageBookingScreen(service: s),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.hamshira:
        markers.addAll(
          data.nurses.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.heartPulse,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NurseBookingScreen(service: s),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.stomatologiya:
        markers.addAll(
          data.dentalClinics.map(
            (c) => Marker(
              point: LatLng(c.latitude, c.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.smile,
                color: accentColor,
                label: c.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DentalBookingScreen(clinic: c),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.tadbirlar:
        markers.addAll(
          data.events.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.partyPopper,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventBookingScreen(service: s),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.bozorchi:
        markers.addAll(
          data.masters.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.shoppingCart,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UniversalBookingScreen(kind: ServiceHubKind.bozorchi),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.oshxona:
        markers.addAll(
          data.masters.map(
            (s) => Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: LucideIcons.utensils,
                color: accentColor,
                label: s.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UniversalBookingScreen(kind: ServiceHubKind.oshxona),
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case ServiceHubKind.gameZona:
      case ServiceHubKind.sportMaydon:
      case ServiceHubKind.bozorchi:
      case ServiceHubKind.oshxona:
      case ServiceHubKind.kompUsta:
      case ServiceHubKind.boshqa:
        markers.addAll(
          data.genericProviders.map((p) {
            double lat = 41.31;
            double lng = 69.24;
            String name = 'Xizmat'.tr;
            if (p is Map) {
              lat = p['lat'] as double? ?? 41.31;
              lng = p['lng'] as double? ?? 69.24;
              name = p['name'] as String? ?? 'Xizmat'.tr;
            } else {
              try {
                lat = p.latitude as double;
              } catch (_) {}
              try {
                lng = p.longitude as double;
              } catch (_) {}
              try {
                name = p.name as String;
              } catch (_) {}
            }
            return Marker(
              point: LatLng(lat, lng),
              width: 120,
              height: 55,
              child: _MapPin(
                icon: kind.icon,
                color: accentColor,
                label: name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SimpleCallBookingScreen(
                      kind: kind,
                      provider: p,
                      accentColor: accentColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
        break;
      default:
        break;
    }
    return markers;
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _MapPin({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
