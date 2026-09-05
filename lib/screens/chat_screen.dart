import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../models/master_worker.dart';
import 'orders_screen.dart';
import 'provider_profile_screen.dart';
import 'todo_screen.dart';
import 'finance_manager_screen.dart';
import 'shopping_list_screen.dart';
import 'all_categories_screen.dart';
import 'profile_screen.dart';
import 'alarm/alarm_home_screen.dart';
import 'calorie/calorie_home_screen.dart';
import 'fitness/fitness_home_screen.dart';
import 'calls/call_history_screen.dart';
import 'premium/premium_screen.dart';
import '../models/service_hub_kind.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';
import '../models/marketplace/listing.dart';
import '../widgets/marketplace/listing_grid.dart';
import '../widgets/marketplace/listing_modal.dart';
import '../theme/lux_tokens.dart';

enum _VoiceState { idle, recording, processing }

class ChatScreen extends StatefulWidget {
  final bool startVoice;

  /// TEST uchun: rasm allaqachon tanlangan holatni tiklaydi.
  ///
  /// Kamera/galereya test muhitida ishlamaydi, shuning uchun "rasm
  /// kutyapti" holatini boshqa yo'l bilan yaratib bo'lmaydi. Bu
  /// maydonsiz eng muhim xatti-harakat (rasm bor -> yuborish tugmasi)
  /// haqiqiy widget bilan sinalmay qolardi.
  ///
  /// Ishlab turgan ilovada hech qachon berilmaydi.
  @visibleForTesting
  final XFile? initialPhoto;

  const ChatScreen({
    super.key,
    this.startVoice = false,
    this.initialPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final AiService _aiService = AiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isTyping = false;
  bool _hasText = false;

  /// Tanlangan, LEKIN hali yuborilmagan rasm.
  ///
  /// Foydalanuvchi talabi: rasm tanlanishi bilan darhol ketmasin —
  /// avval tagiga matn yozish imkoni bo'lsin. Rasm faqat "yuborish"
  /// bosilganda (yoki matn bilan birga) jo'natiladi.
  XFile? _pendingPhoto;

  /// Rasm serverga yuklanayotgan payt (ikki marta bosilmasin).
  bool _photoUploading = false;

  // Speech to Text variables
  _VoiceState _voiceState = _VoiceState.idle;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  String _speechLocale = 'uz_UZ';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  // Mikrofon ovoz balandligi (modal ekvalayzerni jonlantirish uchun). ValueNotifier
  // orqali — butun ekranни qayta chizmasdan silliq yangilanadi.
  final ValueNotifier<double> _soundLevelVN = ValueNotifier<double>(0.0);
  // Ovoz yozish paytida ko'rinadigan modal overlay (gapirib bo'lgach yo'qoladi).
  OverlayEntry? _voiceOverlay;
  // dispose'дан keyin kech kelган speech callback disposed notifier'ga yozmasin.
  bool _disposed = false;

  /// Chat matn o'lchami koeffitsienti — foydalanuvchi 3 xil o'lchamдан
  /// birini tanlaydi (kichik 0.85, o'rtacha 1.0, katta 1.2). Tanlov
  /// SharedPreferences'да saqlanadi va keyingi ochilishда tiklanadi.
  double _chatTextScale = 1.0;
  static const String _chatScaleKey = 'chat_text_scale';

  Future<void> _loadChatScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_chatScaleKey);
      if (v != null && mounted) {
        setState(() => _chatTextScale = v);
      }
    } catch (_) {}
  }

  Future<void> _saveChatScale(double v) async {
    setState(() => _chatTextScale = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_chatScaleKey, v);
    } catch (_) {}
  }

  void _showTextSizeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Widget option(String label, double scale, double preview) {
          final selected = (_chatTextScale - scale).abs() < 0.01;
          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontFamily: LuxTokens.display,
                fontSize: preview,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A0A0A),
              ),
            ),
            trailing: selected
                ? const Icon(LucideIcons.check, color: LuxTokens.gold)
                : null,
            onTap: () {
              _saveChatScale(scale);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Matn o\'lchami'.tr,
                style: const TextStyle(
                  fontFamily: LuxTokens.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 8),
              option('Kichik'.tr, 0.85, 15),
              option('O\'rtacha'.tr, 1.0, 18),
              option('Katta'.tr, 1.2, 22),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadChatScale();
    _pendingPhoto = widget.initialPhoto;
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _chatHistory.add({
      'role': 'assistant',
      'content':
          "Assalomu alaykum! Men AiHub — HubServis SuperApp'ning sun'iy intellekt yordamchisiman. Ilova bo'yicha qanday savollaringiz bor? Sizga bajonidil yordam beraman. 🤖✨"
              .tr,
    });

    // Saqlangan chat tarixini yuklaymiz (ilova qayta ochilganda ham chat qoladi).
    _loadSavedHistory();

    _initSpeechEngine().then((_) {
      if (widget.startVoice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startRecording();
        });
      }
    });
  }

  /// AiService diskdagi tarixni yuklaydi va ekranga qo'shadi.
  Future<void> _loadSavedHistory() async {
    try {
      final saved = await _aiService.loadHistory();
      if (saved.isEmpty || !mounted) return;
      setState(() {
        for (final m in saved) {
          // Saqlangan tugmalarni (actions) ham tiklaymiz — chatga qaytganda
          // "bron qilish" / bo'lim tugmalari yo'qolib qolmasin.
          final acts = (m['actions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _chatHistory.add({
            'role': m['role'] ?? 'assistant',
            'content': m['content'] ?? '',
            if (acts != null && acts.isNotEmpty) 'actions': acts,
          });
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    // Avval ovoz oqimini to'xtatamiz — keyingi onSoundLevelChange callback'lar
    // kelmasligi uchun; so'ng notifier'ni yo'q qilamiz (disposed'ga yozilmasin).
    _speech.cancel();
    _hideVoiceOverlay();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _soundLevelVN.dispose();
    super.dispose();
  }

  Future<void> _initSpeechEngine() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' &&
              _voiceState == _VoiceState.recording &&
              mounted) {
            _stopRecordingAndSend();
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            _resetVoiceState();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${'Ovoz yozishda xatolik yuz berdi'.tr}: ${error.errorMsg}',
                ),
              ),
            );
          }
        },
      );
      if (available && mounted) {
        _isSpeechInitialized = true;
        try {
          var locales = await _speech.locales();
          for (var loc in locales) {
            if (loc.localeId.startsWith('uz')) {
              _speechLocale = loc.localeId;
              break;
            }
          }
        } catch (e) {
          debugPrint('Locales error: $e');
        }
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  void _startRecording() async {
    if (_voiceState == _VoiceState.recording) return;

    bool hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mikrofonga ruxsat berilmadi'.tr)));
      return;
    }

    if (!_isSpeechInitialized) {
      await _initSpeechEngine();
      if (!_isSpeechInitialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ovozli tizim faollashmadi'.tr)));
        return;
      }
    }

    // Ruxsat/init oynasi ochiqligida ekrandan chiqilgan bo'lishi mumkin —
    // await'lardan keyin mounted tekshiramiz (aks holda setState/Overlay crash).
    if (!mounted) return;
    setState(() {
      _voiceState = _VoiceState.recording;
      _textController.clear();
    });
    _pulseController.repeat(reverse: true);
    _showVoiceOverlay();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          // MUHIM: recording tugaganidan keyin ham speech engine bir necha
          // millisekund davomida qo'shimcha onResult (partial va final) yuborishi
          // mumkin. Bu paytda `_textController.text = ...` bo'lsa, xabar
          // yuborilgach ham matn maydonda qolib qoladi (dublikat ko'rinadi).
          // Faqat AKTIV yozish paytida controllerga yozamiz.
          if (_voiceState != _VoiceState.recording) return;
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
          // Ovoz avtomatik tugaganда (yakuniy natija) — tugmani qayta bosmasdan
          // matnni o'zi yuboramiz.
          if (result.finalResult) {
            _stopRecordingAndSend();
          }
        },
        onSoundLevelChange: (level) {
          // Modal ekvalayzer shu qiymatga qarab jonlanadi (setState shart emas).
          if (_disposed) return;
          _soundLevelVN.value = level;
        },
        localeId: _speechLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        // 3 soniya sukunatдан keyin avtomatik to'xtaydi (qo'lda bosish shart emas).
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
      );
    } catch (e) {
      debugPrint('Speech listen exception: $e');
      _resetVoiceState();
    }
  }

  void _stopRecordingAndSend() async {
    // Bir vaqtда bir necha marta chaqirilishi mumkin (onResult final + onStatus
    // notListening + tugma). Faqat "recording" holatдан bir marta o'tamiz.
    if (_voiceState != _VoiceState.recording) return;
    // MUHIM: bu qatordan keyin `onResult` guard'i controllerga yozmaydi.
    setState(() => _voiceState = _VoiceState.processing);
    _hideVoiceOverlay();
    _pulseController.stop();
    _pulseController.reset();

    // Matnni DARHOL olib, controllerni tozalaymiz. Aks holda:
    //  - _speech.stop() async (bir necha ms)
    //  - shu vaqt ichida _sendMessage async chaqirilishidan oldin ekranda
    //    matn ko'rinib turadi va foydalanuvchi "yozilib qoldi" deb tushunadi.
    final text = _textController.text.trim();
    _textController.clear();

    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Speech stop error: $e');
    }

    if (!mounted) return;

    if (text.isEmpty) {
      _resetVoiceState();
      return;
    }

    await _sendMessage(text: text, isVoice: true);

    if (mounted) {
      _resetVoiceState();
    }
  }

  void _resetVoiceState() {
    _hideVoiceOverlay();
    if (mounted) {
      setState(() {
        _voiceState = _VoiceState.idle;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  /// Ovoz yozish modalини ko'rsatadi (jonli mic + ekvalayzer).
  void _showVoiceOverlay() {
    if (_voiceOverlay != null) return;
    final overlay = Overlay.of(context);
    _voiceOverlay = OverlayEntry(
      builder: (_) => _VoiceListeningOverlay(
        soundLevel: _soundLevelVN,
        onStop: _stopRecordingAndSend,
      ),
    );
    overlay.insert(_voiceOverlay!);
  }

  void _hideVoiceOverlay() {
    _voiceOverlay?.remove();
    _voiceOverlay = null;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      // Kechikish davomida ekran yopilgan bo'lishi mumkin — qayta tekshiramiz.
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Rasmni TANLAYDI (yubormaydi).
  ///
  /// Ilgari rasm tanlanishi bilan darhol AI ga ketardi va foydalanuvchi
  /// tushuntirish yozishga ulgurmasdi. Endi rasm "kutish"da turadi,
  /// tagiga matn yozish mumkin, yuborish esa alohida qadam.
  Future<void> _pickJobPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      // Vision modelga 3MB chegara bor, oldindan kichraytiramiz
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _pendingPhoto = picked);
  }

  /// Kutayotgan rasmni bekor qilish.
  void _clearPendingPhoto() {
    setState(() => _pendingPhoto = null);
  }

  /// Kutayotgan rasmni (va yozilgan matnni) AI ga yuboradi.
  Future<void> _sendPendingPhoto() async {
    final photo = _pendingPhoto;
    if (photo == null || _photoUploading) return;

    // Foydalanuvchi rasm tagiga yozgan izoh (bo'lishi shart emas).
    final izoh = _textController.text.trim();

    setState(() {
      _photoUploading = true;
      _pendingPhoto = null;
      _chatHistory.add({
        'role': 'user',
        'content': izoh.isEmpty ? '📷 Rasm yuborildi'.tr : '📷 $izoh',
        'localPhoto': photo.path,
      });
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // Savdo suhbatimi? Shunda rasm SAVDO papkasiga tushadi va
      // vision tahlili o'tkazib yuboriladi (buyumni foydalanuvchi
      // o'zi tasvirlaydi). Aks holda vision "ta'mirlash kerak" degan
      // ish tavsifini qaytarib, savdo suhbatini chalg'itardi.
      final savdo = _isSellingConversation();
      final res = await ApiService().sendJobPhotoToAi(
        photo.path,
        kind: savdo ? 'market' : 'job',
      );
      if (!mounted) return;

      final analysis = res['analysis'] as Map<String, dynamic>?;
      final url = res['url'] as String?;

      // AI rasmni tushungan bo'lsa — tavsifni suhbatga qo'shamiz,
      // shunda model e'lon berishni o'zi taklif qiladi.
      final buf = StringBuffer();
      if (analysis != null && analysis['detected'] == true) {
        buf.writeln('Rasmda: ${analysis['description'] ?? ''}');
        if ((analysis['title'] as String?)?.isNotEmpty ?? false) {
          buf.writeln('Ish: ${analysis['title']}');
        }
      }
      if (url != null) {
        // URL ni ANIQ ko'rsatamiz: model uni add_listing_photos yoki
        // publish_job ga aynan shu ko'rinishda uzatishi kerak.
        buf.writeln('Rasm: $url');
        if (savdo) {
          buf.writeln(
            'Bu SAVDO e\'loni rasmi. add_listing_photos tool\'iga '
            'aynan shu URL ni bering.',
          );
        }
      }
      // Foydalanuvchining o'z izohi eng muhim — oxirida turadi.
      if (izoh.isNotEmpty) {
        buf.writeln('Foydalanuvchi izohi: $izoh');
      } else {
        buf.write(res['message'] ?? '');
      }

      setState(() {
        _isTyping = false;
        _photoUploading = false;
      });
      // Matnni AI ga yuboramiz — u savol berib e'lon tayyorlaydi.
      // `silent` — bu texnik matn chatda ko'rinmaydi, foydalanuvchi
      // allaqachon o'z rasmini va izohini ko'rgan.
      await _sendMessage(text: buf.toString().trim(), silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _photoUploading = false;
        _chatHistory.add({
          'role': 'assistant',
          'content': 'Rasmni yuborib bo\'lmadi. Qaytadan urinib ko\'ring.'.tr,
        });
      });
    }
  }

  /// Suhbat SAVDO (buyum sotish) haqidami.
  ///
  /// Ikki xil e'lon bor va rasm ikkalasiga ham kerak:
  ///   • ISH e'loni — buzilgan joyni rasmga oladi, vision tahlil qiladi
  ///   • SAVDO e'loni — sotiladigan buyum, tahlil kerak emas
  /// Farqni bilmasak, savdo suhbatida vision "ta'mirlash kerak" deb
  /// javob berib, AI ni ish e'loniga burib yuboradi.
  bool _isSellingConversation() {
    // Oxirgi bir necha xabarga qaraymiz: suhbat mavzusi o'zgargan
    // bo'lishi mumkin, butun tarixni tekshirish xato beradi.
    final oxirgi = _chatHistory.length <= 6
        ? _chatHistory
        : _chatHistory.sublist(_chatHistory.length - 6);
    for (final m in oxirgi.reversed) {
      final matn = (m['content'] as String? ?? '').toLowerCase();
      if (matn.isEmpty) continue;
      // Savdo belgilari (AI ham, foydalanuvchi ham ishlatadi).
      if (matn.contains('sotmoqchi') ||
          matn.contains('sotaman') ||
          matn.contains('sotiladi') ||
          matn.contains('e\'loningizni berish') ||
          matn.contains('kamida 3 ta rasm') ||
          matn.contains('продать') ||
          matn.contains('продаю')) {
        return true;
      }
      // Ish e'loni belgilari — savdo emas.
      if (matn.contains('usta') ||
          matn.contains('tamirla') ||
          matn.contains('ta\'mirla') ||
          matn.contains('buzilgan')) {
        return false;
      }
    }
    return false;
  }

  /// Yuborilishni kutayotgan rasm paneli.
  ///
  /// Ko'rinadi: kichik rasm, tushuntirish va bekor qilish tugmasi.
  /// Foydalanuvchi shu paytda tagiga izoh yozishi mumkin.
  Widget _pendingPhotoPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LuxTokens.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_pendingPhoto!.path),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              // Rasm o'qilmasa panel buzilmasin.
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_outlined, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rasm tayyor'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Muammoni yozing va yuboring'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _photoUploading ? null : _clearPendingPhoto,
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: 'Bekor qilish'.tr,
            color: GlassTokens.secondaryText(context),
          ),
        ],
      ),
    );
  }

  /// Kamera yoki galereya tanlash oynasi.
  void _pickPhotoSource() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Rasmga olish'.tr),
              subtitle: Text('Muammoli joyni suratga oling'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickJobPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Galereyadan tanlash'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickJobPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// [silent] — foydalanuvchi xabari chatda KO'RSATILMAYDI.
  /// Rasm oqimida kerak: u yerda texnik matn (rasm URL'i, vision
  /// tahlili) yuboriladi, foydalanuvchi esa o'z rasmini va izohini
  /// allaqachon ko'rgan.
  Future<void> _sendMessage({
    String? text,
    bool isVoice = false,
    bool silent = false,
  }) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      if (!silent) {
        _chatHistory.add({
          'role': 'user',
          'content': isVoice ? '🎤 $messageText' : messageText,
        });
      }
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    final response = await _aiService.sendMessage(messageText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _chatHistory.add({
          'role': 'assistant',
          'content': response,
          // AI amallari (masalan bron yaratildi) — chatда tugma ko'rsatish uchun.
          'actions': List<Map<String, dynamic>>.from(_aiService.lastActions),
        });
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'AiHub'.tr,
      actions: [
        IconButton(
          tooltip: 'Matn o\'lchami'.tr,
          icon: Icon(
            LucideIcons.aLargeSmall,
            color: GlassTokens.primaryText(context),
            size: 22,
          ),
          onPressed: _showTextSizeSheet,
        ),
        IconButton(
          icon: Icon(
            LucideIcons.refreshCcw,
            color: GlassTokens.primaryText(context),
            size: 20,
          ),
          onPressed: () {
            unawaited(_aiService.clearHistory());
            setState(() {
              _chatHistory.clear();
              _chatHistory.add({
                'role': 'assistant',
                'content':
                    "Chat tozalab tashlandi. Sizga yana qanday yordam bera olaman?"
                        .tr,
              });
            });
          },
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatHistory.length) {
                  return _buildTypingIndicator();
                }
                final message = _chatHistory[index];
                // Foydalanuvchi tanlagan chat matn o'lchamini butun
                // xabar (matn + tugmalar + provayder kartalari) ga qo'llaymiz.
                // Global miqyos ustiga chat tanlovi ko'paytiriladi.
                final globalScale =
                    MediaQuery.of(context).textScaler.scale(1.0);
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler:
                        TextScaler.linear(globalScale * _chatTextScale),
                  ),
                  child: _buildMessageBubble(
                    content: message['content'],
                    isUser: message['role'] == 'user',
                    actions: (message['actions'] as List?)
                        ?.cast<Map<String, dynamic>>(),
                    localPhoto: message['localPhoto'] as String?,
                  ),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isUser,
    List<Map<String, dynamic>>? actions,
    // Foydalanuvchi yuborgan rasm (telefondagi yo'l). Chatda ko'rinadi,
    // shunda u nima yuborganini eslab qoladi.
    String? localPhoto,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionButtons = isUser ? const <Widget>[] : _actionButtons(actions);
    // Savdo qidiruvi natijasi: tugma emas, KARTALAR gridi ko'rinadi.
    final listings = isUser ? const <Listing>[] : _listingsOf(actions);
    final providerListAction = isUser ? null : _providerListOf(actions);
    // Tasdiq so'rovi: katta «Ha / Yo'q» tugmalari. Ilgari faqat matn
    // bor edi va foydalanuvchi «E'lon tayyor» degan sarlavhani ko'rib
    // pastdagi savolni o'qimay ketib qolardi — e'lon berilmay qolardi.
    final confirm = isUser ? null : _confirmOf(actions);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Uzun bosilganda: nusxalash / tahrirlash / qayta yuborish /
          // o'chirish. Foydalanuvchi xato yozsa butun chatni tozalashi
          // shart emas.
          GestureDetector(
            onLongPress: () => _showMessageMenu(content, isUser),
            child: Container(
              margin: EdgeInsets.only(bottom: actionButtons.isEmpty && providerListAction == null ? 16 : 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * (providerListAction != null ? 0.90 : 0.75),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF102A43) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xFF102A43) : LuxTokens.border,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF102A43).withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Builder(builder: (context) {
                if (providerListAction != null) {
                  final (headerText, footerText) = _splitContentForProviderList(content);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (headerText.isNotEmpty) ...[
                        Text(
                          headerText,
                          style: const TextStyle(
                            color: LuxTokens.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildProviderListWidget(providerListAction),
                      if (footerText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          footerText,
                          style: const TextStyle(
                            color: LuxTokens.text,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (localPhoto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(localPhoto),
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      content,
                      style: TextStyle(
                        color: isUser ? Colors.white : LuxTokens.text,
                        fontSize: 15,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          // Grid pufakdan KENGROQ bo'ladi (0.75 emas, deyarli to'liq
          // en): 2 ustunli kartalar tor joyda o'qilmaydi.
          if (listings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 8),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.92,
                child: ListingGrid(listings: listings),
              ),
            ),
          if (confirm != null) _confirmButtons(confirm),
          if (actionButtons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
            ),
        ],
      ),
    );
  }

  /// Xabar ustida uzun bosilganda chiqadigan menyu.
  ///
  /// Foydalanuvchi talabi: "agent bilan yuborgan smslarni replace
  /// qilib qayta yuborish va o'chirish". Ilgari faqat BUTUN chatni
  /// tozalash bor edi — bitta xato yozuv uchun hamma narsa yo'qolardi.
  Future<void> _showMessageMenu(String content, bool isUser) async {
    // Salomlashish xabari — o'chirib bo'lmaydi (u tarixda ham yo'q).
    final index = _chatHistory.indexWhere(
      (m) => m['content'] == content && (m['role'] == 'user') == isUser,
    );
    if (index <= 0 && !isUser) {
      await Clipboard.setData(ClipboardData(text: content));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nusxalandi'.tr)));
      return;
    }

    final tanlov = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.copy),
              title: Text('Nusxalash'.tr),
              onTap: () => Navigator.of(ctx).pop('copy'),
            ),
            if (isUser)
              ListTile(
                leading: const Icon(LucideIcons.pencil),
                title: Text('Tahrirlash va qayta yuborish'.tr),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
            if (isUser)
              ListTile(
                leading: const Icon(LucideIcons.refreshCw),
                title: Text('Qayta yuborish'.tr),
                onTap: () => Navigator.of(ctx).pop('resend'),
              ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: Text(
                'O\'chirish'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (tanlov == null || !mounted) return;

    switch (tanlov) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: content));
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Nusxalandi'.tr)));

      case 'edit':
      case 'resend':
        // Xabar va undan keyingi AI javobi olib tashlanadi: eski savol
        // kontekstda qolsa model o'zini takrorlaydi.
        final matn = _stripVoicePrefix(content);
        await _dropFrom(index);
        if (!mounted) return;
        if (tanlov == 'edit') {
          // Tahrirlash: matn maydonga qaytadi, foydalanuvchi tuzatadi.
          _textController.text = matn;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: matn.length),
          );
          setState(() {});
        } else {
          await _sendMessage(text: matn);
        }

      case 'delete':
        await _dropFrom(index, onlyOne: !isUser);
    }
  }

  /// "🎤 " kabi ko'rinish uchun qo'shilgan prefiksni olib tashlaydi.
  String _stripVoicePrefix(String text) {
    for (final p in ['🎤 ', '📷 ']) {
      if (text.startsWith(p)) return text.substring(p.length);
    }
    return text;
  }

  /// [index] dan boshlab xabarlarni o'chiradi (ekrandan ham, tarixdan ham).
  ///
  /// [onlyOne] — faqat bittasini (AI javobi o'chirilganda).
  Future<void> _dropFrom(int index, {bool onlyOne = false}) async {
    if (index < 0 || index >= _chatHistory.length) return;
    final ochiriladi = onlyOne
        ? [_chatHistory[index]]
        : _chatHistory.sublist(index);
    setState(() {
      if (onlyOne) {
        _chatHistory.removeAt(index);
      } else {
        _chatHistory.removeRange(index, _chatHistory.length);
      }
    });
    // AiService tarixidan ham olib tashlaymiz, aks holda keyingi
    // so'rovda o'chirilgan xabar yana modelga ketadi.
    for (final m in ochiriladi) {
      await _aiService.removeMessage(
        (m['role'] ?? 'user').toString(),
        (m['content'] ?? '').toString(),
      );
    }
  }

  /// Tasdiq so'rovi amalini topadi (`confirm_request`).
  Map<String, dynamic>? _confirmOf(List<Map<String, dynamic>>? actions) {
    if (actions == null) return null;
    for (final a in actions) {
      if (a['type'] == 'confirm_request') return a;
    }
    return null;
  }

  /// Katta «Ha / Yo'q» tugmalari.
  ///
  /// Nega katta: bu oxirgi qadam va uni o'tkazib yuborish e'lon
  /// berilmasligiga olib keladi. Tugma bosilganda oddiy xabar
  /// yuboriladi — model uni tasdiq deb tushunadi.
  Widget _confirmButtons(Map<String, dynamic> confirm) {
    final savol = (confirm['question'] as String?) ?? 'Tasdiqlaysizmi?';
    final ha = (confirm['yes_text'] as String?) ?? 'Ha';
    final yoq = (confirm['no_text'] as String?) ?? 'Yo\'q';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 8),
      padding: const EdgeInsets.all(14),
      width: MediaQuery.of(context).size.width * 0.86,
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.circleAlert,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  savol,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : LuxTokens.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isTyping ? null : () => _sendMessage(text: ha),
                    icon: const Icon(LucideIcons.check, size: 20),
                    label: Text(ha, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isTyping ? null : () => _sendMessage(text: yoq),
                    icon: const Icon(LucideIcons.x, size: 20),
                    label: Text(yoq, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// AI qaytargan amallardan savdo e'lonlarini ajratib oladi.
  ///
  /// Backend `{"type": "listing_grid", "listings": [...]}` yuboradi —
  /// bu yagona joy: karta ko'rinishi widgetlarda, bu yerda faqat
  /// ma'lumot o'qiladi.
  List<Listing> _listingsOf(List<Map<String, dynamic>>? actions) {
    if (actions == null || actions.isEmpty) return const [];
    final out = <Listing>[];
    for (final a in actions) {
      if (a['type'] != 'listing_grid') continue;
      for (final raw in (a['listings'] as List?) ?? const []) {
        out.add(Listing.fromJson(Map<String, dynamic>.from(raw as Map)));
      }
    }
    return out;
  }

  (String, String) _splitContentForProviderList(String content) {
    final lines = content.split('\n');
    final headerLines = <String>[];
    final footerLines = <String>[];
    bool inList = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final isListItem = RegExp(r'^\d+[\.\)]').hasMatch(line);
      final isSubDetail = line.startsWith('⭐') ||
          line.startsWith('📍') ||
          line.startsWith('📏') ||
          line.startsWith('•');

      if (isListItem || isSubDetail) {
        inList = true;
        continue;
      }

      if (line.contains('Quyidagi tugmalar') ||
          line.contains('tugmalar orqali') ||
          line.contains('Birortasiga bron')) {
        continue;
      }

      if (inList) {
        footerLines.add(rawLine);
      } else {
        headerLines.add(rawLine);
      }
    }

    final header = headerLines.join('\n').trim();
    final footer = footerLines.join('\n').trim();
    return (header, footer);
  }

  Map<String, dynamic>? _providerListOf(List<Map<String, dynamic>>? actions) {
    if (actions == null || actions.isEmpty) return null;
    for (final a in actions) {
      if (a['type'] == 'provider_list') return a;
    }
    return null;
  }

  Widget _buildProviderListWidget(Map<String, dynamic> action) {
    final catKey = action['category_key'] as String?;
    final provs = (action['providers'] as List?) ?? const [];
    if (provs.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in provs) ...[
          _buildProviderCard(Map<String, dynamic>.from(p as Map), catKey, isDark),
          const SizedBox(height: 6),
        ]
      ],
    );
  }

  Widget _buildProviderCard(
      Map<String, dynamic> pm, String? defaultCatKey, bool isDark) {
    final id = (pm['id'] as num?)?.toInt();
    final name = pm['name'] as String? ?? 'Usta / Xizmat ko\'rsatuvchi';
    final rating = (pm['rating'] as num?)?.toDouble() ?? 5.0;
    final address = pm['address'] as String? ?? '';
    final dist = (pm['distance_km'] as num?)?.toDouble();
    final pKey = pm['category_key'] as String? ?? defaultCatKey;

    if (id == null) return const SizedBox.shrink();

    final details = <String>[];
    details.add('⭐ ${rating.toStringAsFixed(1)}');
    if (address.isNotEmpty) details.add('📍 $address');
    if (dist != null) details.add('📏 ${dist.toStringAsFixed(1)} km');

    const cardBg = Color(0xFFF8F9FA);
    const nameColor = LuxTokens.text;
    const detailColor = LuxTokens.textMuted;
    const borderColor = LuxTokens.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LuxTokens.gold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.store, color: LuxTokens.gold, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details.join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: detailColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: LuxTokens.gold,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _openProviderBooking(id, pKey),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.calendarPlus, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Bron'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI amallaridan chatда bosiladigan tugma yasaydi. Masalan bron yaratilsa —
  /// "Buyurtmani ko'rish" tugmasi (Buyurtmalar bo'limiga o'tadi).
  List<Widget> _actionButtons(List<Map<String, dynamic>>? actions) {
    if (actions == null || actions.isEmpty) return const [];
    final buttons = <Widget>[];
    for (final a in actions) {
      final type = a['type'];
      if (type == 'booking_created') {
        final providerName = a['provider_name'] as String?;
        buttons.add(_chatActionButton(
          icon: LucideIcons.calendarCheck,
          label: providerName != null
              ? "${'Bron'.tr}: $providerName"
              : 'Buyurtmani ko\'rish'.tr,
          onTap: () => _openBookings(),
        ));
      } else if (type == 'listings_changed' || type == 'my_listings') {
        // E'lon berildi/o'zgardi — "Mening e'lonlarim" ga o'tish.
        buttons.add(_chatActionButton(
          icon: LucideIcons.tag,
          label: 'Mening e\'lonlarim'.tr,
          onTap: () => _openBookings(),
        ));
      } else if (type == 'listing_detail') {
        final m = Map<String, dynamic>.from((a['listing'] as Map?) ?? const {});
        if (m.isNotEmpty) {
          final listing = Listing.fromJson(m);
          buttons.add(_chatActionButton(
            icon: LucideIcons.package,
            label: listing.title,
            onTap: () => showListingModal(context, listing),
          ));
        }
      } else if (type == 'orders_changed') {
        buttons.add(_chatActionButton(
          icon: LucideIcons.shoppingBag,
          label: 'Buyurtmalarim'.tr,
          onTap: () => _openBookings(),
        ));
      } else if (type == 'navigate') {
        // Backend bir yoki bir nechta bo'lim tugmasini yuborishi mumkin:
        //   {type: navigate, items: [{route, label}, ...]}  yoki  {route, label}
        final items = (a['items'] as List?) ?? const [];
        if (items.isNotEmpty) {
          for (final it in items) {
            final m = Map<String, dynamic>.from(it as Map);
            final route = m['route'] as String?;
            if (route == null) continue;
            buttons.add(_chatActionButton(
              icon: _sectionIcon(route),
              label: (m['label'] as String?) ?? 'Ochish'.tr,
              onTap: () => _handleNavigate(route),
            ));
          }
        } else if (a['route'] is String) {
          buttons.add(_chatActionButton(
            icon: _sectionIcon(a['route'] as String),
            label: (a['label'] as String?) ?? 'Ochish'.tr,
            onTap: () => _handleNavigate(a['route'] as String),
          ));
        }
      }
    }
    return buttons;
  }

  Widget _chatActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: LuxTokens.gold,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookings() {
    // Buyurtmalar ro'yxati ekraniga o'tadi.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
  }

  /// Provayder id bo'yicha to'liq ma'lumot olib, uning bron/profil sahifasini
  /// ochadi. Foydalanuvchi o'sha yerда vaqt tanlaб bron qiladi.
  Future<void> _openProviderBooking(int providerId, String? categoryKey) async {
    ServiceHubKind kind = ServiceHubKind.sartarosh;
    if (categoryKey != null) {
      try {
        kind = ServiceHubKind.values.byName(categoryKey);
      } catch (_) {}
    }
    // Yuklanmoqda indikatori
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final json = await ApiService().getProvider(providerId);
      final master = Master.fromProviderJson(json);
      if (!mounted) return;
      Navigator.pop(context); // yuklanmoqda dialogини yopamiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderProfileScreen(master: master, category: kind),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provayderni ochib bo\'lmadi'.tr)),
      );
    }
  }

  /// Bo'lim uchun mos ikonka (backend'даги route kalitlari bo'yicha).
  IconData _sectionIcon(String route) {
    switch (route) {
      case 'plans':
      case 'todos':
        return LucideIcons.calendarCheck;
      case 'finance':
        return LucideIcons.wallet;
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'orders':
        return LucideIcons.briefcase;
      case 'alarms':
        return LucideIcons.alarmClock;
      case 'services':
        return LucideIcons.layoutGrid;
      case 'calorie':
        return LucideIcons.flame;
      case 'fitness':
        return LucideIcons.dumbbell;
      case 'calls':
        return LucideIcons.phone;
      case 'profile':
        return LucideIcons.user;
      case 'premium':
        return LucideIcons.crown;
      default:
        return LucideIcons.arrowRight;
    }
  }

  /// Backend 'navigate' action'ida kelgan bo'lim kalitiga qarab ilova ichидаги
  /// tegishli ekranni ochadi. Kalitlar backend nav_tools.SECTIONS bilan bir xil.
  void _handleNavigate(String route) {
    Widget? screen;
    switch (route) {
      case 'plans':
      case 'todos':
        screen = const TodoScreen();
        break;
      case 'finance':
        screen = const FinanceManagerScreen();
        break;
      case 'shopping':
        screen = const ShoppingListScreen();
        break;
      case 'orders':
        screen = const OrdersScreen();
        break;
      case 'alarms':
        screen = const AlarmHomeScreen();
        break;
      case 'services':
        screen = const AllCategoriesScreen(showBackButton: true);
        break;
      case 'calorie':
        screen = const CalorieHomeScreen();
        break;
      case 'fitness':
        screen = const FitnessHomeScreen();
        break;
      case 'calls':
        screen = const CallHistoryScreen();
        break;
      case 'profile':
        screen = const ProfileScreen();
        break;
      case 'premium':
        screen = const PremiumScreen();
        break;
    }
    if (screen == null) {
      _openBookings(); // noma'lum bo'lim — buyurtmalarga tushamiz
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: LuxTokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yozmoqda'.tr,
              style: const TextStyle(
                color: LuxTokens.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LuxTokens.goldSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRecording = _voiceState == _VoiceState.recording;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: LuxTokens.border),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tanlangan, hali yuborilmagan rasm. Foydalanuvchi tagiga
              // izoh yozib, keyin yuborishi mumkin.
              if (_pendingPhoto != null) _pendingPhotoPreview(isDark),
              Row(
                children: [
                  // Rasm yuborish: "shu joyni tamirlash kerak" oqimi
                  IconButton(
                    onPressed: isRecording ? null : _pickPhotoSource,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    tooltip: 'Ish joyi rasmini yuborish'.tr,
                    color: LuxTokens.gold,
                  ),
                  Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isRecording
                        ? Colors.red.shade50
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isRecording
                          ? Colors.redAccent
                          : LuxTokens.border,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                      color: isRecording
                          ? Colors.redAccent
                          : LuxTokens.text,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (isRecording) return;
                      // Rasm kutayotgan bo'lsa yozilgan matn uning
                      // izohi bo'ladi, alohida xabar emas.
                      if (_pendingPhoto != null) {
                        _sendPendingPhoto();
                      } else {
                        _sendMessage();
                      }
                    },
                    readOnly: isRecording,
                    decoration: InputDecoration(
                      hintText: isRecording
                          ? 'Eshitilmoqda...'.tr
                          : 'Xabar yozish...'.tr,
                      hintStyle: TextStyle(
                        color: isRecording
                            ? Colors.redAccent.withValues(alpha: 0.7)
                            : LuxTokens.textMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (isRecording) {
                    _stopRecordingAndSend();
                  } else if (_pendingPhoto != null) {
                    // Rasm kutyapti: matn bo'lsa u izoh sifatida ketadi
                    if (!_isTyping) _sendPendingPhoto();
                  } else if (_hasText) {
                    if (!_isTyping) _sendMessage();
                  } else {
                    _startRecording();
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isRecording ? _pulseAnim.value : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRecording
                                ? [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626),
                                  ]
                                : (_hasText || _pendingPhoto != null)
                                ? [
                                    const Color(0xFFE3C766),
                                    const Color(0xFFC9A227),
                                  ]
                                : [
                                    const Color(0xFFE3C766),
                                    const Color(0xFFC9A227),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isRecording
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : const Color(0xFFC9A227).withValues(alpha: 0.5),
                              blurRadius: isRecording ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording
                              ? LucideIcons
                                    .square // Stop icon
                              : ((_hasText || _pendingPhoto != null)
                                    ? LucideIcons.send
                                    : LucideIcons.mic),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ovoz yozish paytида ko'rinadigan modal overlay — jonli mic + ekvalayzer.
/// Foydalanuvchi gapirib bo'lgach (avto-tugash) o'zi yopiladi; tashqariga yoki
/// yashil tugmaga bosib ham yakunlash mumkin.
class _VoiceListeningOverlay extends StatefulWidget {
  final ValueNotifier<double> soundLevel;
  final VoidCallback onStop;

  const _VoiceListeningOverlay({
    required this.soundLevel,
    required this.onStop,
  });

  @override
  State<_VoiceListeningOverlay> createState() => _VoiceListeningOverlayState();
}

class _VoiceListeningOverlayState extends State<_VoiceListeningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onStop, // tashqariga bosish ham yakunlaydi
        child: Material(
          color: Colors.black.withValues(alpha: 0.62),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // kartaga bosish holatni o'zgartirmasin
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: LuxTokens.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC9A227).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMic(),
                    const SizedBox(height: 26),
                    _buildBars(),
                    const SizedBox(height: 24),
                    Text(
                      'Tinglayapman...'.tr,
                      style: const TextStyle(
                        color: LuxTokens.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "So'zlang — tugagach o'zi yoziladi".tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LuxTokens.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    GestureDetector(
                      onTap: widget.onStop,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: LuxTokens.goldBoxDecoration(isCircle: true),
                        child: const Icon(
                          LucideIcons.check,
                          color: Color(0xFF140D02),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMic() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.soundLevel,
      builder: (context, level, _) {
        final norm = (level.clamp(0.0, 10.0)) / 10.0;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Kengayuvchi halqalar
                  ...List.generate(2, (r) {
                    final p = (_c.value + r * 0.5) % 1.0;
                    return Container(
                      width: 80 + p * 62,
                      height: 80 + p * 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: LuxTokens.gold.withValues(alpha: (1 - p) * 0.45),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                  // Ovoz balandligiga qarab kattalashuvchi mic doirasi
                  Container(
                    width: 74 + norm * 16,
                    height: 74 + norm * 16,
                    decoration: LuxTokens.goldBoxDecoration(isCircle: true),
                    child: const Icon(LucideIcons.mic,
                        color: Color(0xFF140D02), size: 32),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBars() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.soundLevel,
      builder: (context, level, _) {
        final norm = (level.clamp(0.0, 10.0)) / 10.0;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(21, (i) {
                final dist = (i - 10).abs() / 10.0; // 0 markaz .. 1 chet
                final center = 1 - dist; // markaz balandroq
                final phase = i * 0.55;
                final wave = 0.5 + 0.5 * math.sin(t * 2 * math.pi + phase);
                final h = 5.0 + (10 + norm * 42) * wave * (0.35 + 0.65 * center);
                return Container(
                  width: 4,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [LuxTokens.gold, Color(0xFFE0B454)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
