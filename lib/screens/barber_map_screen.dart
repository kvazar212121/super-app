import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/barber_shop.dart';
import '../widgets/enhanced_service_map.dart';
import 'barber_booking_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class BarberMapScreen extends StatelessWidget {
  final List<BarberShop> shops;

  const BarberMapScreen({super.key, required this.shops});

  @override
  Widget build(BuildContext context) {
    return EnhancedServiceMap(
      title: "Yaqin atrofdagi sartaroshlar".tr,
      accent: const Color(0xFFC9A227),
      markerIcon: LucideIcons.scissors,
      places: shops
          .map((s) => MapPlace(
                id: s.id,
                name: s.name,
                lat: s.latitude,
                lng: s.longitude,
                subtitle: s.address,
                rating: s.rating,
                payload: s,
              ))
          .toList(),
      onOpen: (place) {
        final shop = place.payload as BarberShop;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BarberBookingScreen(shop: shop)),
        );
      },
    );
  }
}
