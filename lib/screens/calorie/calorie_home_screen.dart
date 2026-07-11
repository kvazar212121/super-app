import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../services/step_tracker_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'calorie_analyze_screen.dart';
import 'calorie_profile_screen.dart';

/// Ovqat turlari nomlari (analyze ekranida ham ishlatiladi).
const Map<String, String> kMealTypeNames = {
  'breakfast': 'Nonushta',
  'lunch': 'Tushlik',
  'dinner': 'Kechki ovqat',
  'snack': 'Gazak',
};

/// Kaloriya hisoblagich — kunlik xulosa, ovqat jurnali va kamera orqali tahlil.
class CalorieHomeScreen extends StatefulWidget {
  const CalorieHomeScreen({super.key});

  @override
  State<CalorieHomeScreen> createState() => _CalorieHomeScreenState();
}

class _CalorieHomeScreenState extends State<CalorieHomeScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _summary;
  List<dynamic> _meals = [];
  bool _isLoading = true;
  bool _profileChecked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkProfile();
    _initSteps();
  }

  /// Qadam sensorini yoqib, bugungi qadamni serverga sinxronlaymiz — shunda
  /// net byudjet (yoqilgan kaloriya) yangilanadi.
  Future<void> _initSteps() async {
    try {
      await StepTrackerService().init();
      await StepTrackerService().syncNow();
      if (_isToday) _loadData();
    } catch (_) {}
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _checkProfile() async {
    if (_profileChecked) return;
    _profileChecked = true;
    try {
      final profile = await _api.getNutritionProfile();
      if (profile == null && mounted) {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const CalorieProfileScreen(isFirstSetup: true),
          ),
        );
        if (saved == true) _loadData();
      }
    } catch (e) {
      debugPrint('Profil tekshirishda xato: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final date = _formatDateForApi(_selectedDate);
      final results = await Future.wait([
        _api.getCalorieSummary(date: date),
        _api.getMealLogs(date: date),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _meals = results[1] as List<dynamic>;
      });
    } catch (e) {
      debugPrint('Kaloriya ma\'lumotlarini yuklashda xato: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeDate(int deltaDays) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    });
    _loadData();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null || !mounted) return;

      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 65,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );
      if (compressedFile == null || !mounted) return;

      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CalorieAnalyzeScreen(imageFile: File(compressedFile.path)),
        ),
      );
      if (saved == true) _loadData();
    } catch (e) {
      debugPrint('Rasm olishda xato: $e');
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTokens.glassFill(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GlassTokens.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Colors.redAccent),
              title: Text(
                'Kamera'.tr,
                style: TextStyle(color: GlassTokens.primaryText(context)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.redAccent),
              title: Text(
                'Galereya'.tr,
                style: TextStyle(color: GlassTokens.primaryText(context)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMeal(int id) async {
    try {
      await _api.deleteMealLog(id);
      _loadData();
    } catch (e) {
      debugPrint('O\'chirishda xato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Kaloriya hisoblagich'.tr,
      actions: [
        IconButton(
          icon: Icon(LucideIcons.userCog),
          tooltip: 'Profil'.tr,
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CalorieProfileScreen()),
            );
            if (saved == true) _loadData();
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPhotoSourceSheet,
        backgroundColor: Colors.redAccent,
        icon: const Icon(LucideIcons.camera, color: Colors.white),
        label: Text(
          'Suratga olish'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _buildDateSelector(),
            const SizedBox(height: 12),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_meals.isEmpty)
              _buildEmptyState()
            else
              ..._buildMealGroups(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeDate(-1),
          icon: Icon(
            LucideIcons.chevronLeft,
            color: GlassTokens.primaryText(context),
          ),
        ),
        Text(
          _isToday ? 'Bugun'.tr : _formatDateForApi(_selectedDate),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: GlassTokens.primaryText(context),
          ),
        ),
        IconButton(
          onPressed: _isToday ? null : () => _changeDate(1),
          icon: Icon(
            LucideIcons.chevronRight,
            color: _isToday
                ? GlassTokens.secondaryText(context).withValues(alpha: 0.3)
                : GlassTokens.primaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final total = (_summary?['total_calories'] as num?)?.toDouble() ?? 0;
    final goal = (_summary?['goal_calories'] as num?)?.toDouble();
    final protein = (_summary?['protein_g'] as num?)?.toDouble() ?? 0;
    final fat = (_summary?['fat_g'] as num?)?.toDouble() ?? 0;
    final carbs = (_summary?['carbs_g'] as num?)?.toDouble() ?? 0;
    // Net model: yoqilgan kaloriya (mashq + yurish) kunlik byudjetni oshiradi
    final burned = (_summary?['calories_burned'] as num?)?.toDouble() ?? 0;
    final steps = (_summary?['steps'] as num?)?.toInt() ?? 0;
    final netGoal = goal != null ? goal + burned : null;
    final progress = (netGoal != null && netGoal > 0)
        ? (total / netGoal).clamp(0.0, 1.0)
        : 0.0;
    final over = netGoal != null && total > netGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        border: Border.all(color: GlassTokens.glassBorder(context)),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: goal != null ? progress : null,
                      strokeWidth: 9,
                      backgroundColor: GlassTokens.glassBorder(context),
                      valueColor: AlwaysStoppedAnimation(
                        over ? Colors.orangeAccent : Colors.redAccent,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total.round().toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          'kkal'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: GlassTokens.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      netGoal != null
                          ? '${'Maqsad'.tr}: ${netGoal.round()} ${'kkal'.tr}'
                          : 'Maqsad belgilanmagan'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      netGoal != null
                          ? (over
                                ? '${(total - netGoal).round()} ${'kkal oshib ketdi'.tr}'
                                : '${(netGoal - total).round()} ${'kkal qoldi'.tr}')
                          : 'Profilni to\'ldiring'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                    if (burned > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🔥 ${burned.round()} ${'kkal yoqildi'.tr}'
                        '${steps > 0 ? ' · $steps ${'qadam'.tr}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ],
                    SizedBox(height: 12),
                    _buildMacroRow('Oqsil'.tr, protein, Colors.blueAccent),
                    _buildMacroRow('Yog\''.tr, fat, Colors.orangeAccent),
                    _buildMacroRow('Uglevod'.tr, carbs, Colors.greenAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, double grams, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: GlassTokens.secondaryText(context),
            ),
          ),
          Text(
            '${grams.round()} g',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GlassTokens.primaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            LucideIcons.utensils,
            size: 48,
            color: GlassTokens.secondaryText(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu kunda ovqat qayd etilmagan'.tr,
            style: TextStyle(color: GlassTokens.secondaryText(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Taomni suratga oling — AI kaloriyasini hisoblab beradi'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: GlassTokens.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealGroups() {
    final widgets = <Widget>[];
    for (final type in kMealTypeNames.keys) {
      final group = _meals.where((m) => m['meal_type'] == type).toList();
      if (group.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            kMealTypeNames[type]!.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: GlassTokens.primaryText(context),
            ),
          ),
        ),
      );
      widgets.addAll(group.map((m) => _buildMealTile(m)));
    }
    return widgets;
  }

  Widget _buildMealTile(dynamic meal) {
    final photoUrl = AppConfig.formatImageUrl(meal['photo_url'] as String?);
    return Dismissible(
      key: ValueKey('meal_${meal['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteMeal(meal['id'] as int),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
        ),
        child: Icon(LucideIcons.trash2, color: Colors.redAccent),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GlassTokens.glassFill(context),
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          border: Border.all(color: GlassTokens.glassBorder(context)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _mealIconBox(),
                    )
                  : _mealIconBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['dish_name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (meal['portion_grams'] != null)
                        '${(meal['portion_grams'] as num).round()} g',
                      'O: ${(meal['protein_g'] as num?)?.round() ?? 0}g',
                      'Y: ${(meal['fat_g'] as num?)?.round() ?? 0}g',
                      'U: ${(meal['carbs_g'] as num?)?.round() ?? 0}g',
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(meal['calories'] as num?)?.round() ?? 0}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
              ),
            ),
            Text(
              ' ${'kkal'.tr}',
              style: TextStyle(
                fontSize: 12,
                color: GlassTokens.secondaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealIconBox() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.redAccent.withValues(alpha: 0.12),
      child: const Icon(
        LucideIcons.utensils,
        color: Colors.redAccent,
        size: 22,
      ),
    );
  }
}
