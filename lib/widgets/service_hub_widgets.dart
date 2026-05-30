import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../models/beauty_salon.dart';
import '../models/football_field.dart';
import '../models/master_worker.dart';
import '../models/auto_workshop.dart';
import '../models/education_center.dart';
import '../models/disinfection_service.dart';
import '../models/appliance_repair.dart';
import '../models/courier_service.dart';
import '../models/massage_hijoma.dart';
import '../models/nurse_service.dart';
import '../models/event_planning.dart';
import '../screens/barber_booking_screen.dart';
import '../screens/salon_booking_screen.dart';
import '../screens/football_field_booking_screen.dart';
import '../screens/master_dispatch_screen.dart';
import '../screens/disinfection_booking_screen.dart';
import '../screens/appliance_booking_screen.dart';
import '../screens/courier_booking_screen.dart';
import '../screens/massage_booking_screen.dart';
import '../screens/nurse_booking_screen.dart';
import '../screens/event_booking_screen.dart';

class ShopSmallCard extends StatelessWidget {
  final BarberShop shop;
  final Color accentColor;

  const ShopSmallCard({super.key, required this.shop, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(LucideIcons.scissors, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(shop.rating.toString(), style: const TextStyle(fontSize: 12)),
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
        border: Border.all(color: Colors.grey[200]!),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.sparkles, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(salon.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(salon.rating.toString(), style: const TextStyle(fontSize: 12)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FootballFieldBookingScreen(field: field)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.trophy, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(field.rating.toString(), style: const TextStyle(fontSize: 12)),
                ],
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

  const MasterSmallCard({super.key, required this.master});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MasterDispatchScreen(master: master)),
        ),
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
              Text(master.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
              Text(master.specialty, style: TextStyle(fontSize: 11, color: Colors.blue[700])),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${worker.name} bilan bog'lanilmoqda...")),
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
              Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(worker.type, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${workshop.name} ustaxonasi haqida ma'lumot...")),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.home, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(workshop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
              Text(workshop.specializations.join(", "), style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(workshop.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${center.name} haqida ma'lumot...")),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.bookOpen, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
              Text(center.courses.join(", "), style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(center.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DisinfectionBookingScreen(service: service)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.shieldCheck, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(service.rating.toString(), style: const TextStyle(fontSize: 12)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ApplianceBookingScreen(service: service)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.monitor, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(service.rating.toString(), style: const TextStyle(fontSize: 12)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourierBookingScreen(service: service)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.bike, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(service.rating.toString(), style: const TextStyle(fontSize: 12)),
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
    const accentColor = Color(0xFF795548);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MassageBookingScreen(service: service)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.hand, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(service.rating.toString(), style: const TextStyle(fontSize: 12)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NurseBookingScreen(service: service)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.heartPulse, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(service.rating.toString(), style: const TextStyle(fontSize: 12)),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventBookingScreen(service: service)),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(LucideIcons.partyPopper, color: accentColor)),
              ),
              const SizedBox(height: 8),
              Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(service.rating.toString(), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
