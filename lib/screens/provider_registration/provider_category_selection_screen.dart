import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../provider_side/provider_theme.dart';
import 'provider_data_entry_screen.dart';

class ProviderCategorySelectionScreen extends StatefulWidget {
  const ProviderCategorySelectionScreen({super.key});

  @override
  State<ProviderCategorySelectionScreen> createState() => _ProviderCategorySelectionScreenState();
}

class _ProviderCategorySelectionScreenState extends State<ProviderCategorySelectionScreen> {
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'barber', 'name': 'Sartarosh', 'icon': LucideIcons.scissors},
    {'id': 'salon', 'name': 'Go\'zallik saloni', 'icon': LucideIcons.sparkles},
    {'id': 'plumber', 'name': 'Santexnik', 'icon': LucideIcons.droplets},
    {'id': 'electrician', 'name': 'Elektrik', 'icon': LucideIcons.zap},
    {'id': 'cleaner', 'name': 'Tozalash xizmati', 'icon': LucideIcons.sprayCan},
    {'id': 'builder', 'name': 'Quruvchi / Usta', 'icon': LucideIcons.hammer},
    {'id': 'worker', 'name': 'Ishchi / Yuk', 'icon': LucideIcons.users},
    {'id': 'futbol', 'name': 'Futbol maydoni', 'icon': LucideIcons.trophy},
    {'id': 'tutor', 'name': 'Repetitor', 'icon': LucideIcons.graduationCap},
    {'id': 'auto', 'name': 'Avto-yordam', 'icon': LucideIcons.car},
    {'id': 'ac', 'name': 'Konditsioner', 'icon': LucideIcons.wind},
    {'id': 'nanny', 'name': 'Enaga', 'icon': LucideIcons.baby},
    // 6 ta YANGI:
    {'id': 'disinfection', 'name': 'Dezinfeksiya', 'icon': LucideIcons.shieldCheck},
    {'id': 'appliance', 'name': 'Texnika ustasi', 'icon': LucideIcons.monitor},
    {'id': 'courier', 'name': 'Kuryerlik', 'icon': LucideIcons.bike},
    {'id': 'massage', 'name': 'Massaj va Hijoma', 'icon': LucideIcons.hand},
    {'id': 'nurse', 'name': 'Hamshira', 'icon': LucideIcons.heartPulse},
    {'id': 'events', 'name': 'Tadbirlar', 'icon': LucideIcons.partyPopper},
  ];

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(child: Builder(builder: (context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohani tanlang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qaysi sohada xizmat ko\'rsatasiz?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sizning sohangizga qarab mijozlar sizni topishadi.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        _selectedCategory = cat['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'],
                            size: 40,
                            color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            cat['name'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF6366F1) : theme.colorScheme.onSurface,
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
                onPressed: _selectedCategory == null 
                  ? null 
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderDataEntryScreen(
                            categoryId: _selectedCategory!,
                            categoryName: _categories.firstWhere((c) => c['id'] == _selectedCategory)['name'],
                          ),
                        ),
                      );
                    },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Davom etish'),
              ),
            ),
          ],
        ),
      ),
    );
    }));
  }
}
