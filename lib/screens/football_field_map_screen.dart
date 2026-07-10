import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:super_app/l10n/locale_controller.dart';

import '../models/football_field.dart';
import '../widgets/enhanced_service_map.dart';
import 'football_field_booking_screen.dart';

/// Barcha futbol maydonlari aks etgan interaktiv xarita ekrani.
/// Har bir maydon markerini tanlab, yo'l marshruti va masofa ko'rinadi;
/// "Xizmatlarni ko'rish" tugmasi orqali to'g'ridan-to'g'ri booking ekraniga o'tadi.
class FootballFieldMapScreen extends StatelessWidget {
  final List<FootballField> fields;

  const FootballFieldMapScreen({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    return EnhancedServiceMap(
      title: 'Futbol maydonlari'.tr,
      accent: const Color(0xFF4CAF50),
      markerIcon: LucideIcons.trophy,
      places: fields
          .map(
            (field) => MapPlace(
              id: field.id,
              name: field.name,
              lat: field.latitude,
              lng: field.longitude,
              subtitle: field.address,
              rating: field.rating,
              payload: field,
            ),
          )
          .toList(),
      onOpen: (place) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              FootballFieldBookingScreen(field: place.payload as FootballField),
        ),
      ),
    );
  }
}
