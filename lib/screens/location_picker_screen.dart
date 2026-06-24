import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat = 41.2995,
    this.initialLng = 69.2401,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _currentCenter;
  String _currentAddress = 'Manzil aniqlanmoqda...';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
    _updateAddress(_currentCenter);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(LatLng pos) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [place.street, place.subLocality, place.locality]
            .where((e) => e != null && e.isNotEmpty)
            .toList();
        if (mounted) {
          setState(() {
            _currentAddress = parts.isNotEmpty ? parts.join(', ') : "Noma'lum manzil";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Manzilni aniqlab bo'lmadi";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GPS xizmati o'chirilgan")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joylashuvga ruxsat berilmadi')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joylashuv ruxsati butunlay rad etilgan. Sozlamalardan yoqing.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joylashuv aniqlanmoqda...')),
    );

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final newLatLng = LatLng(pos.latitude, pos.longitude);
    _mapController.move(newLatLng, 16);
    _currentCenter = newLatLng;
    _updateAddress(newLatLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xaritadan tanlash'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  _currentCenter = pos.center!;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _updateAddress(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.super_app',
              ),
            ],
          ),
          // Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Point precisely at center
              child: Icon(LucideIcons.mapPin, color: Colors.red, size: 40),
            ),
          ),
          // My Location Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(LucideIcons.navigation, color: Colors.blue),
            ),
          ),
          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanlangan manzil', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isLoadingAddress ? 'Kutib turing...' : _currentAddress,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context, {
                            'lat': _currentCenter.latitude,
                            'lng': _currentCenter.longitude,
                            'address': _currentAddress,
                          });
                        },
                        child: const Text('Shu yerni tasdiqlash'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
