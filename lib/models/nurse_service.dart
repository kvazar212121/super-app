import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tibbiy xizmat turi
enum MedicalService {
  injection,
  bloodTest,
  drip,
  woundCare,
  physiotherapy,
  vaccination,
  postOpCare,
  elderlyCare,
  diabetesMonitoring,
  ecg;

  static MedicalService? fromKey(String key) {
    final k = key.replaceAll('-', '_');
    return switch (k) {
      'injection' => MedicalService.injection,
      'blood_test' => MedicalService.bloodTest,
      'drip' => MedicalService.drip,
      'wound_care' => MedicalService.woundCare,
      'physiotherapy' => MedicalService.physiotherapy,
      'vaccination' => MedicalService.vaccination,
      'post_op_care' => MedicalService.postOpCare,
      'elderly_care' => MedicalService.elderlyCare,
      'diabetes_monitoring' => MedicalService.diabetesMonitoring,
      'ecg' => MedicalService.ecg,
      _ => null,
    };
  }
}

extension MedicalServiceX on MedicalService {
  String get key => switch (this) {
        MedicalService.injection => 'injection',
        MedicalService.bloodTest => 'blood_test',
        MedicalService.drip => 'drip',
        MedicalService.woundCare => 'wound_care',
        MedicalService.physiotherapy => 'physiotherapy',
        MedicalService.vaccination => 'vaccination',
        MedicalService.postOpCare => 'post_op_care',
        MedicalService.elderlyCare => 'elderly_care',
        MedicalService.diabetesMonitoring => 'diabetes_monitoring',
        MedicalService.ecg => 'ecg',
      };

  String get label => switch (this) {
        MedicalService.injection => 'Ukol',
        MedicalService.bloodTest => 'Qon tahlili',
        MedicalService.drip => 'Tomchilatma',
        MedicalService.woundCare => 'Yara parvarishi',
        MedicalService.physiotherapy => 'Fizioterapiya',
        MedicalService.vaccination => 'Emash',
        MedicalService.postOpCare => 'Operatsiyadan keyingi parvarish',
        MedicalService.elderlyCare => 'Keksalarga parvarish',
        MedicalService.diabetesMonitoring => 'Qandli diabet nazorati',
        MedicalService.ecg => 'EKG',
      };

  IconData get icon => switch (this) {
        MedicalService.injection => LucideIcons.syringe,
        MedicalService.bloodTest => LucideIcons.flaskConical,
        MedicalService.drip => LucideIcons.droplet,
        MedicalService.woundCare => LucideIcons.heart,
        MedicalService.physiotherapy => LucideIcons.activity,
        MedicalService.vaccination => LucideIcons.shield,
        MedicalService.postOpCare => LucideIcons.heartPulse,
        MedicalService.elderlyCare => LucideIcons.user,
        MedicalService.diabetesMonitoring => LucideIcons.droplet,
        MedicalService.ecg => LucideIcons.activity,
      };
}

/// Hamshira — faqat uyga chiqish (chaqirish)
class NurseService {
  final String id;
  final int providerId;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String? serviceArea;
  final List<MedicalService> medicalServices;
  final Map<String, double> prices;
  final String qualifications;
  final List<String> timeSlots;
  final Map<String, dynamic>? rawJson;

  final String? subCategory;

  NurseService({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    this.serviceArea,
    required this.medicalServices,
    required this.prices,
    required this.qualifications,
    this.timeSlots = const [],
    this.rawJson,
      this.subCategory,
  });

  bool get homeVisitOnly => true;

  String get visitLabel => 'Uyga chiqish (chaqirish)';

  @Deprecated('Use homeVisitOnly')
  bool get homeVisit => true;

  factory NurseService.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final typeKeys = (meta['medical_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    var types = typeKeys.map(MedicalService.fromKey).whereType<MedicalService>().toList();
    if (types.isEmpty) {
      types = [MedicalService.injection, MedicalService.bloodTest, MedicalService.drip];
    }

    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.isEmpty
        ? {
            "Ukol (in'ektsiya)": 35000.0,
            'Qon tahlili (uyda)': 120000.0,
          }
        : pricesRaw.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0));

    return NurseService(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone']?.toString() ?? '',
      serviceArea: meta['service_area']?.toString(),
      medicalServices: types,
      prices: prices,
      qualifications: meta['qualifications']?.toString() ?? 'Litsenziyalangan hamshira',
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      rawJson: json,
          subCategory: meta['sub_category']?.toString(),
    );
  }
}
