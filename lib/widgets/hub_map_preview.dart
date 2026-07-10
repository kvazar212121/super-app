import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Xarita yarmini barcha hub ekranlarida qayta ishlatish uchun.
class HubMapPreview extends StatelessWidget {
  final List<Marker> markers;
  final LatLng center;
  final double zoom;
  final VoidCallback? onExpand; // Added onExpand

  const HubMapPreview({
    super.key,
    required this.markers,
    this.center = const LatLng(41.3115, 69.2495),
    this.zoom = 12.0,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: zoom),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.super_app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (onExpand != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'expand_map',
              onPressed: onExpand,
              backgroundColor: Colors.white,
              child: const Icon(Icons.fullscreen, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
