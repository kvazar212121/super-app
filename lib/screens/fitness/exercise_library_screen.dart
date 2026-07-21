import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'fitness_utils.dart';

/// Mashqlar kutubxonasi: qidiruv, filtrlar va cheksiz ro'yxat.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<dynamic> _exercises = [];
  List<dynamic> _bodyParts = [];
  List<dynamic> _equipmentOptions = [];

  String? _selectedBodyPart;
  String? _selectedEquipment;
  int _page = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMeta();
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 400 &&
        !_isLoading &&
        _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await _api.getExerciseMeta();
      if (!mounted) return;
      setState(() {
        _bodyParts = meta['body_parts'] as List<dynamic>? ?? [];
        _equipmentOptions = meta['equipment'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      debugPrint('Meta yuklashda xato: $e');
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (reset) {
        _page = 1;
        _exercises.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await _api.getExercises(
        bodyPart: _selectedBodyPart,
        equipment: _selectedEquipment,
        search: _searchController.text.trim(),
        page: _page,
        pageSize: 20,
      );
      if (!mounted) return;
      final items = response['items'] as List<dynamic>? ?? [];
      setState(() {
        _exercises.addAll(items);
        _total = response['total'] as int? ?? 0;
        _hasMore = _exercises.length < _total;
        _page += 1;
      });
    } catch (e) {
      debugPrint('Mashqlarni yuklashda xato: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadPage(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Mashqlar kutubxonasi'.tr,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: GlassTokens.primaryText(context)),
              decoration: InputDecoration(
                hintText: 'Mashq qidirish…'.tr,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _loadPage(reset: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(
            child: _exercises.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'Hech narsa topilmadi'.tr,
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _exercises.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index >= _exercises.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildExerciseTile(
                        _exercises[index] as Map<String, dynamic>,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Body part chiplar
          ..._bodyParts.map((bp) {
            final value = bp['value'] as String;
            final selected = _selectedBodyPart == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(bp['label_uz'] as String? ?? value),
                selected: selected,
                selectedColor: Colors.teal,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : GlassTokens.primaryText(context),
                ),
                onSelected: (_) {
                  setState(() => _selectedBodyPart = selected ? null : value);
                  _loadPage(reset: true);
                },
              ),
            );
          }),
          // Uskuna filtri (dropdown chip)
          if (_equipmentOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 14,
                  color: _selectedEquipment != null
                      ? Colors.white
                      : GlassTokens.primaryText(context),
                ),
                backgroundColor: _selectedEquipment != null
                    ? Colors.teal
                    : null,
                label: Text(
                  _selectedEquipment != null
                      ? (_equipmentOptions.firstWhere(
                                  (e) => e['value'] == _selectedEquipment,
                                  orElse: () => {
                                    'label_uz': _selectedEquipment,
                                  },
                                )['label_uz']
                                as String? ??
                            _selectedEquipment!)
                      : 'Uskuna'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedEquipment != null
                        ? Colors.white
                        : GlassTokens.primaryText(context),
                  ),
                ),
                onPressed: _showEquipmentPicker,
              ),
            ),
        ],
      ),
    );
  }

  void _showEquipmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTokens.glassFill(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GlassTokens.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ListTile(
              title: Text(
                'Barcha uskunalar'.tr,
                style: TextStyle(color: GlassTokens.primaryText(context)),
              ),
              leading: Icon(
                _selectedEquipment == null
                    ? LucideIcons.circleCheck
                    : LucideIcons.circle,
                color: Colors.teal,
                size: 18,
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedEquipment = null);
                _loadPage(reset: true);
              },
            ),
            ..._equipmentOptions.map((eq) {
              final value = eq['value'] as String;
              return ListTile(
                title: Text(
                  eq['label_uz'] as String? ?? value,
                  style: TextStyle(color: GlassTokens.primaryText(context)),
                ),
                leading: Icon(
                  _selectedEquipment == value
                      ? LucideIcons.circleCheck
                      : LucideIcons.circle,
                  color: Colors.teal,
                  size: 18,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedEquipment = value);
                  _loadPage(reset: true);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(Map<String, dynamic> exercise) {
    final gifUrl = exercise['gif_url'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
        border: Border.all(color: GlassTokens.glassBorder(context)),
      ),
      child: ListTile(
        onTap: () => showExerciseDetailSheet(context, exercise: exercise),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: gifUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: gifUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _gifPlaceholder(),
                  errorWidget: (_, _, _) => _gifPlaceholder(),
                )
              : _gifPlaceholder(),
        ),
        title: Text(
          exercise['name_uz'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: GlassTokens.primaryText(context),
          ),
        ),
        subtitle: Text(
          [
            exercise['body_part_uz'] ?? exercise['body_part'],
            exercise['equipment_uz'] ?? exercise['equipment'],
          ].whereType<String>().join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: GlassTokens.secondaryText(context),
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: GlassTokens.secondaryText(context),
        ),
      ),
    );
  }

  Widget _gifPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.tealAccent.withValues(alpha: 0.1),
      child: const Icon(LucideIcons.dumbbell, color: Colors.teal, size: 22),
    );
  }
}
