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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/chat_screen.dart';

/// Test uchun kichik rasm fayli (1x1 PNG).
XFile _soxtaRasm() {
  final f = File('${Directory.systemTemp.path}/test_rasm.png');
  if (!f.existsSync()) {
    // Eng kichik haqiqiy PNG.
    f.writeAsBytesSync(<int>[
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1,
      13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);
  }
  return XFile(f.path);
}

Widget _qur({XFile? rasm}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
      ],
      child: MaterialApp(home: ChatScreen(initialPhoto: rasm)),
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

  testWidgets('Rasm kutayotganda YUBORISH belgisi (mikrofon EMAS)',
      (tester) async {
    // Eng muhim holat: rasm tanlangan, matn yozilmagan. Agar
    // mikrofon qolsa, foydalanuvchi rasmni qanday yuborishni
    // bilmay qoladi.
    await tester.pumpWidget(_qur(rasm: _soxtaRasm()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(LucideIcons.send), findsOneWidget,
        reason: 'rasm bor, lekin yuborish belgisi yo\'q');
    expect(find.byIcon(LucideIcons.mic), findsNothing,
        reason: 'rasm bor ekan mikrofon ko\'rsatilmasin');
    await _yop(tester);
  });

  testWidgets('Rasm kutayotganda oldindan ko\'rish paneli CHIQADI',
      (tester) async {
    await tester.pumpWidget(_qur(rasm: _soxtaRasm()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rasm tayyor'), findsOneWidget,
        reason: 'foydalanuvchi nima yuborayotganini ko\'rmayapti');
    expect(find.text('Muammoni yozing va yuboring'), findsOneWidget);
    expect(find.byType(Image), findsWidgets,
        reason: 'rasmning o\'zi ko\'rinishi kerak');
    await _yop(tester);
  });

  testWidgets('Rasmni bekor qilish panelni yopadi', (tester) async {
    await tester.pumpWidget(_qur(rasm: _soxtaRasm()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rasm tayyor'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rasm tayyor'), findsNothing,
        reason: 'bekor qilingach panel yo\'qolishi kerak');
    expect(find.byIcon(LucideIcons.mic), findsOneWidget,
        reason: 'rasm yo\'q ekan mikrofonga qaytsin');
    await _yop(tester);
  });

  testWidgets('Rasm bilan birga matn yozish mumkin', (tester) async {
    await tester.pumpWidget(_qur(rasm: _soxtaRasm()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'rozetka ishlamayapti');
    await tester.pump(const Duration(milliseconds: 200));

    // Panel ham, matn ham, yuborish belgisi ham bir vaqtda turadi.
    expect(find.text('Rasm tayyor'), findsOneWidget);
    expect(find.text('rozetka ishlamayapti'), findsOneWidget);
    expect(find.byIcon(LucideIcons.send), findsOneWidget);
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
