import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../widgets/friendly_error.dart';
import '../config/map_config.dart';
import '../theme/lux_tokens.dart';

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

  // Xaritani harakatlantirishni kechiktirish (debounce)
  DateTime? _lastMoveTime;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialPosition != null) {
      _center = widget.initialPosition!;
      _pinPosition = widget.initialPosition!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_pinPosition);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Nominatim (OpenStreetMap) orqali koordinatdan manzil aniqlash.
  /// Bu Google xizmatiga bog'liq emas, emulatorlarda ham ishlaydi.
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _loadingAddress = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&format=json&accept-language=uz,ru,en',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'HubServis/1.0 (uz.hubservis.app)'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        // Manzilni qurish: ko'cha, tuman, shahar
        final parts = <String>[];
        final road =
            addr['road'] ??
            addr['pedestrian'] ??
            addr['footway'] ??
            addr['path'];
        final suburb =
            addr['suburb'] ?? addr['neighbourhood'] ?? addr['quarter'];
        final city =
            addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'];
        if (road != null) parts.add(road.toString());
        if (suburb != null) parts.add(suburb.toString());
        if (city != null) parts.add(city.toString());

        final result = parts.isNotEmpty
            ? parts.join(', ')
            : (data['display_name']?.toString().split(',').take(3).join(', ') ??
                  'Noma\'lum manzil');
        setState(() => _address = result);
      }
    } catch (_) {
      // Tarmoq muammosi bo'lsa koordinatlarni ko'rsatamiz
      if (mounted) {
        setState(
          () => _address =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joylashuv xizmati o\'chirilgan'.tr)),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joylashuv ruxsati rad etilgan'.tr)),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final myPos = LatLng(pos.latitude, pos.longitude);
      _mapController.move(myPos, 16);
      setState(() {
        _pinPosition = myPos;
        _center = myPos;
      });
      await _reverseGeocode(myPos);
    } catch (e) {
      if (mounted) {
        // "Xato: Exception..." o'rniga tushunarli xabar.
        showFriendlyErrorSnack(context, e);
      }
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
                  // Debounce: faqat harakatlanish to'xtagach manzilni aniqlash
                  _lastMoveTime = DateTime.now();
                  final capturedTime = _lastMoveTime;
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (_lastMoveTime == capturedTime && mounted) {
                      _reverseGeocode(_pinPosition);
                    }
                  });
                }
              },
              onMapReady: () {
                // manzilni yangilash map tayyor bo'lgach
              },
            ),
            children: [
              MapConfig.tileLayer(),
              // Litsenziya talabi: xarita ma'lumoti manbasi.
              MapConfig.attribution(),
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
                  colors: [LuxTokens.text, Colors.transparent],
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
              backgroundColor: LuxTokens.surface,
              onPressed: _locating ? null : _goToMyLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: LuxTokens.text),
            ),
          ),

          // ── Manzil ko'rsatish va tasdiqlash paneli ──────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: LuxTokens.surface,
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LuxTokens.border,
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
                      const Icon(
                        LucideIcons.mapPin,
                        color: Color(0xFFE11D48),
                        size: 20,
                      ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
