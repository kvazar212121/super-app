// Tasdiq so'ralganda katta «Ha / Yo'q» tugmalari.
//
// HAQIQIY SHIKOYAT: AI xulosani «E'lon tayyor ✅» deb boshlagan va
// foydalanuvchi ish tugadi deb o'ylab, pastdagi «E'lon berilsinmi?»
// savolini o'qimay ketib qolgan — e'lon berilmay qolgan.
//
// Yechim ikki qismli:
//   1. Backend modelga «tayyor» deb yozmaslikni buyuradi (prompt).
//   2. Ilova `confirm_request` amalini ko'rib KATTA tugmalar chiqaradi.
// Bu fayl ikkinchi qismni qo'riqlaydi.
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

Map<String, dynamic> _tasdiqAmali({String kind = 'listing'}) => {
  'type': 'confirm_request',
  'kind': kind,
  'summary': 'iPhone 13 Pro 256GB\n4 500 000 so\'m',
  'question': 'Shu e\'lonni tasdiqlaysizmi?',
  'yes_text': 'Ha, e\'lon bering',
  'no_text': 'Yo\'q, tuzataman',
};

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

  testWidgets('Tasdiq so\'ralganda Ha va Yo\'q tugmalari chiqadi', (
    tester,
  ) async {
    _tarix([
      {'role': 'user', 'content': 'telefonimni sotmoqchiman'},
      {
        'role': 'assistant',
        'content': 'E\'loningizni tekshiring 👇',
        'actions': [_tasdiqAmali()],
      },
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Shu e\'lonni tasdiqlaysizmi?'), findsOneWidget);
    expect(find.text('Ha, e\'lon bering'), findsOneWidget);
    expect(find.text('Yo\'q, tuzataman'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('Tugmalar KATTA (kamida 48px balandlik)', (tester) async {
    // Kichik tugma e'tibordan chetda qoladi — shikoyatning sababi shu.
    _tarix([
      {'role': 'user', 'content': 'sotmoqchiman'},
      {
        'role': 'assistant',
        'content': 'Tekshiring',
        'actions': [_tasdiqAmali()],
      },
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    final haBalandligi = tester
        .getSize(find.ancestor(
          of: find.text('Ha, e\'lon bering'),
          matching: find.byType(FilledButton),
        ))
        .height;
    expect(haBalandligi, greaterThanOrEqualTo(48.0),
        reason: 'tasdiq tugmasi barmoq bilan bosishga qulay bo\'lishi kerak');

    await _yop(tester);
  });

  testWidgets('"Ha" bosilganda tasdiq matni yuboriladi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'sotmoqchiman'},
      {
        'role': 'assistant',
        'content': 'Tekshiring',
        'actions': [_tasdiqAmali()],
      },
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Ha, e\'lon bering'));
    await tester.pump(const Duration(milliseconds: 300));

    // Foydalanuvchi xabari sifatida chatga tushadi (model uni tasdiq
    // deb tushunadi).
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Ha, e\'lon bering'),
      ),
      findsWidgets,
    );

    await _yop(tester);
  });

  testWidgets('Ish e\'loni uchun ham tugmalar chiqadi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'kranim oqyapti'},
      {
        'role': 'assistant',
        'content': 'Tekshiring',
        'actions': [_tasdiqAmali(kind: 'job')],
      },
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ha, e\'lon bering'), findsOneWidget);
    expect(find.text('Yo\'q, tuzataman'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('Oddiy xabarda tasdiq tugmalari yo\'q', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'salom'},
      {'role': 'assistant', 'content': 'Assalomu alaykum!'},
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('tasdiqlaysizmi'), findsNothing);

    await _yop(tester);
  });

  testWidgets('Amal to\'liq bo\'lmasa ham chat yiqilmaydi', (tester) async {
    _tarix([
      {'role': 'user', 'content': 'sotmoqchiman'},
      {
        'role': 'assistant',
        'content': 'Tekshiring',
        // Backend eski versiyada matnsiz yuborishi mumkin.
        'actions': [
          {'type': 'confirm_request'},
        ],
      },
    ]);
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    // Standart matnlar ishlatiladi.
    expect(find.text('Ha'), findsOneWidget);

    await _yop(tester);
  });
}
