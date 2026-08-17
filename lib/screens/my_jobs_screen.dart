import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import 'job_offers_screen.dart';

/// Mijozning ish e'lonlari: ro'yxat + yangi e'lon berish.
///
/// Foydalanuvchi talabi: "ish qilinadigan joyni rasmga olib, summani
/// yozib, qachon qilinish kerakligini yozib e'lon berib qo'yilishi kerak".
class MyJobsScreen extends StatefulWidget {
  /// [embedded] — "Buyurtmalarim" ekrani ichidagi tab sifatida ochilgan
  /// (o'z AppBar'i kerak emas, fon tashqi ekrandan keladi).
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
        _error = 'E\'lonlarni yuklab bo\'lmadi';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.embedded ? Colors.transparent : null,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Mening e\'lonlarim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('E\'lon berish'),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.wifi_off, size: 52, color: theme.hintColor),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        Center(
          child: FilledButton(
            onPressed: _load,
            child: const Text('Qayta urinish'),
          ),
        ),
      ]);
    }
    if (_jobs.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.assignment_outlined, size: 56, color: theme.hintColor),
        const SizedBox(height: 14),
        Text(
          'Hali e\'lon bermagansiz.\n"E\'lon berish" tugmasini bosing —\n'
          'ustalar sizga taklif yuborishadi.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _jobs.length,
      itemBuilder: (_, i) => _jobCard(theme, _jobs[i]),
    );
  }

  Widget _jobCard(ThemeData theme, JobPost job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobOffersScreen(job: job)),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _statusChip(theme, job.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                job.address,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (job.budget != null) ...[
                    Icon(Icons.payments_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${job.budget!.toStringAsFixed(0)} so\'m',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Icon(Icons.mark_email_unread_outlined,
                      size: 16, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('${job.offersCount} taklif'),
                  if (job.photos.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    Icon(Icons.photo_outlined,
                        size: 16, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text('${job.photos.length}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme, JobStatus s) {
    Color c;
    switch (s) {
      case JobStatus.open:
        c = const Color(0xFF0EA5E9);
        break;
      case JobStatus.assigned:
        c = const Color(0xFF10B981);
        break;
      case JobStatus.completed:
        c = theme.hintColor;
        break;
      default:
        c = const Color(0xFFEF4444);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        jobStatusLabel(s),
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
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
    } catch (_) {
      // Kategoriyasiz forma ham ko'rsatiladi, lekin saqlab bo'lmaydi
    }
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
        const SnackBar(content: Text('Rasmni yuklab bo\'lmadi')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sohani tanlang')),
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
        const SnackBar(content: Text('E\'lon berildi! Ustalar taklif yuborishadi.')),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('E\'lon berib bo\'lmadi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('E\'lon berish')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Qaysi soha ustasi kerak *',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text('${c['title_uz'] ?? c['key']}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Sarlavha *',
                hintText: 'Masalan: Rozetka almashtirish',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Kamida 3 ta harf'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nima qilish kerak *',
                hintText: 'Batafsil yozing — usta aniqroq narx aytadi',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Batafsilroq yozing'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Manzil *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Manzilni yozing' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Taxminiy summa (ixtiyoriy)',
                hintText: 'Bo\'sh qoldirsangiz ustalar o\'zi narx aytadi',
                suffixText: 'so\'m',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // "qachon qilinish kerakligini yozib"
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_neededAt == null
                  ? 'Qachon kerak? (ixtiyoriy)'
                  : '${_neededAt!.day}.${_neededAt!.month}.${_neededAt!.year}'),
              trailing: const Icon(Icons.chevron_right),
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
            const Divider(),

            // "ish qilinadigan joyni rasmga olib"
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined),
                const SizedBox(width: 8),
                const Expanded(child: Text('Ish joyining rasmi')),
                if (_uploading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('Qo\'shish'),
                  ),
              ],
            ),
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 84,
                          height: 84,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image, size: 30),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _photoUrls.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('E\'lon berish'),
            ),
          ],
        ),
      ),
    );
  }
}
