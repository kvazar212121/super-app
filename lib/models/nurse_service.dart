import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tibbiy xizmat turi
enum MedicalService {
  injection,          // Ukol
  bloodTest,          // Qon tahlili
  drip,               // Tomchilatma
  woundCare,          // Yara parvarishi
  physiotherapy,      // Fizioterapiya
  vaccination,        // Emash
  postOpCare,         // Operatsiyadan keyingi parvarish
  elderlyCare,        // Keksalarga parvarish
  diabetesMonitoring, // Qandli diabet nazorati
  ecg,                // EKG
}

extension MedicalServiceX on MedicalService {
  String get label => switch (this) {
        MedicalService.injection          => 'Ukol',
        MedicalService.bloodTest          => 'Qon tahlili',
        MedicalService.drip               => 'Tomchilatma',
        MedicalService.woundCare          => 'Yara parvarishi',
        MedicalService.physiotherapy      => 'Fizioterapiya',
        MedicalService.vaccination        => 'Emash',
        MedicalService.postOpCare         => 'Operatsiyadan keyingi parvarish',
        MedicalService.elderlyCare        => 'Keksalarga parvarish',
        MedicalService.diabetesMonitoring => 'Qandli diabet nazorati',
        MedicalService.ecg                => 'EKG',
      };

  IconData get icon => switch (this) {
        MedicalService.injection          => LucideIcons.syringe,
        MedicalService.bloodTest          => LucideIcons.flaskConical,
        MedicalService.drip               => LucideIcons.droplet,
        MedicalService.woundCare          => LucideIcons.heart,
        MedicalService.physiotherapy      => LucideIcons.activity,
        MedicalService.vaccination        => LucideIcons.shield,
        MedicalService.postOpCare         => LucideIcons.heartPulse,
        MedicalService.elderlyCare        => LucideIcons.user,
        MedicalService.diabetesMonitoring => LucideIcons.droplet,
        MedicalService.ecg                => LucideIcons.activity,
      };
}

/// Hamshira xizmati modeli
class NurseService {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<MedicalService> medicalServices;
  final Map<String, double> prices;
  final bool homeVisit;
  final String qualifications;

  const NurseService({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.medicalServices,
    required this.prices,
    required this.homeVisit,
    required this.qualifications,
  });

  factory NurseService.fromProviderJson(Map<String, dynamic> json) {
    return NurseService(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      phoneNumber: json['phone'] ?? '',
      medicalServices: const [MedicalService.injection, MedicalService.bloodTest, MedicalService.drip],
      prices: const {'Ukol': 30000, 'Qon tahlili': 50000},
      homeVisit: true,
      qualifications: 'Litsenziyalangan hamshira',
    );
  }

}
