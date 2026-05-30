import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  static List<NurseService> demoServices = [
    NurseService(
      id: 'ns1',
      name: 'Tibbiyot Uyda',
      latitude: 41.3125,
      longitude: 69.2505,
      rating: 4.7,
      reviewCount: 156,
      phoneNumber: '+998 90 555 66 77',
      medicalServices: [
        MedicalService.injection,
        MedicalService.bloodTest,
        MedicalService.drip,
        MedicalService.woundCare,
        MedicalService.ecg,
      ],
      prices: {
        'Ukol': 25000,
        'Qon tahlili': 80000,
        'Tomchilatma': 100000,
        'Yara parvarishi': 60000,
        'EKG': 120000,
        'Uyga chiqish': 40000,
      },
      homeVisit: true,
      qualifications: 'Oliy tibbiyot ma\'lumoti, 10 yillik tajriba',
    ),
    NurseService(
      id: 'ns2',
      name: 'Hamshira Pro',
      latitude: 41.2965,
      longitude: 69.2375,
      rating: 4.8,
      reviewCount: 203,
      phoneNumber: '+998 93 888 99 00',
      medicalServices: [
        MedicalService.injection,
        MedicalService.drip,
        MedicalService.postOpCare,
        MedicalService.elderlyCare,
        MedicalService.diabetesMonitoring,
      ],
      prices: {
        'Ukol': 30000,
        'Tomchilatma': 120000,
        'Operatsiyadan keyingi parvarish': 200000,
        'Keksalarga parvarish (kunlik)': 250000,
        'Qandli diabet nazorati': 90000,
        'Uyga chiqish': 35000,
      },
      homeVisit: true,
      qualifications: 'Katta hamshira, jarrohlik bo\'limi tajribasi, 8 yil',
    ),
    NurseService(
      id: 'ns3',
      name: 'MedService',
      latitude: 41.3245,
      longitude: 69.2745,
      rating: 4.5,
      reviewCount: 87,
      phoneNumber: '+998 94 111 22 33',
      medicalServices: [
        MedicalService.vaccination,
        MedicalService.bloodTest,
        MedicalService.physiotherapy,
        MedicalService.ecg,
      ],
      prices: {
        'Emash': 50000,
        'Qon tahlili': 70000,
        'Fizioterapiya (seans)': 150000,
        'EKG': 100000,
        'Konsultatsiya': 40000,
      },
      homeVisit: false,
      qualifications: 'Tibbiyot klinikasi, litsenziyalangam muassasa',
    ),
    NurseService(
      id: 'ns4',
      name: "Sog'liq Xizmat",
      latitude: 41.3095,
      longitude: 69.2825,
      rating: 4.9,
      reviewCount: 278,
      phoneNumber: '+998 97 444 55 66',
      medicalServices: [
        MedicalService.injection,
        MedicalService.bloodTest,
        MedicalService.drip,
        MedicalService.woundCare,
        MedicalService.physiotherapy,
        MedicalService.vaccination,
        MedicalService.postOpCare,
        MedicalService.elderlyCare,
        MedicalService.diabetesMonitoring,
        MedicalService.ecg,
      ],
      prices: {
        'Ukol': 20000,
        'Qon tahlili': 75000,
        'Tomchilatma': 110000,
        'Yara parvarishi': 55000,
        'Fizioterapiya (seans)': 140000,
        'Emash': 45000,
        'Operatsiyadan keyingi parvarish': 180000,
        'Keksalarga parvarish (kunlik)': 220000,
        'Qandli diabet nazorati': 85000,
        'EKG': 110000,
        'Uyga chiqish': 30000,
      },
      homeVisit: true,
      qualifications: 'Malakali hamshiralar jamoasi, 15+ yillik tajriba, barcha yo\'nalishlar',
    ),
  ];
}
