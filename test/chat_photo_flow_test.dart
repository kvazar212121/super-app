// Chat ekranida RASM oqimi: tanlanishi bilan darhol YUBORILMAYDI.
//
// Foydalanuvchi talabi (aynan): "men rasmga olib tashlaganimda srazi
// chatga ketmasin, yani men rasm tagiga matn yozib yubormagunimcha
// yoki yuborish tugmasini bosmagunimcha".
//
// Bu xatti-harakat kod tuzilishi darajasida qo'riqlanadi: ekranni
// to'liq qurish uchun tarmoq va kamera kerak (test muhitida yo'q),
// shuning uchun manba kodi qoidalari tekshiriladi. Qoida buzilsa
// (masalan kimdir yana `_sendJobPhoto` ni tiklasa) test yiqiladi.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String src;

  setUpAll(() {
    src = File('lib/screens/chat_screen.dart').readAsStringSync();
  });

  group('Rasm darhol yuborilmaydi', () {
    test('Rasm tanlash faqat holatga saqlaydi', () {
      // `_pickJobPhoto` rasmni tanlaydi va `_pendingPhoto` ga qo'yadi.
      expect(src, contains('_pickJobPhoto'),
          reason: 'rasm tanlash funksiyasi yo\'q');
      expect(src, contains('_pendingPhoto = picked'),
          reason: 'tanlangan rasm kutish holatiga saqlanishi kerak');
    });

    test('Eski "tanladi = yubordi" oqimi qaytib kelmagan', () {
      // Ilgari `_sendJobPhoto` tanlash bilan darhol yuborardi.
      expect(src.contains('_sendJobPhoto'), isFalse,
          reason: 'rasm tanlanishi bilan yuborilmasligi kerak');
    });

    test('Tanlash funksiyasi ichida yuborish YO\'Q', () {
      // `_pickJobPhoto` tanasi: yuborish chaqiruvi bo'lmasligi shart.
      final start = src.indexOf('Future<void> _pickJobPhoto');
      expect(start, greaterThan(-1));
      final end = src.indexOf('void _clearPendingPhoto', start);
      expect(end, greaterThan(start));
      final body = src.substring(start, end);

      expect(body.contains('sendJobPhotoToAi'), isFalse,
          reason: 'tanlash paytida serverga yuborilmasligi kerak');
      expect(body.contains('_sendMessage'), isFalse,
          reason: 'tanlash paytida AI ga xabar ketmasligi kerak');
      expect(body.contains('_sendPendingPhoto'), isFalse,
          reason: 'tanlash o\'zi yubormasligi kerak');
    });

    test('Yuborish alohida qadam sifatida mavjud', () {
      expect(src, contains('Future<void> _sendPendingPhoto'));
      final start = src.indexOf('Future<void> _sendPendingPhoto');
      final body = src.substring(start, start + 2500);
      expect(body, contains('sendJobPhotoToAi'),
          reason: 'aynan shu yerda serverga ketishi kerak');
    });
  });

  group('Foydalanuvchi rasmni yubora oladi', () {
    test('Yuborish tugmasi rasmni jo\'natadi', () {
      // Tugma bosilganda `_sendPendingPhoto` chaqirilishi kerak.
      expect(src, contains('if (!_isTyping) _sendPendingPhoto();'),
          reason: 'yuborish tugmasi rasmni yubormayapti');
    });

    test('Klaviaturadagi "yuborish" ham ishlaydi', () {
      final start = src.indexOf('onSubmitted:');
      expect(start, greaterThan(-1));
      final body = src.substring(start, start + 400);
      expect(body, contains('_sendPendingPhoto'),
          reason: 'matn yozib Enter bosilganda rasm ketishi kerak');
    });

    test('Rasm bo\'lsa tugma "yuborish" ko\'rinishida', () {
      // Aks holda foydalanuvchi mikrofon belgisini ko'rib, rasmni
      // qanday yuborishni bilmay qoladi.
      expect(src, contains('(_hasText || _pendingPhoto != null)'),
          reason: 'rasm kutayotganda tugma yuborish holatida bo\'lsin');
    });

    test('Rasmni bekor qilish mumkin', () {
      expect(src, contains('_clearPendingPhoto'));
      expect(src, contains('_pendingPhoto = null'));
    });
  });

  group('Foydalanuvchi nima yuborganini ko\'radi', () {
    test('Kutayotgan rasm oldindan ko\'rsatiladi', () {
      expect(src, contains('_pendingPhotoPreview'),
          reason: 'tanlangan rasm ekranda ko\'rinishi kerak');
      expect(src, contains('if (_pendingPhoto != null) _pendingPhotoPreview'),
          reason: 'panel faqat rasm bor bo\'lganda chiqsin');
    });

    test('Yuborilgan rasm chat tarixida qoladi', () {
      expect(src, contains("'localPhoto': photo.path"),
          reason: 'yuborilgan rasm xabarga biriktirilishi kerak');
      expect(src, contains('localPhoto: message[\'localPhoto\']'),
          reason: 'xabar puffagi rasmni ko\'rsatishi kerak');
    });

    test('Foydalanuvchi izohi rasm bilan birga ketadi', () {
      final start = src.indexOf('Future<void> _sendPendingPhoto');
      final body = src.substring(start, start + 2500);
      expect(body, contains('_textController.text.trim()'),
          reason: 'rasm tagiga yozilgan matn olinishi kerak');
      expect(body, contains('Foydalanuvchi izohi'),
          reason: 'izoh AI ga uzatilishi kerak');
    });

    test('Texnik matn chatda ko\'rinmaydi', () {
      // Rasm URL'i va vision tahlili foydalanuvchiga ko'rsatilmaydi —
      // u xom `Rasm: /uploads/...` matnini ko'rmasligi kerak.
      expect(src, contains('silent: true'),
          reason: 'texnik xabar jimgina yuborilishi kerak');
      expect(src, contains('bool silent = false'),
          reason: '_sendMessage silent parametrini qo\'llab-quvvatlasin');
    });

    test('Rasm yuklanayotganda ikki marta bosib bo\'lmaydi', () {
      expect(src, contains('_photoUploading'),
          reason: 'takroriy yuborishdan himoya kerak');
      expect(src, contains('if (photo == null || _photoUploading) return;'));
    });
  });
}
