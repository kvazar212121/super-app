import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/config/map_config.dart';

/// Xarita provayderi sozlamalari testlari.
///
/// Asosiy maqsad: production'da taqiqlangan demo tile serverlari qaytib
/// kelmasligini va kalit kodga yozilib qolmasligini qo'riqlash.
void main() {
  group('Tile manzili', () {
    test('Kalitsiz (dev) — OSM zaxirasi ishlatiladi', () {
      // Testlar --dart-define siz ishlaydi, ya'ni kalit bo'sh.
      expect(MapConfig.hasKey, isFalse,
          reason: 'testda kalit berilmagan bo\'lishi kerak');
      expect(MapConfig.tileUrl(), contains('tile.openstreetmap.org'));
    });

    test('Kalit BERILGANDA MapTiler ishlatiladi (production yo\'li)', () {
      // Bu eng muhim holat: relizda aynan shu tarmoq ishlaydi. Kalit
      // compile-time konstanta bo'lgani uchun uni testda bevosita
      // o'zgartirib bo'lmaydi, shuning uchun sof `tileUrlFor` sinaladi.
      const key = 'TEST_KEY_123';
      final url = MapConfig.tileUrlFor(key);
      expect(url, contains('api.maptiler.com'));
      expect(url, contains('key=$key'));
      expect(url, contains(MapConfig.style));
      expect(url, startsWith('https://'));
      for (final t in ['{z}', '{x}', '{y}']) {
        expect(url, contains(t));
      }
    });

    test('Kalit bilan qorong\'i uslub ham to\'g\'ri', () {
      final dark = MapConfig.tileUrlFor('K', dark: true);
      expect(dark, contains(MapConfig.darkStyle));
      expect(dark, isNot(MapConfig.tileUrlFor('K')));
    });

    test('Bo\'sh kalit — OSM zaxirasi (dev holati)', () {
      expect(MapConfig.tileUrlFor(''), contains('tile.openstreetmap.org'));
    });

    test('tileUrl() va tileUrlFor() bir xil natija beradi', () {
      // Ikkisi ajralib ketmasligi kerak: aks holda test bir yo'lni,
      // ilova boshqa yo'lni ishlatgan bo'lardi.
      expect(MapConfig.tileUrl(), MapConfig.tileUrlFor(MapConfig.maptilerKey));
      expect(MapConfig.tileUrl(dark: true),
          MapConfig.tileUrlFor(MapConfig.maptilerKey, dark: true));
    });

    test('Manzil {z}/{x}/{y} shablonini saqlaydi', () {
      for (final url in [MapConfig.tileUrl(), MapConfig.fallbackUrl]) {
        expect(url, contains('{z}'));
        expect(url, contains('{x}'));
        expect(url, contains('{y}'));
      }
    });

    test('Manzillar HTTPS', () {
      expect(MapConfig.tileUrl(), startsWith('https://'));
      expect(MapConfig.fallbackUrl, startsWith('https://'));
    });

    test('Qorong\'i uslub alohida', () {
      expect(MapConfig.style, isNot(MapConfig.darkStyle));
    });

    test('Ilova identifikatori to\'g\'ri', () {
      expect(MapConfig.userAgent, 'uz.hubservis.app',
          reason: 'tile serverlari uchun haqiqiy paket nomi bo\'lsin');
    });

    test('tileLayer() tayyor qatlam qaytaradi', () {
      final layer = MapConfig.tileLayer();
      expect(layer.urlTemplate, MapConfig.tileUrl());
      expect(layer.fallbackUrl, MapConfig.fallbackUrl);
      // `userAgentPackageName` TileLayer'da ochiq maydon emas — u ichki
      // HTTP mijozga uzatiladi, shuning uchun konstantani tekshiramiz.
      expect(MapConfig.userAgent, isNotEmpty);
    });
  });

  group('Manba kodi qoidalari', () {
    /// `lib/` ichidagi barcha dart fayllar.
    List<File> libFiles() {
      final dir = Directory('lib');
      return dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    }

    test('Hech bir ekranda tile manzili QO\'LDA yozilmagan', () {
      final offenders = <String>[];
      for (final f in libFiles()) {
        if (f.path.endsWith('config/map_config.dart')) continue;
        final text = f.readAsStringSync();
        if (text.contains('cartocdn') ||
            text.contains('tile.openstreetmap.org')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'tile manzili faqat MapConfig da bo\'lsin, topildi: '
              '$offenders');
    });

    test('MapTiler kaliti kodga yozilmagan', () {
      // Kalit --dart-define orqali beriladi. Kodda uchrashi — sirning
      // git tarixiga tushishi demak.
      final offenders = <String>[];
      final keyPattern = RegExp(r"key\s*[:=]\s*'[A-Za-z0-9]{15,}'");
      for (final f in libFiles()) {
        final text = f.readAsStringSync();
        if (text.contains('api.maptiler.com') &&
            keyPattern.hasMatch(text) &&
            !text.contains('String.fromEnvironment')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty, reason: 'kalit kodda: $offenders');
    });

    test('Har bir FlutterMap MapConfig ni ishlatadi', () {
      final offenders = <String>[];
      for (final f in libFiles()) {
        final text = f.readAsStringSync();
        if (!text.contains('FlutterMap(')) continue;
        if (!text.contains('MapConfig.tileLayer()')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'bu ekranlar markaziy sozlamani ishlatmayapti: $offenders');
    });

    test('To\'liq ekranli xaritalarda manba ko\'rsatilgan (litsenziya)', () {
      // Kichik preview (hub_map_preview) bundan mustasno — u bosilganda
      // to'liq ekran ochiladi va u yerda manba ko'rinadi.
      const exempt = ['hub_map_preview.dart'];
      final offenders = <String>[];
      for (final f in libFiles()) {
        final text = f.readAsStringSync();
        if (!text.contains('FlutterMap(')) continue;
        if (exempt.any(f.path.endsWith)) continue;
        if (!text.contains('MapConfig.attribution(')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'manba ko\'rsatilmagan (ODbL buzilishi): $offenders');
    });
  });
}
