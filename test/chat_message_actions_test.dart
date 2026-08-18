// Chat xabarini TAHRIRLASH / QAYTA YUBORISH / O'CHIRISH.
//
// Foydalanuvchi talabi: "agent bilan yuborgan smslarni replace qilib
// qayta yuborish va o'chirish". Ilgari faqat BUTUN chatni tozalash
// bor edi — bitta xato yozuv uchun hamma narsa yo'qolardi.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/chat_screen.dart';
import 'package:super_app/services/ai_service.dart';

void _tarix(List<Map<String, dynamic>> xabarlar) {
  SharedPreferences.setMockInitialValues({
    'ai_chat_history_v2': jsonEncode(xabarlar),
  });
}

Widget _qur() => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
  ],
  child: const MaterialApp(home: ChatScreen()),
);

Future<void> _yop(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  setUp(() => AiService().resetHistoryCache());

  testWidgets('Xabarni uzun bosganda menyu chiqadi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'telefonimni sotmoqchiman'},
      {'role': 'assistant', 'content': 'Qanday telefon?'},
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.longPress(find.text('telefonimni sotmoqchiman'));
    await tester.pumpAndSettle();

    expect(find.text('Nusxalash'), findsOneWidget);
    expect(find.text('Tahrirlash va qayta yuborish'), findsOneWidget);
    expect(find.text('Qayta yuborish'), findsOneWidget);
    expect(find.text('O\'chirish'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('Tahrirlash: matn kirish maydoniga qaytadi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'telefonimni sotmoqchimna'}, // xato yozilgan
      {'role': 'assistant', 'content': 'Tushunmadim'},
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.longPress(find.text('telefonimni sotmoqchimna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tahrirlash va qayta yuborish'));
    await tester.pumpAndSettle();

    // Matn tuzatish uchun maydonga qaytadi.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'telefonimni sotmoqchimna');
    // Xabar va undan keyingi AI javobi chatdan olib tashlanadi:
    // eski savol kontekstda qolsa model o'zini takrorlaydi.
    // (Matn faqat kirish maydonida qoladi, chat pufagida emas —
    // shuning uchun EditableText ni hisobdan chiqaramiz.)
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('telefonimni sotmoqchimna'),
      ),
      findsNothing,
    );
    expect(find.text('Tushunmadim'), findsNothing);

    await _yop(tester);
  });

  testWidgets('O\'chirish: xabar chatdan yo\'qoladi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'birinchi savol'},
      {'role': 'assistant', 'content': 'birinchi javob'},
      {'role': 'user', 'content': 'ikkinchi savol'},
      {'role': 'assistant', 'content': 'ikkinchi javob'},
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.longPress(find.text('ikkinchi savol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('O\'chirish'));
    await tester.pumpAndSettle();

    expect(find.text('ikkinchi savol'), findsNothing);
    expect(find.text('ikkinchi javob'), findsNothing);
    // Oldingilari joyida qoladi — butun chat tozalanmaydi.
    expect(find.text('birinchi savol'), findsOneWidget);
    expect(find.text('birinchi javob'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('AI javobini o\'chirish savolni o\'chirmaydi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'savolim'},
      {'role': 'assistant', 'content': 'noto\'g\'ri javob'},
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.longPress(find.text('noto\'g\'ri javob'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('O\'chirish'));
    await tester.pumpAndSettle();

    expect(find.text('noto\'g\'ri javob'), findsNothing);
    expect(find.text('savolim'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('AI javobida tahrirlash tugmasi yo\'q', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'savolim'},
      {'role': 'assistant', 'content': 'javobim'},
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.longPress(find.text('javobim'));
    await tester.pumpAndSettle();

    // AI javobini "qayta yuborish" mantiqsiz.
    expect(find.text('Tahrirlash va qayta yuborish'), findsNothing);
    expect(find.text('Qayta yuborish'), findsNothing);
    expect(find.text('O\'chirish'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('Salomlashish xabari o\'chirilmaydi', (tester) async {
    // U tarixda yo'q, faqat ekranда. O'chirishga urinish xato bermasin.
    _tarix([]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.longPress(find.textContaining('Assalomu alaykum'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Assalomu alaykum'), findsOneWidget);

    await _yop(tester);
  });
}
