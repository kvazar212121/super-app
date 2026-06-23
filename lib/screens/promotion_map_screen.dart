import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';

class PromotionMapScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> colors;

  const PromotionMapScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
  });

  @override
  State<PromotionMapScreen> createState() => _PromotionMapScreenState();
}

class _PromotionMapScreenState extends State<PromotionMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _tashkentCenter = const LatLng(41.2995, 69.2401);
  
  // Aksiya joylari uchun mock markerlar
  final List<LatLng> _promoLocations = [
    const LatLng(41.3111, 69.2797),
    const LatLng(41.2856, 69.2012),
    const LatLng(41.3289, 69.2450),
    const LatLng(41.2750, 69.2600),
    const LatLng(41.3000, 69.2200),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Aksiya Xaritasi',
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBanner(context),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _tashkentCenter,
        initialZoom: 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hubservis.app',
        ),
        MarkerLayer(
          markers: _promoLocations.map((loc) {
            return Marker(
              point: loc,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showPromoDetails(loc),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: GlassTokens.glassBlur, sigmaY: GlassTokens.glassBlur),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.colors[0].withOpacity(0.85),
                  widget.colors[1].withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: widget.colors[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.badge,
                    style: TextStyle(
                      color: widget.colors[0],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPromoDetails(LatLng loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksiyadagi ob\\'yekt',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: TextStyle(color: widget.colors[0], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aksiya bo\\'yicha chegirma ushbu filialda amal qiladi. Joyni band qilish uchun hoziroq qo\\'ng\\'iroq qiling.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ma\\'muriyatga qo\\'ng\\'iroq qilinmoqda...')),
                  );
                },
                icon: const Icon(LucideIcons.phone),
                label: const Text('Qo\\'ng\\'iroq qilish'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.colors[0],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
