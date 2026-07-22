import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/meal_reminder_service.dart';
import 'calorie_analyze_screen.dart';

/// "Ovqat qildingizmi?" modali — eslatma bosilganda yoki panel ochilganda.
/// 3 yo'l: 📷 rasm (AI), ✍️ matn (AI taxmin + qo'lda), ⏭️ yemadim/keyin.
class MealCheckDialog {
  static const _blue = Color(0xFF3B82F6);

  static Future<void> show(BuildContext context, String mealType) async {
    final label = MealReminderService.labelFor(mealType);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '$label qildingizmi?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nima yeganingizni belgilang — kaloriya hisobiga qo\'shiladi.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _option(
                icon: Icons.photo_camera_rounded,
                title: 'Rasmga olish',
                subtitle: 'AI taomni aniqlab kaloriyani hisoblaydi',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(context, mealType);
                },
              ),
              const SizedBox(height: 10),
              _option(
                icon: Icons.edit_note_rounded,
                title: 'Yozib berish',
                subtitle: '"2 ta non, choy" — AI kaloriyani taxminlaydi',
                onTap: () {
                  Navigator.pop(ctx);
                  _showTextEntry(context, mealType);
                },
              ),
              const SizedBox(height: 10),
              _option(
                icon: Icons.skip_next_rounded,
                title: 'Yemadim / keyinroq',
                subtitle: 'Bu ovqat bugun qayta so\'ralmaydi',
                muted: true,
                onTap: () async {
                  await MealReminderService().markHandled(mealType);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _option({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    final color = muted ? Colors.grey[600]! : _blue;
    return Material(
      color: muted ? Colors.grey[100] : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: muted ? Colors.grey[800] : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _pickPhoto(BuildContext context, String mealType) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked == null || !context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalorieAnalyzeScreen(imageFile: File(picked.path)),
        ),
      );
      // Rasm oqimidan qaytdi — shu ovqat bugun qayta so'ralmaydi.
      await MealReminderService().markHandled(mealType);
    } catch (_) {}
  }

  static void _showTextEntry(BuildContext context, String mealType) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MealTextDialog(mealType: mealType),
    );
  }
}

/// Matn bilan ovqat kiritish: yozadi → AI taxminlaydi → qo'lda to'g'rilaydi → saqlaydi.
class _MealTextDialog extends StatefulWidget {
  final String mealType;
  const _MealTextDialog({required this.mealType});

  @override
  State<_MealTextDialog> createState() => _MealTextDialogState();
}

class _MealTextDialogState extends State<_MealTextDialog> {
  final _textCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  bool _analyzing = false;
  bool _analyzed = false; // AI natija keldimi (natija maydonlari ko'rinsinmi)
  bool _saving = false;
  double _protein = 0, _fat = 0, _carbs = 0;

  static const _blue = Color(0xFF3B82F6);

  @override
  void dispose() {
    _textCtrl.dispose();
    _nameCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _analyzing = true);
    try {
      final res = await ApiService().analyzeFoodText(text);
      _nameCtrl.text = (res['dish_name_uz'] ?? text).toString();
      _calCtrl.text = ((res['calories'] as num?)?.round() ?? 0).toString();
      _protein = (res['protein_g'] as num?)?.toDouble() ?? 0;
      _fat = (res['fat_g'] as num?)?.toDouble() ?? 0;
      _carbs = (res['carbs_g'] as num?)?.toDouble() ?? 0;
      if (mounted) setState(() => _analyzed = true);
    } catch (e) {
      // AI ishlamasa — qo'lda kiritishga o'tamiz (nomni matndan olamiz).
      _nameCtrl.text = text;
      _calCtrl.text = _calCtrl.text.isEmpty ? '' : _calCtrl.text;
      if (mounted) {
        setState(() => _analyzed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI taxminlay olmadi — kaloriyani qo\'lda kiriting'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _save() async {
    final cal = double.tryParse(_calCtrl.text.trim()) ?? 0;
    final name = _nameCtrl.text.trim().isEmpty
        ? _textCtrl.text.trim()
        : _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService().logMeal({
        'meal_type': widget.mealType,
        'dish_name': name,
        'calories': cal,
        'protein_g': _protein,
        'fat_g': _fat,
        'carbs_g': _carbs,
      });
      await MealReminderService().markHandled(widget.mealType);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name qo\'shildi (${cal.round()} kkal)')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saqlab bo\'lmadi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${MealReminderService.labelFor(widget.mealType)} — nima yedingiz?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textCtrl,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Masalan: 2 ta non, bir kosa osh, choy',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _analyzing ? null : _analyze,
                icon: _analyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18, color: _blue),
                label: Text(
                  _analyzing ? 'Tahlil qilinmoqda...' : 'AI bilan taxminlash',
                  style: const TextStyle(color: _blue),
                ),
              ),
            ),
            if (_analyzed) ...[
              const Divider(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Taom nomi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kaloriya (kkal)',
                  helperText: 'AI taxmini — to\'g\'rilashingiz mumkin',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor'),
        ),
        FilledButton(
          onPressed: (!_analyzed || _saving) ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Saqlash'),
        ),
      ],
    );
  }
}
