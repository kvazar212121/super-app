import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_helper.dart';
import '../models/alarm.dart';
import '../config/app_config.dart';

/// AI yordamchi xizmati — backend proxy orqali Groq API ga ulanadi.
/// API kalit serverda saqlanadi, APK ichida yo'q.
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  late final Dio _dio;

  AiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(
          seconds: 45,
        ), // AI javob berishi uchun ko'proq vaqt
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  /// Chat tarixini saqlaydi (faqat user va assistant xabarlari).
  /// Lokal xotira (SharedPreferences) — ilova yopilsa ham chat qoladi.
  final List<Map<String, String>> _messages = [];
  static const String _historyKey = 'ai_chat_history_v1';
  // Prompt hajmi cheklangani uchun so'nggi N xabarni yuboramiz (kichik "xotira").
  static const int _maxContextMessages = 20;
  // Diskda saqlanadigan maksimal xabar (eskilarini kesib tashlaymiz).
  static const int _maxStoredMessages = 100;
  bool _loaded = false;

  /// Oxirgi AI javobидаги amallar (chat tugmalari uchun). sendMessage'дан
  /// keyin chat ekrani buni o'qib, mos tugma (masalan 'Buyurtmani ko'rish')
  /// ko'rsatadi.
  List<Map<String, dynamic>> lastActions = const [];

  /// Saqlangan chat tarixini diskdan yuklaydi (ilova ochilganda bir marta).
  Future<List<Map<String, String>>> loadHistory() async {
    if (_loaded) return List.unmodifiable(_messages);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
        _messages
          ..clear()
          ..addAll(data.map((e) => Map<String, String>.from(e as Map)));
      }
    } catch (_) {}
    _loaded = true;
    return List.unmodifiable(_messages);
  }

  /// Chat tarixini diskka saqlaydi (oxirgi _maxStoredMessages ta).
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toStore = _messages.length > _maxStoredMessages
          ? _messages.sublist(_messages.length - _maxStoredMessages)
          : _messages;
      await prefs.setString(_historyKey, jsonEncode(toStore));
    } catch (_) {}
  }

  // Joylashuv keshi — chat davomida qayta-qayta GPS so'ramaslik uchun.
  Position? _cachedPos;
  DateTime? _cachedPosAt;
  static const Duration _posTtl = Duration(minutes: 10);

  /// Foydalanuvchining oxirgi ma'lum joylashuvi (bo'lsa).
  ///
  /// MUHIM: chatni hech qachon kutdirmaydi va ruxsat SO'RAMAYDI — ruxsat
  /// allaqachon berilган bo'lsagina ishlaydi (xizmatlar xaritasида beriladi).
  /// Xato/ruxsat yo'q bo'lsa null qaytadi va AI reyting bo'yicha saralaydi.
  Future<Position?> _lastKnownLocation() async {
    final now = DateTime.now();
    if (_cachedPos != null &&
        _cachedPosAt != null &&
        now.difference(_cachedPosAt!) < _posTtl) {
      return _cachedPos;
    }
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return null;
      }
      // Avval keshlangan (tezkor) joylashuv
      Position? pos = await Geolocator.getLastKnownPosition();
      // Bo'lmasa — qisqa muddatli aniqlash (chat kutib qolmasligi uchun 4s limit)
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 4),
      );
      if (pos != null) {
        _cachedPos = pos;
        _cachedPosAt = now;
      }
      return pos;
    } catch (_) {
      return null; // joylashuv bo'lmasa ham chat normal ishlaydi
    }
  }

  Future<String> sendMessage(String userText) async {
    lastActions = const []; // yangi so'rov — eski tugmalarни tozalaymiz
    _messages.add({'role': 'user', 'content': userText});

    try {
      // Auth token ni olish
      final token = await ApiService().getToken();
      if (token == null) {
        return "Iltimos, avval tizimga kiring.";
      }

      // Faqat so'nggi N xabarни kontekst sifatida yuboramiz (prompt hajmi cheklovi).
      final recent = _messages.length > _maxContextMessages
          ? _messages.sublist(_messages.length - _maxContextMessages)
          : _messages;
      final payloadMessages = List<Map<String, String>>.from(recent);
      if (payloadMessages.isNotEmpty &&
          payloadMessages.last['role'] == 'user') {
        payloadMessages.last = {
          'role': 'user',
          'content':
              "${payloadMessages.last['content']}\n\n[TIZIM MA'LUMOTI: Foydalanuvchining joriy vaqti: ${DateTime.now().toString()} (Timezone: UTC+5). Har qanday reja yoki vazifa yaratishda ushbu vaqtni hisobga oling va vaqtni to'g'ri UTC+5 ga moslab belgilang.]",
        };
      }

      // Joylashuv (bo'lsa) — "eng yaqin sartaroshxonalar" kabi so'rovlar uchun.
      // Hech qachon chatni kutdirmaydi: faqat oxirgi ma'lum joylashuv olinadi.
      final pos = await _lastKnownLocation();

      final response = await _dio.post(
        '/ai/chat',
        data: {
          'messages': payloadMessages,
          if (pos != null) 'lat': pos.latitude,
          if (pos != null) 'lng': pos.longitude,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data;
      final aiReply = responseData['reply'] as String? ?? '';

      // AI yon-amallarini bajaramiz (masalan budilnikni qurilmada rejalashtirish)
      final actions = (responseData['actions'] as List?) ?? const [];
      final parsedActions = <Map<String, dynamic>>[];
      for (final act in actions) {
        final m = Map<String, dynamic>.from(act as Map);
        parsedActions.add(m);
        await _handleAction(m);
      }
      // Chat ekrani tugma ko'rsatishi uchun oxirgi amallarни saqlaymiz.
      lastActions = parsedActions;

      if (aiReply.isNotEmpty) {
        _messages.add({'role': 'assistant', 'content': aiReply});
        await _persist(); // chatni diskka saqlaymiz
        return aiReply;
      }
      return "Kechirasiz, javob olishda xatolik yuz berdi.";
    } on DioException catch (e) {
      // Javob tanasini (maxfiy bo'lishi mumkin) log'ga chiqarmaymiz — faqat status.
      if (kDebugMode) {
        debugPrint("AI API Error: ${e.response?.statusCode ?? e.message}");
      }

      // Tarix dan oxirgi user xabarini olib tashlash (muvaffaqiyatsiz bo'ldi)
      if (_messages.isNotEmpty && _messages.last['role'] == 'user') {
        _messages.removeLast();
      }

      if (e.response?.statusCode == 503 || e.response?.statusCode == 404) {
        await Future.delayed(const Duration(seconds: 1));
        return "Sizning so'rovingiz qabul qilindi! Men SuperApp AI yordamchisiman, qanday yordam bera olaman?";
      }
      if (e.response?.statusCode == 504) {
        return "AI javob berishda vaqt tugadi. Qayta urinib ko'ring.";
      }
      if (e.response?.statusCode == 429) {
        return "Juda ko'p so'rov yubordingiz. Biroz kuting va qayta urinib ko'ring.";
      }
      if (e.response?.statusCode == 401) {
        return "Iltimos, qayta tizimga kiring.";
      }
      return "Internet muammosi: ${e.message} ${e.response?.statusCode ?? ''}";
    } catch (e) {
      debugPrint("AI Service Error: $e");
      if (_messages.isNotEmpty && _messages.last['role'] == 'user') {
        _messages.removeLast();
      }
      return "Kutilmagan xatolik: $e";
    }
  }

  /// AI qaytargan yon-amalni bajaradi.
  Future<void> _handleAction(Map<String, dynamic> act) async {
    try {
      final type = act['type'];
      if (type == 'schedule_alarm' && act['alarm'] != null) {
        final alarm = Alarm.fromJson(
          Map<String, dynamic>.from(act['alarm'] as Map),
        );
        await NotificationHelper().scheduleAlarm(alarm);
        debugPrint('AI budilnik rejalashtirildi: ${alarm.timeLabel}');
      } else if (type == 'alarms_changed') {
        // Budilnik o'chirilgan yoki o'chirib qo'yilgan bo'lsa — qurilmadagi
        // rejalashtirilgan bildirishnomani ham bekor qilamiz.
        final alarmId = act['alarm_id'];
        final deleted = act['deleted'] == true;
        final enabled = act['enabled'];
        if (alarmId is int && (deleted || enabled == false)) {
          try {
            await NotificationHelper().cancelAlarm(alarmId);
          } catch (_) {}
        }
      }
      // orders_changed / plans_changed / todos_changed / shopping_changed /
      // finance_changed — bu ekranlar ochilganда/refresh'да serverdan yangilanadi,
      // shu sabab qo'shimcha lokal amal talab qilinmaydi.
    } catch (e) {
      debugPrint('AI action bajarishda xato: $e');
    }
  }

  /// Chat tarixini tozalaydi (xotira + disk).
  Future<void> clearHistory() async {
    _messages.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }
}
