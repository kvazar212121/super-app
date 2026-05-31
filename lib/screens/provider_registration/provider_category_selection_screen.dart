import 'package:flutter/material.dart';
import '../../config/provider_category_config.dart';
import '../../services/api_service.dart';
import '../provider_side/provider_theme.dart';
import 'provider_data_entry_screen.dart';

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
        if (config == null) continue;
        items.add({
          'id': config.registrationId,
          'dbId': c['id'],
          'name': c['title']?.toString() ?? config.title,
          'icon': config.icon,
        });
      }
      _categories = items;
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
            appBar: AppBar(title: const Text('Sohani tanlang')),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qaysi sohada xizmat ko\'rsatasiz?',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sizning sohangizga qarab mijozlar sizni topishadi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                              final isSelected =
                                  _selectedCategory == cat['id'];

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
                                        ? const Color(0xFF6366F1)
                                            .withValues(alpha: 0.1)
                                        : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey.withValues(alpha: 0.2),
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
                                            ? const Color(0xFF6366F1)
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
                                                ? const Color(0xFF6366F1)
                                                : theme.colorScheme.onSurface,
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
                                  builder: (context) => ProviderDataEntryScreen(
                                    categoryId: cat['id'] as String,
                                    categoryName: cat['name'] as String,
                                    categoryDbId: cat['dbId'] as int?,
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
        },
      ),
    );
  }
}
