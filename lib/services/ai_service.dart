import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  late final Dio _dio;

  AiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.groq.com/openai/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        },
      ),
    );
  }

  // SuperApp System Prompt
  final String _systemPrompt = """Siz HubServis SuperApp (universal ilovasi) uchun sun'iy intellekt yordamchisisiz. 
Sizning asosiy vazifangiz — foydalanuvchilarga ilovani qanday ishlatish bo'yicha yo'l-yo'riq ko'rsatish va savollariga xushmuomalalik bilan o'zbek tilida javob berishdir.

ILOVANING ASOSIY BO'LIMLARI VA FUNKSIYALARI:
1. Rejalarim (Kundalik vazifalar va eslatmalar): Foydalanuvchi ma'lum sana va vaqtga rejalar (Tasklar) qo'shishi mumkin. Belgilangan vaqt kelganda ilova eslatma yuboradi.
2. Mening moliyam (Finance Manager): Foydalanuvchi daromad va xarajatlarini kiritib boradi. Oylik byudjet tahlil qilinadi, qaysi sohaga (masalan, ovqatlanish, transport) qancha ketayotgani foizlarda ko'rsatiladi. Shuningdek, qarz yoki kredit kabi doimiy to'lovlarni ham kiritish mumkin va AI xarajatlar daromaddan oshib ketsa ogohlantiradi.
3. Aqlli savdo (Bozorlik ro'yxati): Foydalanuvchi bozorga borishdan oldin ro'yxat tuzadi. Ilova o'zbek bozoridagi o'rtacha narxlar bo'yicha mahsulotlarning taxminiy narxini hisoblab beradi. Foydalanuvchi keyin haqiqiy xarid narxini kiritib taqqoslashi mumkin.
4. Barcha xizmatlar: Ilovada ustalar, tozalash, enaga, repetitor, avto yordam, sartarosh, massaj kabi 15 dan ortiq turdagi xizmatlarga buyurtma berish mumkin. Foydalanuvchilar o'zlari ham xizmat ko'rsatuvchi (Provider) sifatida ro'yxatdan o'tishlari mumkin.
5. Aksiyalar (Promos): Foydalanuvchi chegirma kodlari va aksiyalardan foydalana oladi.

QOIDALAR:
- Foydalanuvchiga faqat o'zbek tilida javob bering.
- Juda qisqa, tushunarli va do'stona (ammo rasmiyroq) ohangda yozing.
- Ilova imkoniyatlaridan tashqari mavzulardagi savollarga: "Kechirasiz, men faqat HubServis SuperApp ilovasi bo'yicha yordam bera olaman" deb javob bering.
- Javoblarni uzun paragraf emas, balki punktlar va emojilar bilan bezatib bering.""";

  /// Jo'natish uchun chat tarixini saqlaydi
  final List<Map<String, String>> _messages = [];

  Future<String> sendMessage(String userText) async {
    // Agar chat tarixi bo'sh bo'lsa, avval system prompt qo'shamiz
    if (_messages.isEmpty) {
      _messages.add({'role': 'system', 'content': _systemPrompt});
    }

    _messages.add({'role': 'user', 'content': userText});

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'qwen/qwen3-32b',
          'messages': _messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        },
      );

      final responseData = response.data;
      if (responseData['choices'] != null && responseData['choices'].isNotEmpty) {
        String aiMessage = responseData['choices'][0]['message']['content'] as String;
        
        // Remove <think> blocks if the model returns them
        aiMessage = aiMessage.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
        
        _messages.add({'role': 'assistant', 'content': aiMessage});
        return aiMessage;
      }
      return "Kechirasiz, javob olishda xatolik yuz berdi.";
    } on DioException catch (e) {
      debugPrint("Groq API Error: \${e.response?.data ?? e.message}");
      // Faqatgina 401 bo'lsa, aniq xabar beramiz
      if (e.response?.statusCode == 401) {
        return "API kaliti noto'g'ri yoki kiritilmagan. Iltimos, sozlarni tekshiring.";
      }
      return "Internet bilan muammo yoki xizmat vaqtincha ishlamayapti.";
    } catch (e) {
      debugPrint("AI Service Error: \$e");
      return "Kutilmagan xatolik yuz berdi.";
    }
  }

  void clearHistory() {
    _messages.clear();
  }
}
