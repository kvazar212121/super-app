import sys

with open('lib/models/dental_clinic.dart', 'r') as f:
    content = f.read()

# Update DentalDentist
old_dentist = """class DentalDentist {
  final String name;
  final String specialty;

  const DentalDentist({required this.name, this.specialty = 'Stomatolog'});
}"""

new_dentist = """class DentalDentist {
  final String name;
  final String specialty;
  final int providerId;

  const DentalDentist({
    required this.name,
    this.specialty = 'Stomatolog',
    this.providerId = 0,
  });
}"""

content = content.replace(old_dentist, new_dentist)

# Update fromProviderJson mapping
old_map = """    final dentistsRaw = meta['dentists'] as List<dynamic>? ?? [];
    final dentists = dentistsRaw.map((d) {
      final m = d as Map<String, dynamic>? ?? {};
      return DentalDentist(
        name: m['name']?.toString() ?? 'Shifokor',
        specialty: m['specialty']?.toString() ?? 'Stomatolog',
      );
    }).toList();"""

new_map = """    final dentistsRaw = meta['dentists'] as List<dynamic>? ?? [];
    final dentists = dentistsRaw.map((d) {
      final m = d as Map<String, dynamic>? ?? {};
      return DentalDentist(
        name: m['name']?.toString() ?? 'Shifokor',
        specialty: m['specialty']?.toString() ?? 'Stomatolog',
        providerId: (m['provider_id'] as num?)?.toInt() ?? 0,
      );
    }).toList();"""

content = content.replace(old_map, new_map)

with open('lib/models/dental_clinic.dart', 'w') as f:
    f.write(content)

print("dental_clinic.dart model patched")
