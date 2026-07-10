import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/locale_controller.dart';
import '../utils/geo_utils.dart';

/// Xaritada ko'rsatiladigan bitta joy (provayder/xizmat).
class MapPlace {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? subtitle;
  final double? rating;
  final Object? payload; // asl model — onOpen'ga uzatiladi
  final VoidCallback? onTap; // shu joyga xos ochish amali (ixtiyoriy)

  const MapPlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.subtitle,
    this.rating,
    this.payload,
    this.onTap,
  });
}

/// Kuchaytirilgan xizmat xaritasi:
/// - O'z lokatsiyangiz (ko'k puls nuqta + aniqlik doirasi)
/// - Har provaydergacha masofa (km)
/// - Tanlaganda yo'l bo'ylab HAQIQIY marshrut (OSRM) + masofa/vaqt
/// - Avto-fokus (barcha nuqtalar bir ekranда), "meni ko'rsat" tugmasi
/// - Chiroyli rangli markerlar + zamonaviy CartoDB xarita
class EnhancedServiceMap extends StatefulWidget {
  final List<MapPlace> places;
  final Color accent;
  final IconData markerIcon;
  final String title;

  /// "Xizmatlarni ko'rish" bosilganda — asl model bilan chaqiriladi.
  final void Function(MapPlace place)? onOpen;

  const EnhancedServiceMap({
    super.key,
    required this.places,
    required this.title,
    this.accent = const Color(0xFF6366F1),
    this.markerIcon = LucideIcons.mapPin,
    this.onOpen,
  });

  @override
  State<EnhancedServiceMap> createState() => _EnhancedServiceMapState();
}

class _EnhancedServiceMapState extends State<EnhancedServiceMap>
    with SingleTickerProviderStateMixin {
  final MapController _map = MapController();
  late final AnimationController _pulse;

  LatLng? _userPos;
  MapPlace? _selected;
  List<LatLng> _route = [];
  double? _routeKm;
  int? _routeMin;
  bool _routing = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _initLocation();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    LatLng? pos;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));
          pos = LatLng(p.latitude, p.longitude);
        }
      }
    } catch (_) {}
    pos ??= const LatLng(kDefaultUserLat, kDefaultUserLng);
    if (!mounted) return;
    setState(() => _userPos = pos);
    _fitAll();
  }

  /// Barcha nuqta + foydalanuvchini ekranга sig'diradi.
  void _fitAll() {
    final pts = <LatLng>[
      if (_userPos != null) _userPos!,
      ...widget.places.map((p) => LatLng(p.lat, p.lng)),
    ];
    if (pts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (pts.length == 1) {
          _map.move(pts.first, 14);
        } else {
          _map.fitCamera(
            CameraFit.coordinates(
              coordinates: pts,
              padding: const EdgeInsets.all(60),
              maxZoom: 16,
            ),
          );
        }
      } catch (_) {}
    });
  }

  Future<void> _selectPlace(MapPlace place) async {
    setState(() {
      _selected = place;
      _route = [];
      _routeKm = null;
      _routeMin = null;
    });
    _showPlaceSheet(place);
    await _buildRoute(place);
  }

  /// OSRM (bepul, kalitsiz) orqali yo'l marshrutini oladi.
  /// Xato bo'lsa — to'g'ri chiziq (fallback) chiziladi.
  Future<void> _buildRoute(MapPlace place) async {
    final user = _userPos;
    if (user == null) return;
    setState(() => _routing = true);
    final dest = LatLng(place.lat, place.lng);
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${user.longitude},${user.latitude};${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=geojson';
      final res = await Dio().get(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final routes = res.data['routes'] as List<dynamic>?;
      if (routes != null && routes.isNotEmpty) {
        final r = routes.first as Map<String, dynamic>;
        final coords = (r['geometry']['coordinates'] as List<dynamic>)
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (mounted && _selected?.id == place.id) {
          setState(() {
            _route = coords;
            _routeKm = ((r['distance'] as num) / 1000).toDouble();
            _routeMin = ((r['duration'] as num) / 60).round();
          });
        }
        return;
      }
    } catch (_) {}
    // Fallback: to'g'ri chiziq + tekis masofa
    if (mounted && _selected?.id == place.id) {
      setState(() {
        _route = [user, dest];
        _routeKm = distanceKm(user.latitude, user.longitude, place.lat, place.lng);
        _routeMin = null;
      });
    }
    if (mounted) setState(() => _routing = false);
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final tileUrl = _isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), elevation: 0),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _userPos ??
                  const LatLng(kDefaultUserLat, kDefaultUserLng),
              initialZoom: 12,
              onTap: (_, __) => _clearRoute(),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.super_app',
                fallbackUrl:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              // Marshrut chizig'i
              if (_route.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 5,
                      color: widget.accent,
                      borderStrokeWidth: 1.5,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              // Foydalanuvchi aniqlik doirasi
              if (_userPos != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userPos!,
                      radius: 260,
                      useRadiusInMeter: true,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderColor:
                          const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          // Marshrut yuklanmoqda indikatori
          if (_routing)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Marshrut qurilmoqda…'.tr,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fitAll',
            backgroundColor: Colors.white,
            foregroundColor: widget.accent,
            onPressed: _fitAll,
            child: const Icon(LucideIcons.maximize2),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'myLoc',
            backgroundColor: widget.accent,
            foregroundColor: Colors.white,
            onPressed: () {
              if (_userPos != null) _map.move(_userPos!, 15);
            },
            child: const Icon(LucideIcons.locateFixed),
          ),
        ],
      ),
    );
  }

  void _clearRoute() {
    if (_route.isEmpty && _selected == null) return;
    setState(() {
      _route = [];
      _selected = null;
      _routeKm = null;
      _routeMin = null;
    });
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Foydalanuvchi — pulsli ko'k nuqta
    if (_userPos != null) {
      markers.add(
        Marker(
          point: _userPos!,
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 20 + _pulse.value * 34,
                    height: 20 + _pulse.value * 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6)
                          .withValues(alpha: (1 - _pulse.value) * 0.4),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // Provayder markerlari
    for (final p in widget.places) {
      final selected = _selected?.id == p.id;
      final km = _userPos == null
          ? null
          : distanceKm(_userPos!.latitude, _userPos!.longitude, p.lat, p.lng);
      markers.add(
        Marker(
          point: LatLng(p.lat, p.lng),
          width: 130,
          height: 74,
          child: GestureDetector(
            onTap: () => _selectPlace(p),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Masofa yorlig'i
                if (km != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? widget.accent : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      formatDistanceKm(km),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                // Pin
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? widget.accent : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.4),
                        blurRadius: selected ? 12 : 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.markerIcon,
                    size: selected ? 22 : 18,
                    color: selected ? Colors.white : widget.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _showPlaceSheet(MapPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            // Sheet ochilgach marshrut kelganда yangilash uchun kichik poll
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.markerIcon, color: widget.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (place.subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  place.subtitle!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (place.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(
                              ' ${place.rating!.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Masofa / vaqt chiplari (marshrut kelganда yangilanadi)
                  Builder(builder: (_) {
                    final km = _routeKm;
                    final min = _routeMin;
                    return Row(
                      children: [
                        _chip(LucideIcons.route,
                            km != null ? formatDistanceKm(km) : '…'),
                        const SizedBox(width: 10),
                        if (min != null)
                          _chip(LucideIcons.clock, '$min ${'daqiqa'.tr}'),
                      ],
                    );
                  }),
                  const SizedBox(height: 18),
                  if (widget.onOpen != null || place.onTap != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (place.onTap != null) {
                            place.onTap!();
                          } else {
                            widget.onOpen!(place);
                          }
                        },
                        icon: const Icon(LucideIcons.arrowRight),
                        label: Text('Xizmatlarni ko\'rish'.tr),
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.accent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Sheet yopilganда tanlovni saqlaymiz (marshrut ko'rinib turadi)
    });
    // Marshrut kelganда sheet ichidagi chiplarni yangilash uchun qayta ochish shart emas —
    // foydalanuvchi sheetни yopib xaritada marshrutни ko'radi.
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: widget.accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: widget.accent,
            ),
          ),
        ],
      ),
    );
  }
}
