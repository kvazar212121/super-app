import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../models/football_field.dart';
import 'football_field_booking_screen.dart';

/// Barcha futbol maydonlari aks etgan interaktiv xarita ekrani.
/// Marker ustiga tegish bilan maydon haqida ma'lumot ko'rinadi,
/// "Bron qilish" tugmasi orqali to'g'ridan-to'g'ri booking ekraniga o'tadi.
class FootballFieldMapScreen extends StatefulWidget {
  final List<FootballField> fields;

  const FootballFieldMapScreen({super.key, required this.fields});

  @override
  State<FootballFieldMapScreen> createState() => _FootballFieldMapScreenState();
}

class _FootballFieldMapScreenState extends State<FootballFieldMapScreen> {
  List<FootballField> get fields => widget.fields;

  // Filterlar
  FieldSize? _sizeFilter;
  FieldSurface? _surfaceFilter;
  bool _showFilters = false;

  // Saralash: 'rating' yoki 'price'
  String _sortBy = 'rating';

  List<FootballField> get _filteredFields {
    var list = fields.toList();

    if (_sizeFilter != null) {
      list = list.where((f) => f.size == _sizeFilter).toList();
    }
    if (_surfaceFilter != null) {
      list = list.where((f) => f.surface == _surfaceFilter).toList();
    }

    if (_sortBy == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'price') {
      list.sort((a, b) => a.basePricePerHour.compareTo(b.basePricePerHour));
    } else if (_sortBy == 'price_desc') {
      list.sort((a, b) => b.basePricePerHour.compareTo(a.basePricePerHour));
    }

    return list;
  }

  void _openFieldDetail(FootballField field) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FieldBottomSheet(field: field),
    );
  }

  List<Marker> _buildMarkers() {
    return _filteredFields.map((field) {
      return Marker(
        width: 130,
        height: 80,
        point: LatLng(field.latitude, field.longitude),
        child: GestureDetector(
          onTap: () => _openFieldDetail(field),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Maydon icon marker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: field.surface.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: field.surface.color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      field.surface.icon,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        field.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Narx ko'rsatkichi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '${NumberFormat('#,###').format(field.basePricePerHour)} soʻm',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Futbol maydonlari'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          // Maydonlar ro'yxati tugmasi
          IconButton(
            icon: Icon(_showFilters ? Icons.map : Icons.view_list),
            tooltip: _showFilters ? 'Xarita' : "Ro'yxat",
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          // Saralash
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Saralash',
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rating', child: Text('Reyting boʻyicha')),
              const PopupMenuItem(value: 'price', child: Text('Narx (arzon)')),
              const PopupMenuItem(value: 'price_desc', child: Text('Narx (qimmat)')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Xarita
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(41.3115, 69.2495),
              initialZoom: 11.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.super_app',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Top filter panel
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _FilterPanel(
              sizeFilter: _sizeFilter,
              surfaceFilter: _surfaceFilter,
              sortBy: _sortBy,
              onSizeChanged: (s) => setState(() => _sizeFilter = s),
              onSurfaceChanged: (s) => setState(() => _surfaceFilter = s),
              onSortChanged: (s) => setState(() => _sortBy = s),
            ),
          ),

          // Pastki qism: tanlangan filtr natijalari soni
          Positioned(
            bottom: 80,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_soccer, size: 18, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 6),
                  Text(
                    '${_filteredFields.length} ta maydon',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          // List rejimi overlay
          if (_showFilters)
            Positioned(
              top: 90,
              left: 12,
              right: 12,
              bottom: 12,
              child: _FieldListView(
                fields: _filteredFields,
                onFieldSelected: (f) => _openFieldDetail(f),
              ),
            ),
        ],
      ),
    );
  }
}

// ===================================================================
//              FILTER PANEL (xarita ustida)
// ===================================================================
class _FilterPanel extends StatelessWidget {
  final FieldSize? sizeFilter;
  final FieldSurface? surfaceFilter;
  final String sortBy;
  final ValueChanged<FieldSize?> onSizeChanged;
  final ValueChanged<FieldSurface?> onSurfaceChanged;
  final ValueChanged<String> onSortChanged;

  const _FilterPanel({
    required this.sizeFilter,
    required this.surfaceFilter,
    required this.sortBy,
    required this.onSizeChanged,
    required this.onSurfaceChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // O'lcham filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Barchasi'),
                    selected: sizeFilter == null,
                    onSelected: (_) => onSizeChanged(null),
                  ),
                  const SizedBox(width: 6),
                  ...FieldSize.values.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(s.shortLabel),
                        selected: sizeFilter == s,
                        selectedColor: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        onSelected: (_) => onSizeChanged(
                          sizeFilter == s ? null : s,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Qoplama filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...FieldSurface.values.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        avatar: Icon(s.icon, size: 16),
                        label: Text(s.label),
                        selected: surfaceFilter == s,
                        selectedColor: s.color.withValues(alpha: 0.2),
                        onSelected: (_) => onSurfaceChanged(
                          surfaceFilter == s ? null : s,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
//              LIST VIEW (xarita ustida)
// ===================================================================
class _FieldListView extends StatelessWidget {
  final List<FootballField> fields;
  final ValueChanged<FootballField> onFieldSelected;

  const _FieldListView({
    required this.fields,
    required this.onFieldSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Hech qanday maydon topilmadi',
              style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: fields.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final field = fields[i];
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: field.surface.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(field.surface.icon, color: field.surface.color),
            ),
            title: Text(
              field.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                Text(
                  ' ${field.rating}  ·  ${field.size.shortLabel}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Text(
              '${NumberFormat('#,###').format(field.basePricePerHour)} soʻm',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF4CAF50),
              ),
            ),
            onTap: () => onFieldSelected(field),
          );
        },
      ),
    );
  }
}

// ===================================================================
//              BOTTOM SHEET (maydon detali)
// ===================================================================
class _FieldBottomSheet extends StatelessWidget {
  final FootballField field;

  const _FieldBottomSheet({required this.field});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Maydon nomi va reyting
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star,
                                      size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${field.rating} (${field.reviewCount})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: field.surface.color
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                field.size.shortLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: field.surface.color,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Surface icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: field.surface.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      field.surface.icon,
                      color: field.surface.color,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Manzil
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      field.address,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Telefon
              if (field.phoneNumber.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      field.phoneNumber,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Qulayliklar
              const Text(
                'Qulayliklar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (field.hasLighting)
                    _AmenityChip(
                      icon: Icons.light_mode, label: 'Yoritish'),
                  if (field.hasParking)
                    _AmenityChip(
                      icon: Icons.local_parking, label: 'Avtoturargoh'),
                  if (field.hasShowers)
                    _AmenityChip(icon: Icons.shower, label: 'Dush'),
                  if (field.hasCafe)
                    _AmenityChip(icon: Icons.local_cafe, label: 'Kafe'),
                  ...field.amenities.map((a) => _AmenityChip(
                        icon: a.icon,
                        label: a.name,
                      )),
                ],
              ),
              const SizedBox(height: 20),

              // Narx va bron
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Narx',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(field.basePricePerHour)} soʻm / soat',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                FootballFieldBookingScreen(field: field),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month, size: 20),
                      label: const Text(
                        'Bron qilish',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }
}