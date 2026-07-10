import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../models/beauty_salon.dart';
import '../models/football_field.dart';
import '../models/master_worker.dart';
import '../models/auto_workshop.dart';
import '../models/education_center.dart';
import '../screens/education_center_booking_screen.dart';
import '../models/disinfection_service.dart';
import '../models/appliance_repair.dart';
import '../models/courier_service.dart';
import '../models/massage_hijoma.dart';
import '../models/nurse_service.dart';
import '../models/dental_clinic.dart';
import '../models/event_planning.dart';
import '../models/service_hub_kind.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_surface.dart';
import '../screens/barber_booking_screen.dart';
import '../screens/salon_booking_screen.dart';
import '../screens/football_field_booking_screen.dart';
import '../screens/provider_profile_screen.dart';
import '../screens/master_dispatch_screen.dart';
import '../screens/disinfection_profile_screen.dart';
import '../screens/appliance_profile_screen.dart';
import '../screens/courier_profile_screen.dart';
import '../screens/sport_facility_booking_screen.dart';
import '../screens/game_zone_booking_screen.dart';
import '../screens/event_venue_booking_screen.dart';
import '../screens/event_team_profile_screen.dart';
import '../screens/oshxona_profile_screen.dart';
import '../screens/bozorchi_profile_screen.dart';
import '../screens/auto_mobile_profile_screen.dart';
import '../screens/auto_workshop_profile_screen.dart';
import '../screens/massage_booking_screen.dart';
import '../screens/nurse_booking_screen.dart';
import '../screens/dental_booking_screen.dart';
import '../screens/event_booking_screen.dart';
import '../screens/worker_profile_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Oq kartalardagi matnlar (har doim oq fonda, shuning uchun qat'iy qora).
const _cardTitleColor = Colors.black;
const _cardSubColor = Colors.black87;

class ShopSmallCard extends StatelessWidget {
  final BarberShop shop;
  final Color accentColor;

  const ShopSmallCard({
    super.key,
    required this.shop,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BarberBookingScreen(shop: shop)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(LucideIcons.scissors, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shop.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    shop.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalonSmallCard extends StatelessWidget {
  final BeautySalon salon;

  const SalonSmallCard({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE91E63);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SalonBookingScreen(salon: salon)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.sparkles, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                salon.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    salon.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FieldSmallCard extends StatelessWidget {
  final FootballField field;

  const FieldSmallCard({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF4CAF50);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FootballFieldBookingScreen(field: field),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(LucideIcons.trophy, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                field.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    field.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SportFacilitySmallCard extends StatelessWidget {
  final dynamic facility;

  const SportFacilitySmallCard({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final accentColor = ServiceHubKind.sportMaydon.accent;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SportFacilityBookingScreen(facility: facility),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                  image: facility.gallery.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(facility.gallery.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: facility.gallery.isEmpty
                    ? const Center(
                        child: Icon(Icons.sports_tennis, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                facility.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                facility.sportType,
                style: TextStyle(fontSize: 11, color: accentColor),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameZoneSmallCard extends StatelessWidget {
  final dynamic zone;

  const GameZoneSmallCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final accentColor = ServiceHubKind.gameZona.accent;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameZoneBookingScreen(zone: zone)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                  image: zone.gallery.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(zone.gallery.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: zone.gallery.isEmpty
                    ? const Center(
                        child: Icon(Icons.gamepad, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                zone.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                zone.zoneType,
                style: TextStyle(fontSize: 11, color: accentColor),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventVenueSmallCard extends StatelessWidget {
  final dynamic venue;

  const EventVenueSmallCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final accentColor = ServiceHubKind.tadbirlar.accent;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventVenueBookingScreen(venue: venue),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                  image: venue.gallery.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(venue.gallery.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: venue.gallery.isEmpty
                    ? const Center(
                        child: Icon(Icons.location_city, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                venue.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                venue.venueType,
                style: TextStyle(fontSize: 11, color: accentColor),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventTeamSmallCard extends StatelessWidget {
  final dynamic team;

  const EventTeamSmallCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final accentColor = ServiceHubKind.tadbirlar.accent;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventTeamProfileScreen(team: team)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.celebration, color: accentColor, size: 36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                team.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                team.capabilitiesLabel,
                style: TextStyle(fontSize: 11, color: accentColor),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MasterSmallCard extends StatelessWidget {
  final Master master;
  final ServiceHubKind category;

  const MasterSmallCard({
    super.key,
    required this.master,
    this.category = ServiceHubKind.usta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () {
          if (category == ServiceHubKind.oshxona) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OshxonaProfileScreen(oshxona: master),
              ),
            );
          } else if (category == ServiceHubKind.bozorchi) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BozorchiProfileScreen(bozorchi: master),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProviderProfileScreen(master: master, category: category),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue[50],
                child: const Icon(LucideIcons.user, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                master.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                master.specialty,
                style: TextStyle(fontSize: 11, color: Colors.blue[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkerSmallCard extends StatelessWidget {
  final Worker worker;

  const WorkerSmallCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerProfileScreen(worker: worker),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange[50],
                child: Icon(LucideIcons.user, color: Colors.orange[800]),
              ),
              const SizedBox(height: 8),
              Text(
                worker.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _cardTitleColor,
                ),
              ),
              Text(
                worker.type,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HubActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const HubActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: GlassTokens.secondaryText(context),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class WorkshopSmallCard extends StatelessWidget {
  final AutoWorkshop workshop;

  const WorkshopSmallCard({super.key, required this.workshop});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF334155); // Slate for physical buildings
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AutoWorkshopProfileScreen(workshop: workshop),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.home, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workshop.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                workshop.specializations.join(", "),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    workshop.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _cardTitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EducationCenterSmallCard extends StatelessWidget {
  final EducationCenter center;

  const EducationCenterSmallCard({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1); // Indigo for education
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EducationCenterBookingScreen(center: center),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.bookOpen, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                center.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                center.courses.join(", "),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    center.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _cardTitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 6 ta YANGI:
class DisinfectionSmallCard extends StatelessWidget {
  final DisinfectionService service;

  const DisinfectionSmallCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF10B981);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisinfectionProfileScreen(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.shieldCheck, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ApplianceSmallCard extends StatelessWidget {
  final ApplianceRepair service;

  const ApplianceSmallCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF607D8B);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplianceProfileScreen(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.monitor, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourierSmallCard extends StatelessWidget {
  final CourierService service;

  const CourierSmallCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFB300);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourierProfileScreen(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.bike, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MassageSmallCard extends StatelessWidget {
  final MassageHijoma service;

  const MassageSmallCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE11D48);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MassageBookingScreen(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.heartPulse, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                service.visitModesLabel,
                style: const TextStyle(fontSize: 10, color: _cardSubColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NurseSmallCard extends StatelessWidget {
  final NurseService service;

  const NurseSmallCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE53935);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NurseBookingScreen(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.heartPulse, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                service.visitLabel,
                style: const TextStyle(fontSize: 10, color: _cardSubColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DentalSmallCard extends StatelessWidget {
  final DentalClinic clinic;

  const DentalSmallCard({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF0EA5E9);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DentalBookingScreen(clinic: clinic),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.smile, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                clinic.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                'Klinikada vaqt bron',
                style: const TextStyle(fontSize: 10, color: _cardSubColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    clinic.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventSmallCard extends StatelessWidget {
  final EventPlanning service;

  const EventSmallCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE91E63);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventBookingScreen(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.partyPopper, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _cardTitleColor,
                ),
                maxLines: 1,
              ),
              Text(
                service.teamSize > 1
                    ? '${service.teamSize} kishi · ${service.capabilitiesLabel}'
                    : service.capabilitiesLabel,
                style: const TextStyle(fontSize: 10, color: _cardSubColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    service.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: _cardSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
