import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

import '../../l10n/locale_controller.dart';
import '../../models/alarm.dart';
import '../../services/api_service.dart';
import '../../services/notification_helper.dart';
import '../../theme/lux_tokens.dart';

/// Budilnik jiringlaganda ochiladigan to'liq-ekranli ekran.
/// Baland ovozda jiringlaydi, orqaga qaytishni bloklaydi va vazifa bajarilgunicha o'chmaydi.
class AlarmRingScreen extends StatefulWidget {
  final Alarm alarm;
  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  final _api = ApiService();
  DateTime? _firedAt;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _firedAt = DateTime.now();
    _startRinging();
  }

  Future<void> _startRinging() async {
    WakelockPlus.enable();
    try {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {}
  }

  Future<void> _stopRinging() async {
    try {
      await FlutterRingtonePlayer().stop();
    } catch (_) {}
    WakelockPlus.disable();
  }

  Future<void> _onMissionSolved() async {
    if (_dismissed) return;
    _dismissed = true;
    await _stopRinging();

    // Statistikani backendga yozamiz (offline bo'lsa jim o'tadi)
    final dismissedAt = DateTime.now();
    final seconds = _firedAt != null
        ? dismissedAt.difference(_firedAt!).inSeconds
        : null;
    try {
      await _api.logAlarmEvent(widget.alarm.id, {
        'fired_at': _firedAt?.toUtc().toIso8601String(),
        'dismissed_at': dismissedAt.toUtc().toIso8601String(),
        'dismiss_seconds': seconds,
        'snooze_count': 0,
      });
    } catch (_) {}

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSnooze() async {
    if (_dismissed) return;
    _dismissed = true;
    await _stopRinging();
    await NotificationHelper().snoozeAlarm(widget.alarm);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stopRinging();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false, // orqaga tugma budilnikni o'chirmaydi
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  timeStr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  widget.alarm.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.alarm, color: LuxTokens.goldSoft, size: 40),
                const SizedBox(height: 16),
                Expanded(
                  child: _MissionArea(
                    alarm: widget.alarm,
                    onSolved: _onMissionSolved,
                  ),
                ),
                if (widget.alarm.snoozeEnabled)
                  TextButton(
                    onPressed: _onSnooze,
                    child: Text(
                      'Snooze (${widget.alarm.snoozeMinutes} ${'daqiqa'.tr})',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vazifa turini tanlab, tegishli vidjetni ko'rsatadi.
class _MissionArea extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onSolved;
  const _MissionArea({required this.alarm, required this.onSolved});

  @override
  Widget build(BuildContext context) {
    switch (alarm.missionType) {
      case 'photo':
        return _PhotoMission(alarm: alarm, onSolved: onSolved);
      case 'speech':
        return _SpeechMission(alarm: alarm, onSolved: onSolved);
      case 'math':
      default:
        return _MathMission(alarm: alarm, onSolved: onSolved);
    }
  }
}

// ─────────────────────────── MATEMATIK VAZIFA ───────────────────────────

class _MathMission extends StatefulWidget {
  final Alarm alarm;
  final VoidCallback onSolved;
  const _MathMission({required this.alarm, required this.onSolved});

  @override
  State<_MathMission> createState() => _MathMissionState();
}

class _MathMissionState extends State<_MathMission> {
  final _rand = Random();
  final _controller = TextEditingController();
  late int _a, _b, _c, _answer;
  late String _op;
  int _solved = 0;
  late int _needed;

  @override
  void initState() {
    super.initState();
    _needed = (widget.alarm.missionConfig['count'] as int?) ?? 1;
    if (_needed < 1) _needed = 1;
    _generate();
  }

  void _generate() {
    final difficulty =
        (widget.alarm.missionConfig['difficulty'] as String?) ?? 'medium';
    switch (difficulty) {
      case 'easy':
        _a = _rand.nextInt(20) + 1;
        _b = _rand.nextInt(20) + 1;
        _op = '+';
        _answer = _a + _b;
        _c = 0;
        break;
      case 'hard':
        _a = _rand.nextInt(13) + 2;
        _b = _rand.nextInt(13) + 2;
        _c = _rand.nextInt(40) + 10;
        _op = '×+';
        _answer = _a * _b + _c;
        break;
      case 'medium':
      default:
        _a = _rand.nextInt(60) + 10;
        _b = _rand.nextInt(60) + 10;
        _op = '+';
        _answer = _a + _b;
        _c = 0;
    }
    _controller.clear();
    setState(() {});
  }

  String get _questionText {
    if (_op == '×+') return '$_a × $_b + $_c = ?';
    return '$_a $_op $_b = ?';
  }

  void _check() {
    final val = int.tryParse(_controller.text.trim());
    if (val == _answer) {
      _solved++;
      if (_solved >= _needed) {
        widget.onSolved();
      } else {
        _generate();
      }
    } else {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Noto\'g\'ri, qayta urinib ko\'ring'.tr),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_needed > 1)
          Text(
            '$_solved / $_needed',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        const SizedBox(height: 8),
        Text(
          _questionText,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
          ],
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Javob'.tr,
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: LuxTokens.goldSoft),
            ),
          ),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxTokens.goldSoft,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _check,
            child: Text(
              'Tasdiqlash'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── RASM VAZIFASI ───────────────────────────

class _PhotoMission extends StatefulWidget {
  final Alarm alarm;
  final VoidCallback onSolved;
  const _PhotoMission({required this.alarm, required this.onSolved});

  @override
  State<_PhotoMission> createState() => _PhotoMissionState();
}

class _PhotoMissionState extends State<_PhotoMission> {
  final _picker = ImagePicker();
  final _api = ApiService();
  bool _busy = false;
  String? _status;

  String get _targetUz =>
      (widget.alarm.missionConfig['target_uz'] as String?) ??
      'belgilangan narsa';
  String get _targetForAi =>
      (widget.alarm.missionConfig['target_en'] as String?) ??
      (widget.alarm.missionConfig['target_uz'] as String?) ??
      'the target object';

  Future<void> _takeAndVerify() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (!mounted) return;
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );
      final path = compressed?.path ?? picked.path;

      final result = await _api.verifyAlarmPhoto(path, _targetForAi);
      if (!mounted) return;
      final matched = result['matched'] == true;
      if (matched) {
        widget.onSolved();
      } else {
        setState(() {
          _busy = false;
          _status = (result['detail'] as String?)?.isNotEmpty == true
              ? result['detail'] as String
              : '${'Rasmda'.tr} "${_targetUz.tr}" ${'topilmadi. Qayta urinib ko\'ring.'.tr}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Xatolik: internetni tekshiring va qayta urinib ko\'ring'.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt, color: LuxTokens.goldSoft, size: 48),
        const SizedBox(height: 16),
        Text(
          'Shuni rasmga oling:'.tr,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          _targetUz.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _status!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxTokens.goldSoft,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _busy ? null : _takeAndVerify,
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.photo_camera),
            label: Text(
              _busy ? 'Tekshirilmoqda...'.tr : 'Kamerani ochish'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── NUTQ (MATNNI O'QISH) VAZIFASI ───────────────────────────

class _SpeechMission extends StatefulWidget {
  final Alarm alarm;
  final VoidCallback onSolved;
  const _SpeechMission({required this.alarm, required this.onSolved});

  @override
  State<_SpeechMission> createState() => _SpeechMissionState();
}

class _SpeechMissionState extends State<_SpeechMission> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _recognized = '';
  String _locale = 'uz_UZ';

  static const List<String> _defaultPhrases = [
    'Men bugun erta turdim va kunni zabt etaman',
    'Yangi kun yangi imkoniyatlar olib keladi',
    'Uyqu tugadi endi harakat vaqti keldi',
    'Bugun o\'zimni yaxshi his qilaman va tayyorman',
  ];

  late String _phrase;

  @override
  void initState() {
    super.initState();
    final configPhrase = widget.alarm.missionConfig['phrase_uz'] as String?;
    if (configPhrase != null && configPhrase.trim().isNotEmpty) {
      _phrase = configPhrase.trim();
    } else {
      _phrase = _defaultPhrases[DateTime.now().second % _defaultPhrases.length];
    }
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _available = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _listening = false);
            _evaluate();
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (_available) {
        final locales = await _speech.locales();
        for (final loc in locales) {
          if (loc.localeId.startsWith('uz')) {
            _locale = loc.localeId;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9а-яўқғҳ' ]", unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Tanilgan matn iboraga yetarlicha o'xshasa (so'zlarning 70% mos kelsa) — muvaffaqiyat.
  void _evaluate() {
    if (_recognized.isEmpty) return;
    final target = _normalize(
      _phrase,
    ).split(' ').where((w) => w.isNotEmpty).toSet();
    final said = _normalize(
      _recognized,
    ).split(' ').where((w) => w.isNotEmpty).toSet();
    if (target.isEmpty) return;
    final matched = target.where(said.contains).length;
    final ratio = matched / target.length;
    if (ratio >= 0.7) {
      widget.onSolved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('To\'liq o\'qing, qayta urinib ko\'ring'.tr),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _listen() async {
    if (!_available) return;
    setState(() {
      _listening = true;
      _recognized = '';
    });
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _recognized = r.recognizedWords);
      },
      localeId: _locale,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.record_voice_over, color: LuxTokens.goldSoft, size: 48),
        const SizedBox(height: 12),
        Text(
          'Ushbu matnni ovoz chiqarib o\'qing:'.tr,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _phrase,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_recognized.isNotEmpty)
          Text(
            '"$_recognized"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _listening
                  ? Colors.redAccent
                  : LuxTokens.goldSoft,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _available && !_listening ? _listen : null,
            icon: Icon(_listening ? Icons.mic : Icons.mic_none),
            label: Text(
              !_available
                  ? 'Mikrofon mavjud emas'.tr
                  : (_listening
                        ? 'Eshitilmoqda...'.tr
                        : 'O\'qishni boshlash'.tr),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
