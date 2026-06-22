import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum NannyServiceType {
  hourly,
  halfDay,
  fullDay,
  overnight,
  weekly,
  monthly,
}

extension NannyServiceTypeX on NannyServiceType {
  String get key => switch (this) {
        NannyServiceType.hourly => 'hourly',
        NannyServiceType.halfDay => 'half_day',
        NannyServiceType.fullDay => 'full_day',
        NannyServiceType.overnight => 'overnight',
        NannyServiceType.weekly => 'weekly',
        NannyServiceType.monthly => 'monthly',
      };

  String get label => switch (this) {
        NannyServiceType.hourly => 'Soatbay',
        NannyServiceType.halfDay => 'Yarim kun',
        NannyServiceType.fullDay => 'Butun kun',
        NannyServiceType.overnight => 'Tungi qarash',
        NannyServiceType.weekly => 'Haftalik doimiy',
        NannyServiceType.monthly => 'Oylik doimiy',
      };

  static NannyServiceType? fromKey(String key) {
    for (final t in NannyServiceType.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

class NannyDocuments {
  final bool medicalCert;
  final bool criminalRecord;
  final bool idVerified;
  final String? medicalCertUrl;
  final String? idUrl;
  final String? criminalRecordUrl;

  const NannyDocuments({
    this.medicalCert = false,
    this.criminalRecord = false,
    this.idVerified = false,
    this.medicalCertUrl,
    this.idUrl,
    this.criminalRecordUrl,
  });

  bool get isFullyVerified => medicalCert && idVerified && criminalRecord;

  factory NannyDocuments.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NannyDocuments();
    return NannyDocuments(
      medicalCert: json['medical_cert'] == true,
      criminalRecord: json['criminal_record'] == true,
      idVerified: json['id_verified'] == true,
      medicalCertUrl: json['medical_cert_url']?.toString(),
      idUrl: json['id_url']?.toString(),
      criminalRecordUrl: json['criminal_record_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'medical_cert': medicalCert,
        'criminal_record': criminalRecord,
        'id_verified': idVerified,
        if (medicalCertUrl != null) 'medical_cert_url': medicalCertUrl,
        if (idUrl != null) 'id_url': idUrl,
        if (criminalRecordUrl != null) 'criminal_record_url': criminalRecordUrl,
      };
}

/// Enaga xizmati modeli
class NannyService {
  final String id;
  final int providerId;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String? serviceArea;
  final String address;
  final int experienceYears;
  final List<String> ageGroups;
  final List<String> languages;
  final List<NannyServiceType> serviceTypes;
  final List<String> services;
  final Map<String, double> prices;
  final List<String> timeSlots;
  final NannyDocuments documents;
  final String verificationStatus;
  final String? nannyRole;
  final int repeatFamilies;
  final Map<String, dynamic>? rawJson;

  const NannyService({
    required this.id,
    this.providerId = 0,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    this.serviceArea,
    this.address = '',
    this.experienceYears = 0,
    this.ageGroups = const [],
    this.languages = const [],
    this.serviceTypes = const [],
    this.services = const [],
    this.prices = const {},
    this.timeSlots = const [],
    this.documents = const NannyDocuments(),
    this.verificationStatus = 'pending',
    this.nannyRole,
    this.repeatFamilies = 0,
    this.rawJson,
  });

  bool get isVerified =>
      verificationStatus == 'verified' || nannyRole == 'verified';

  String get ageGroupsLabel =>
      ageGroups.isEmpty ? 'Barcha yosh' : ageGroups.join(', ');

  String get languagesLabel =>
      languages.map(languageLabel).join(', ');

  static String languageLabel(String code) => switch (code) {
        'uz' => 'O\'zbek',
        'ru' => 'Rus',
        'en' => 'Ingliz',
        _ => code,
      };

  factory NannyService.fromProviderJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final typeKeys = (meta['service_types'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final serviceTypes = typeKeys
        .map(NannyServiceTypeX.fromKey)
        .whereType<NannyServiceType>()
        .toList();

    final services = (meta['services'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final pricesRaw = meta['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0),
    );

    return NannyService(
      id: json['id']?.toString() ?? '',
      providerId: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 41.31,
      longitude: (json['lng'] as num?)?.toDouble() ?? 69.25,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone']?.toString() ?? '',
      serviceArea: meta['service_area']?.toString(),
      address: json['address']?.toString() ?? '',
      experienceYears: (meta['experience_years'] as num?)?.toInt() ?? 0,
      ageGroups: (meta['age_groups'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      languages: (meta['languages'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      serviceTypes: serviceTypes,
      services: services,
      prices: prices,
      timeSlots: (meta['time_slots'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      documents: NannyDocuments.fromJson(
        meta['documents'] as Map<String, dynamic>?,
      ),
      verificationStatus: meta['verification_status']?.toString() ?? 'pending',
      nannyRole: meta['nanny_role']?.toString(),
      repeatFamilies: (meta['repeat_families'] as num?)?.toInt() ?? 0,
      rawJson: json,
    );
  }

  IconData badgeIcon(String type) => switch (type) {
        'medical' => LucideIcons.heartPulse,
        'id' => LucideIcons.badgeCheck,
        'criminal' => LucideIcons.shieldCheck,
        _ => LucideIcons.check,
      };
}
