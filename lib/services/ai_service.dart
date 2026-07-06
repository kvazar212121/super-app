import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        receiveTimeout: const Duration(seconds: 45), // AI javob berishi uchun ko'proq vaqt
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Chat tarixini saqlaydi (faqat user va assistant xabarlari)
  final List<Map<String, String>> _messages = [];

  Future<String> sendMessage(String userText) async {
    _messages.add({'role': 'user', 'content': userText});

    try {
      // Auth token ni olish
      final token = await ApiService().getToken();
      if (token == null) {
        return "Iltimos, avval tizimga kiring.";
      }

      final payloadMessages = List<Map<String, String>>.from(_messages);
      if (payloadMessages.isNotEmpty && payloadMessages.last['role'] == 'user') {
        payloadMessages.last = {
          'role': 'user',
          'content': "${payloadMessages.last['content']}\n\n[TIZIM MA'LUMOTI: Foydalanuvchining joriy vaqti: ${DateTime.now().toString()} (Timezone: UTC+5). Har qanday reja yoki vazifa yaratishda ushbu vaqtni hisobga oling va vaqtni to'g'ri UTC+5 ga moslab belgilang.]"
        };
      }

      final response = await _dio.post(
        '/ai/chat',
        data: {
          'messages': payloadMessages,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final responseData = response.data;
      final aiReply = responseData['reply'] as String? ?? '';

      // AI yon-amallarini bajaramiz (masalan budilnikni qurilmada rejalashtirish)
      final actions = (responseData['actions'] as List?) ?? const [];
      for (final act in actions) {
        await _handleAction(Map<String, dynamic>.from(act as Map));
      }

      if (aiReply.isNotEmpty) {
        _messages.add({'role': 'assistant', 'content': aiReply});
        return aiReply;
      }
      return "Kechirasiz, javob olishda xatolik yuz berdi.";
    } on DioException catch (e) {
      debugPrint("AI API Error: ${e.response?.data ?? e.message}");

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
      if (act['type'] == 'schedule_alarm' && act['alarm'] != null) {
        final alarm = Alarm.fromJson(Map<String, dynamic>.from(act['alarm'] as Map));
        await NotificationHelper().scheduleAlarm(alarm);
        debugPrint('AI budilnik rejalashtirildi: ${alarm.timeLabel}');
      }
    } catch (e) {
      debugPrint('AI action bajarishda xato: $e');
    }
  }

  void clearHistory() {
    _messages.clear();
  }
}
