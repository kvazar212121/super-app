// Chat ekranidagi RASM oqimi — haqiqiy widgetlar bilan.
//
// Foydalanuvchi talabi (aynan): "men rasmga olib tashlaganimda srazi
// chatga ketmasin, yani men rasm tagiga matn yozib yubormagunimcha
// yoki yuborish tugmasini bosmagunimcha".
//
// `chat_photo_flow_test.dart` bu qoidani MANBA KODI darajasida
// qo'riqlaydi. Bu fayl esa ekranni HAQIQATAN quradi va foydalanuvchi
// ko'radigan holatni tekshiradi: qanday tugma chiqadi, matn yozilsa
// nima o'zgaradi. Kamera/galereya test muhitida yo'q, shuning uchun
// rasm tanlash bosqichi o'tkazib yuboriladi va ekranning qolgan
// xatti-harakati sinaladi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/chat_screen.dart';

Widget _qur() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
      ],
      child: const MaterialApp(home: ChatScreen()),
    );

/// Ekrandan chiqib, qolgan taymerlarni bo'shatadi.
Future<void> _yop(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  testWidgets('Chat ochiladi va yozish maydoni bor', (tester) async {
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsOneWidget,
        reason: 'xabar yozish maydoni topilmadi');
    await _yop(tester);
  });

  testWidgets('Rasm tanlash tugmasi mavjud', (tester) async {
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget,
        reason: 'rasm qo\'shish tugmasi yo\'q');
    await _yop(tester);
  });

  testWidgets('Rasm tanlanmaganda oldindan ko\'rish paneli YO\'Q',
      (tester) async {
    // Panel faqat rasm kutayotganda chiqishi kerak, aks holda u
    // doim joy egallab, yozish maydonini siqib qo'yardi.
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rasm tayyor'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    await _yop(tester);
  });

  testWidgets('Bo\'sh maydonda MIKROFON, matn yozilsa YUBORISH',
      (tester) async {
    // Rasm kutayotganda ham xuddi shu mantiq bo'yicha yuborish
    // belgisi chiqadi (kodda `_hasText || _pendingPhoto != null`).
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(LucideIcons.mic), findsOneWidget,
        reason: 'bo\'sh chatda mikrofon bo\'lishi kerak');
    expect(find.byIcon(LucideIcons.send), findsNothing);

    await tester.enterText(find.byType(TextField), 'kran oqyapti');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(LucideIcons.send), findsOneWidget,
        reason: 'matn yozilgach yuborish belgisi chiqishi kerak');
    expect(find.byIcon(LucideIcons.mic), findsNothing);
    await _yop(tester);
  });

  testWidgets('Rasm manbasi so\'raladi (kamera/galereya)', (tester) async {
    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    // Tanlov oynasi chiqadi — ya'ni bosish darhol yubormaydi.
    expect(find.text('Rasmga olish'), findsOneWidget);
    expect(find.text('Galereyadan tanlash'), findsOneWidget);

    // Oynani yopamiz (bekor qilish) — hech narsa yuborilmasligi kerak.
    await tester.tapAt(const Offset(200, 60));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('📷 Rasm yuborildi'), findsNothing,
        reason: 'bekor qilinganda chatga hech narsa qo\'shilmasin');
    await _yop(tester);
  });
}
