import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import 'job_offers_screen.dart';
import '../theme/lux_tokens.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_surface.dart';
import '../l10n/locale_controller.dart';

/// Mijozning ish e'lonlari: ro'yxat + yangi e'lon berish.
class MyJobsScreen extends StatefulWidget {
  final bool embedded;

  const MyJobsScreen({super.key, this.embedded = false});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final ApiService _api = ApiService();
  List<JobPost> _jobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.getMyJobs();
      if (!mounted) return;
      setState(() {
        _jobs = raw
            .map((e) => JobPost.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'E\'lonlarni yuklab bo\'lmadi'.tr;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.embedded ? Colors.transparent : Colors.white,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text('Mening e\'lonlarim'.tr),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
      floatingActionButton: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: LuxTokens.goldGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: _openCreate,
          borderRadius: BorderRadius.circular(26),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.plus, color: Color(0xFF140D02), size: 20),
              const SizedBox(width: 8),
              Text(
                'E\'lon berish'.tr,
                style: const TextStyle(
                  color: Color(0xFF140D02),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: LuxTokens.gold,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        const Icon(LucideIcons.wifiOff, size: 52, color: Color(0xFF64748B)),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF0F172A))),
        const SizedBox(height: 14),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxTokens.gold,
              foregroundColor: const Color(0xFF140D02),
            ),
            onPressed: _load,
            child: Text('Qayta urinish'.tr),
          ),
        ),
      ]);
    }
    if (_jobs.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: GlassSurface(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            borderRadius: GlassTokens.radiusLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LuxTokens.gold.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.clipboardList,
                    size: 40,
                    color: Color(0xFF140D02),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hali e\'lon bermagansiz'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF140D02),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"E\'lon berish" tugmasini bosing — ustalar sizga taklif yuborishadi.'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF332205),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _jobs.length,
      itemBuilder: (_, i) => _jobCard(_jobs[i]),
    );
  }

  Widget _jobCard(JobPost job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuxTokens.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: LuxTokens.gold.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobOffersScreen(job: job)),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(job.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              Row(
                children: [
                  if (job.budget != null) ...[
                    const Icon(LucideIcons.banknote, size: 15, color: Color(0xFF8A5D0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${job.budget!.toStringAsFixed(0)} ${'so\'m'.tr}',
                      style: const TextStyle(
                        color: Color(0xFF8A5D0B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  const Icon(LucideIcons.messageSquare, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '${job.offersCount} ${'taklif'.tr}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (job.photos.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    const Icon(LucideIcons.image, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${job.photos.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(JobStatus s) {
    Color bg;
    Color border;
    Color text;
    IconData icon;

    switch (s) {
      case JobStatus.open:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFF8A5D0B);
        icon = LucideIcons.sparkles;
        break;
      case JobStatus.assigned:
      case JobStatus.completed:
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF15803D);
        icon = LucideIcons.circleCheck;
        break;
      default:
        bg = const Color(0xFFFFF1F2);
        border = const Color(0xFFFECDD3);
        text = const Color(0xFF9F1239);
        icon = LucideIcons.circleX;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            jobStatusLabel(s),
            style: TextStyle(color: text, fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateJobScreen()),
    );
    if (created == true) _load();
  }
}

/// Yangi e'lon berish formasi.
class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _budget = TextEditingController();

  int? _categoryId;
  List<dynamic> _categories = [];
  DateTime? _neededAt;
  final List<String> _photoUrls = [];
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.getCategories();
      if (!mounted) return;
      setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _uploading = true);
      final url = await _api.uploadJobPhoto(picked.path);
      if (!mounted) return;
      setState(() {
        _photoUrls.add(url);
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Rasmni yuklab bo\'lmadi'.tr)),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohani tanlang'.tr)),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await _api.createJob({
        'category_id': _categoryId,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'photos': _photoUrls,
        if (_budget.text.trim().isNotEmpty)
          'budget': double.tryParse(_budget.text.trim().replaceAll(' ', '')),
        if (_neededAt != null) 'needed_at': _neededAt!.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('E\'lon berildi! Ustalar taklif yuborishadi.'.tr)),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('E\'lon berib bo\'lmadi'.tr)),
      );
    }
  }

  InputDecoration _inputDeco(String label, {String? hint, String? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Color(0xFF8A5D0B), fontWeight: FontWeight.w700),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LuxTokens.gold, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('E\'lon berish'.tr),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: _inputDeco('Qaysi soha ustasi kerak *'.tr),
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              items: _categories
                  .map((c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text('${c['title_uz'] ?? c['key']}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              decoration: _inputDeco('Sarlavha *'.tr, hint: 'Masalan: Rozetka almashtirish'.tr),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Kamida 3 ta harf'.tr
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              decoration: _inputDeco('Nima qilish kerak *'.tr, hint: 'Batafsil yozing — usta aniqroq narx aytadi'.tr),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Batafsilroq yozing'.tr
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              decoration: _inputDeco('Manzil *'.tr),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Manzilni yozing'.tr : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              decoration: _inputDeco(
                'Taxminiy summa (ixtiyoriy)'.tr,
                hint: 'Bo\'sh qoldirsangiz ustalar o\'zi narx aytadi'.tr,
                suffix: 'so\'m',
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: ListTile(
                leading: const Icon(LucideIcons.calendar, color: LuxTokens.gold, size: 22),
                title: Text(
                  _neededAt == null
                      ? 'Qachon kerak? (ixtiyoriy)'.tr
                      : '${_neededAt!.day}.${_neededAt!.month}.${_neededAt!.year}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                trailing: const Icon(LucideIcons.chevronRight, color: Color(0xFF64748B)),
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _neededAt = d);
                },
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.camera, color: LuxTokens.gold, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ish joyining rasmi'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                  ),
                  if (_uploading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: LuxTokens.gold),
                    )
                  else
                    TextButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(LucideIcons.imagePlus, size: 18, color: Color(0xFF8A5D0B)),
                      label: Text('Qo\'shish'.tr, style: const TextStyle(color: Color(0xFF8A5D0B), fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
            if (_photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(LucideIcons.image, size: 30, color: Color(0xFF64748B)),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photoUrls.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LuxTokens.goldGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF140D02),
                        ),
                      )
                    : Text(
                        'E\'lon berish'.tr,
                        style: const TextStyle(
                          color: Color(0xFF140D02),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
