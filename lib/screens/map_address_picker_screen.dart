import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Xaritadan manzil tanlash ekrani.
/// Foydalanuvchi xaritani siljitib belgi qo'yadi,
/// keyin "Shu manzilni tanlash" tugmasini bosadi.
class MapAddressPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const MapAddressPickerScreen({super.key, this.initialPosition});

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  late final MapController _mapController;

  // Boshlang'ich joylashuv: Toshkent markazi
  LatLng _center = const LatLng(41.2995, 69.2401);
  LatLng _pinPosition = const LatLng(41.2995, 69.2401);

  String _address = 'Manzil aniqlanmoqda...';
  bool _loadingAddress = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialPosition != null) {
      _center = widget.initialPosition!;
      _pinPosition = widget.initialPosition!;
    }
    // Birinchi marta manzilni yuklash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_pinPosition);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _loadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.street?.isNotEmpty == true) parts.add(p.street!);
        if (p.subLocality?.isNotEmpty == true) parts.add(p.subLocality!);
        if (p.locality?.isNotEmpty == true) parts.add(p.locality!);
        setState(() => _address = parts.isNotEmpty ? parts.join(', ') : 'Aniq manzil topilmadi');
      }
    } catch (_) {
      if (mounted) setState(() => _address = 'Manzil aniqlanmadi');
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joylashuv xizmati o\'chirilgan')));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joylashuv ruxsati rad etilgan')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final myPos = LatLng(pos.latitude, pos.longitude);
      _mapController.move(myPos, 16);
      setState(() {
        _pinPosition = myPos;
        _center = myPos;
      });
      await _reverseGeocode(myPos);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Xarita ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  setState(() => _pinPosition = pos.center);
                }
              },
              onMapReady: () {
                // manzilni yangilash map tayyor bo'lgach
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.hubservis.app',
              ),
            ],
          ),

          // ── Markaziy pin (belgi) ─────────────────────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Color(0xFFE11D48), size: 48),
                SizedBox(height: 24), // pin balandligi kompensatsiyasi
              ],
            ),
          ),

          // ── Yuqori sarlavha ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 8,
                right: 8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Manzilni tanlang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // ── Joylashuvga o'tish tugmasi ──────────────────────
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              onPressed: _locating ? null : _goToMyLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // ── Manzil ko'rsatish va tasdiqlash paneli ──────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanlangan manzil',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: Color(0xFFE11D48), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _loadingAddress
                            ? const Text(
                                'Manzil aniqlanmoqda...',
                                style: TextStyle(color: Colors.grey),
                              )
                            : Text(
                                _address,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadingAddress
                          ? null
                          : () => Navigator.pop(context, _address),
                      icon: const Icon(LucideIcons.check),
                      label: const Text(
                        'Shu manzilni tanlash',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
