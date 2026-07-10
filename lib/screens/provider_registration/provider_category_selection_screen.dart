import 'package:flutter/material.dart';
import '../../config/provider_category_config.dart';
import '../../services/api_service.dart';
import '../provider_side/provider_theme.dart';
import 'barber/barber_role_selection_screen.dart';
import 'cleaning/cleaning_role_selection_screen.dart';
import 'master/master_role_selection_screen.dart';
import 'salon/salon_role_selection_screen.dart';
import 'electrician/electrician_solo_screen.dart';
import 'plumber/plumber_solo_screen.dart';
import 'ac/ac_solo_screen.dart';
import 'courier/courier_solo_screen.dart';
import 'auto/auto_role_selection_screen.dart';
import 'nanny/nanny_registration_screen.dart';
import 'tutor/tutor_role_selection_screen.dart';
import 'disinfection/disinfection_registration_screen.dart';
import 'massage/massage_registration_screen.dart';
import 'nurse/nurse_registration_screen.dart';
import 'dental/dental_registration_screen.dart';
import 'event/event_registration_screen.dart';
import 'provider_data_entry_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

class ProviderCategorySelectionScreen extends StatefulWidget {
  const ProviderCategorySelectionScreen({super.key});

  @override
  State<ProviderCategorySelectionScreen> createState() =>
      _ProviderCategorySelectionScreenState();
}

class _ProviderCategorySelectionScreenState
    extends State<ProviderCategorySelectionScreen> {
  String? _selectedCategory;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService().getCategories();
      final items = <Map<String, dynamic>>[];
      for (final c in cats) {
        final key = c['key']?.toString() ?? '';
        if (key == 'yana') continue;
        final config = ProviderCategoryConfig.byCategoryKey(key);
        items.add({
          'id': config?.registrationId ?? key,
          'dbId': c['id'],
          'name': c['title']?.toString() ?? config?.title ?? 'Boshqa xizmat',
          'icon': config?.icon ?? Icons.category,
        });
      }
      _categories = items;

      // Append any missing categories from ProviderCategoryConfig
      final existingIds = _categories.map((c) => c['id']).toSet();
      for (final c in ProviderCategoryConfig.all) {
        if (!existingIds.contains(c.registrationId)) {
          _categories.add({
            'id': c.registrationId,
            'dbId': null,
            'name': c.title,
            'icon': c.icon,
          });
        }
      }
    } catch (_) {
      _error = 'Kategoriyalarni yuklab bo\'lmadi';
      _categories = _fallbackCategories();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _fallbackCategories() {
    return ProviderCategoryConfig.all
        .map(
          (c) => {
            'id': c.registrationId,
            'dbId': null,
            'name': c.title,
            'icon': c.icon,
          },
        )
        .toList();
  }

  Map<String, dynamic>? get _selected {
    if (_selectedCategory == null) return null;
    for (final c in _categories) {
      if (c['id'] == _selectedCategory) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(title: Text('Sohani tanlang'.tr)),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qaysi sohada xizmat ko\'rsatasiz?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sizning sohangizga qarab mijozlar sizni topishadi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.orange)),
                  ],
                  const SizedBox(height: 24),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1,
                                ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory == cat['id'];

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat['id'] as String;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.black12
                                        : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        size: 40,
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          cat['name'] as String,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? Colors.black
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedCategory == null || _loading
                          ? null
                          : () {
                              final cat = _selected!;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    if (cat['id'] == 'barber') {
                                      return BarberRoleSelectionScreen(
                                        categoryDbId: cat['dbId'] as int?,
                                      );
                                    }
                                    if (cat['id'] == 'cleaner') {
                                      return const CleaningRoleSelectionScreen();
                                    }
                                    if (cat['id'] == 'builder') {
                                      return const MasterRoleSelectionScreen();
                                    }
                                    if (cat['id'] == 'salon') {
                                      return const SalonRoleSelectionScreen();
                                    }
                                    if (cat['id'] == 'electrician') {
                                      return const ElectricianSoloScreen();
                                    }
                                    if (cat['id'] == 'plumber') {
                                      return const PlumberSoloScreen();
                                    }
                                    if (cat['id'] == 'courier') {
                                      return const CourierSoloScreen();
                                    }
                                    if (cat['id'] == 'auto') {
                                      return const AutoRoleSelectionScreen();
                                    }
                                    if (cat['id'] == 'ac') {
                                      return const AcSoloScreen();
                                    }
                                    if (cat['id'] == 'nanny') {
                                      return const NannyRegistrationScreen();
                                    }
                                    if (cat['id'] == 'tutor') {
                                      return const TutorRoleSelectionScreen();
                                    }
                                    if (cat['id'] == 'disinfection') {
                                      return const DisinfectionRegistrationScreen();
                                    }
                                    if (cat['id'] == 'massage') {
                                      return const MassageRegistrationScreen();
                                    }
                                    if (cat['id'] == 'nurse') {
                                      return const NurseRegistrationScreen();
                                    }
                                    if (cat['id'] == 'dental') {
                                      return const DentalRegistrationScreen();
                                    }
                                    if (cat['id'] == 'events') {
                                      return const EventRegistrationScreen();
                                    }
                                    return ProviderDataEntryScreen(
                                      categoryId: cat['id'] as String,
                                      categoryName: cat['name'] as String,
                                      categoryDbId: cat['dbId'] as int?,
                                    );
                                  },
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Davom etish'.tr),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
