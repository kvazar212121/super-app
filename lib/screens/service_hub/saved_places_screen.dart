import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/service_hub_kind.dart';
import '../../models/saved_place_model.dart';
import '../../models/barber_shop.dart';
import '../../models/beauty_salon.dart';
import '../../models/football_field.dart';
import '../../models/massage_hijoma.dart';
import '../../models/master_worker.dart';
import '../../models/nanny_service.dart';
import '../../models/tutor_service.dart';
import '../../models/nurse_service.dart';
import '../../models/dental_clinic.dart';
import '../../models/event_planning.dart';
import '../../models/disinfection_service.dart';
import '../../models/appliance_repair.dart';
import '../../models/courier_service.dart';
import '../../models/auto_mobile_service.dart';
import '../../models/auto_workshop.dart';
import '../../models/education_center.dart';

import '../../l10n/locale_controller.dart';
import '../../providers/saved_places_provider.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_surface.dart';
import '../../widgets/hub/venue_hub_card.dart';

import '../salon_booking_screen.dart';
import '../massage_booking_screen.dart';
import '../event_team_profile_screen.dart';
import '../provider_profile_screen.dart';
import '../nanny_profile_screen.dart';
import '../tutor_profile_screen.dart';
import '../nurse_booking_screen.dart';
import '../dental_booking_screen.dart';
import '../event_booking_screen.dart';
import '../disinfection_profile_screen.dart';
import '../appliance_profile_screen.dart';
import '../courier_profile_screen.dart';
import '../oshxona_profile_screen.dart';
import '../bozorchi_profile_screen.dart';
import '../auto_mobile_profile_screen.dart';
import '../auto_workshop_profile_screen.dart';
import '../education_center_booking_screen.dart';
import '../barber_booking_screen.dart';

class SavedPlacesScreen extends StatelessWidget {
  final ServiceHubKind category;

  const SavedPlacesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final accent = category.accent;
    final savedPlacesProvider = context.watch<SavedPlacesProvider>();
    final items = savedPlacesProvider.getSavedPlacesForCategory(category.name);

    return GlassScaffold(
      showBackButton: true,
      title: 'Saqlanganlar'.tr,
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bookmark,
                    size: 64,
                    color: GlassTokens.secondaryText(context).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hozircha saqlangan joylar yo\'q'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassSurface(
                    borderRadius: GlassTokens.radiusLg,
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => _handleItemTap(context, item),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(category.icon, color: accent, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: GlassTokens.primaryText(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: GlassTokens.secondaryText(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.rating}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: GlassTokens.primaryText(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () {
                              savedPlacesProvider.toggleSave(item);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _handleItemTap(BuildContext context, SavedPlace item) {
    final accent = category.accent;
    try {
    switch (item.type) {
      case 'massage':
        final center = MassageHijoma.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MassageBookingScreen(service: center)),
        );
        break;
      case 'event_team':
        final team = EventPlanning.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventTeamProfileScreen(team: team)),
        );
        break;
      case 'barber_shop':
        final shop = BarberShop.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BarberBookingScreen(shop: shop)),
        );
        break;
      case 'beauty_salon':
        final salon = BeautySalon.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SalonBookingScreen(salon: salon)),
        );
        break;
      case 'football_field':
        final field = FootballField.fromProviderJson(item.rawJson);
        showFieldPreviewSheet(context, field: field, accent: accent);
        break;
      case 'master':
        final master = Master.fromProviderJson(item.rawJson, category.title);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProviderProfileScreen(master: master, category: category),
          ),
        );
        break;
      case 'nanny':
        final nanny = NannyService.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NannyProfileScreen(nanny: nanny)),
        );
        break;
      case 'tutor':
        final tutor = TutorService.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: tutor)),
        );
        break;
      case 'nurse':
        final nurse = NurseService.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NurseBookingScreen(service: nurse)),
        );
        break;
      case 'dental_clinic':
        final clinic = DentalClinic.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DentalBookingScreen(clinic: clinic),
          ),
        );
        break;
      case 'event':
      case 'event_planning':
        final event = EventPlanning.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventBookingScreen(service: event)),
        );
        break;
      case 'disinfection':
        final disinfection = DisinfectionService.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisinfectionProfileScreen(service: disinfection),
          ),
        );
        break;
      case 'appliance':
        final appliance = ApplianceRepair.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplianceProfileScreen(service: appliance),
          ),
        );
        break;
      case 'courier':
        final courier = CourierService.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourierProfileScreen(service: courier),
          ),
        );
        break;
      case 'auto_mobile':
        final autoMobile = AutoMobileService.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AutoMobileProfileScreen(service: autoMobile),
          ),
        );
        break;
      case 'auto_workshop':
        final workshop = AutoWorkshop.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AutoWorkshopProfileScreen(workshop: workshop),
          ),
        );
        break;
      case 'education_center':
        final center = EducationCenter.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EducationCenterBookingScreen(center: center),
          ),
        );
        break;
      case 'oshxona':
        final oshxona = Master.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OshxonaProfileScreen(oshxona: oshxona),
          ),
        );
        break;
      case 'bozorchi':
        final bozorchi = Master.fromProviderJson(item.rawJson);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BozorchiProfileScreen(bozorchi: bozorchi),
          ),
        );
        break;
      default:
        // Fallback to provider profile if type is generic master
        final master = Master.fromProviderJson(item.rawJson, category.title);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProviderProfileScreen(master: master, category: category),
          ),
        );
    }
    } catch (e) {
      // Ba'zi turlar (game_zone/sport/venue) rawJson'dан qayta tiklanmasligi mumkin —
      // shunda ilova yiqilmasligi uchun xatoni yutamiz.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu joyni ochib bo\'lmadi'.tr)),
      );
    }
  }
}
