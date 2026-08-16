import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/hub/hub_filter_chips.dart';
import '../../widgets/hub/provider_map_preview_card.dart';
import 'service_catalog_screen.dart';

/// EKRAN 2 — to'liq ekranli xizmat xaritasi.
///
/// Ro'yxat ekranidagi ("xaritadan" tugmasi) bilan BIR XIL ma'lumot manbaidan
/// ([CatalogEntry]) ishlaydi. Marker bosilganda tepada provayder preview
/// kartasi chiqadi — undan to'g'ridan-to'g'ri buyurtmaga o'tiladi.
class ServiceMapScreen extends StatefulWidget {
  final String title;
  final Color accent;
  final IconData markerIcon;
  final List<CatalogEntry> entries;

  /// Filtr modali uchun (ro'yxat ekrani bilan bir xil holat).
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;
  final HubListFilter sortFilter;
  final ValueChanged<HubListFilter>? onSortChanged;

  const ServiceMapScreen({
    super.key,
    required this.title,
    required this.entries,
    this.accent = const Color(0xFF2563EB),
    this.markerIcon = LucideIcons.mapPin,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
    this.sortFilter = HubListFilter.all,
    this.onSortChanged,
  });

  @override
  State<ServiceMapScreen> createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends State<ServiceMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _map = MapController();
  late final AnimationController _pulse;

  LatLng? _userPos;
  CatalogEntry? _selected;
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
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          ).timeout(const Duration(seconds: 9));
          pos = LatLng(p.latitude, p.longitude);
        }
      }
    } catch (_) {}
    pos ??= const LatLng(kDefaultUserLat, kDefaultUserLng);
    if (!mounted) return;
    setState(() => _userPos = pos);
    _fitAll();
  }

  /// Barcha nuqta + foydalanuvchini ekranga sig'diradi.
  void _fitAll() {
    final pts = <LatLng>[
      ?_userPos,
      ...widget.entries.map((e) => LatLng(e.latitude, e.longitude)),
    ];
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _map.move(pts.first, 14);
      return;
    }
    try {
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: pts,
          padding: const EdgeInsets.fromLTRB(50, 190, 50, 130),
          maxZoom: 15,
        ),
      );
    } catch (_) {}
  }

  Future<void> _selectEntry(CatalogEntry entry) async {
    setState(() {
      _selected = entry;
      _route = [];
      _routeKm = null;
      _routeMin = null;
    });
    _map.move(LatLng(entry.latitude, entry.longitude), 15);
    await _buildRoute(entry);
  }

  /// OSRM orqali haqiqiy marshrut. Xato bo'lsa to'g'ri chiziq.
  Future<void> _buildRoute(CatalogEntry entry) async {
    final user = _userPos;
    if (user == null) return;
    final dest = LatLng(entry.latitude, entry.longitude);
    setState(() => _routing = true);
    try {
      final res = await Dio().get<Map<String, dynamic>>(
        'https://router.project-osrm.org/route/v1/driving/'
        '${user.longitude},${user.latitude};${dest.longitude},${dest.latitude}',
        queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final routes = res.data?['routes'] as List<dynamic>?;
      if (routes != null && routes.isNotEmpty) {
        final r = routes.first as Map<String, dynamic>;
        final coords =
            (r['geometry']?['coordinates'] as List<dynamic>?) ?? const [];
        final pts = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (mounted && _selected?.id == entry.id) {
          setState(() {
            _route = pts;
            _routeKm = ((r['distance'] as num?)?.toDouble() ?? 0) / 1000;
            _routeMin = (((r['duration'] as num?)?.toDouble() ?? 0) / 60).round();
          });
        }
      }
    } catch (_) {}
    if (mounted && _selected?.id == entry.id && _route.isEmpty) {
      setState(() {
        _route = [user, dest];
        _routeKm = distanceKm(
          user.latitude,
          user.longitude,
          entry.latitude,
          entry.longitude,
        );
        _routeMin = null;
      });
    }
    if (mounted) setState(() => _routing = false);
  }

  void _clearSelection() {
    if (_selected == null && _route.isEmpty) return;
    setState(() {
      _selected = null;
      _route = [];
      _routeKm = null;
      _routeMin = null;
    });
  }

  double? _distanceTo(CatalogEntry e) {
    final u = _userPos;
    if (u == null) return null;
    return distanceKm(u.latitude, u.longitude, e.latitude, e.longitude);
  }

  @override
  Widget build(BuildContext context) {
    // Har doim rangli (voyager) — dark rejimda ham xarita qop-qora chiqmaydi.
    const tileUrl =
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter:
                  _userPos ?? const LatLng(kDefaultUserLat, kDefaultUserLng),
              initialZoom: 12,
              onTap: (_, _) => _clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.super_app',
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
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

          // TEPADA — tanlangan provayder preview kartasi (rasmdagidek).
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(sizeFactor: anim, child: child),
              ),
              child: _selected == null
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : ProviderMapPreviewCard(
                      key: ValueKey(_selected!.id),
                      entry: _selected!,
                      accent: widget.accent,
                      distanceKmValue: _routeKm ?? _distanceTo(_selected!),
                      durationMin: _routeMin,
                      routing: _routing,
                      onClose: _clearSelection,
                      onOrder: () => _selected!.onOpen(context),
                    ),
            ),
          ),

          // PASTDA — "filtrlar" tugmasi (rasmdagidek).
          Positioned(
            left: 16,
            right: 96,
            bottom: 20,
            child: _MapFilterButton(
              accent: widget.accent,
              categories: widget.categories,
              selectedCategory: widget.selectedCategory,
              onCategorySelected: widget.onCategorySelected,
              sortFilter: widget.sortFilter,
              onSortChanged: widget.onSortChanged,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fitAllMap',
            backgroundColor: Colors.white,
            foregroundColor: widget.accent,
            onPressed: _fitAll,
            child: const Icon(LucideIcons.maximize2),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'myLocMap',
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
            builder: (context, _) => Stack(
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
            ),
          ),
        ),
      );
    }

    // Provayder markerlari — masofa yorlig'i + doira ichida xizmat ikonkasi.
    for (final e in widget.entries) {
      final selected = _selected?.id == e.id;
      final km = _distanceTo(e);
      markers.add(
        Marker(
          point: LatLng(e.latitude, e.longitude),
          width: 130,
          height: 74,
          child: GestureDetector(
            onTap: () => _selectEntry(e),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        color:
                            selected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
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
}

/// Xarita ustidagi "filtrlar" tugmasi — ro'yxat ekrani bilan bir xil modal.
class _MapFilterButton extends StatelessWidget {
  final Color accent;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;
  final HubListFilter sortFilter;
  final ValueChanged<HubListFilter>? onSortChanged;

  const _MapFilterButton({
    required this.accent,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.sortFilter,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedCategory != null || sortFilter != HubListFilter.all;
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
        onTap: () => showHubFilterSheet(
          context,
          accent: accent,
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
          selected: sortFilter,
          onChanged: onSortChanged,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.slidersHorizontal,
                  size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Filtrlar'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
