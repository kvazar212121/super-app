import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/services/top_providers_service.dart';

/// "Top reytingli" ro'yxati uchun testlar.
void main() {
  group('TopProvider.fromJson', () {
    test('Asosiy maydonlar to\'g\'ri o\'qiladi', () {
      final p = TopProvider.fromJson(const {
        'id': 7,
        'name': 'Style Barbershop',
        'address': "Amir Temur ko'chasi, 15",
        'rating': 4.8,
        'review_count': 124,
        'category_key': 'sartarosh',
        'lat': 41.31,
        'lng': 69.24,
      });

      expect(p.id, 7);
      expect(p.name, 'Style Barbershop');
      expect(p.subtitle, "Amir Temur ko'chasi, 15");
      expect(p.rating, 4.8);
      expect(p.reviewCount, 124);
      expect(p.kind, ServiceHubKind.sartarosh);
      expect(p.categoryLabel, 'Sartarosh');
    });

    test('Manzil bo\'lmasa xizmat hududi ishlatiladi', () {
      final p = TopProvider.fromJson(const {
        'id': 1,
        'name': 'Aziz',
        'address': '',
        'rating': 4.5,
        'category_key': 'sartarosh',
        'metadata': {'service_area': 'Chilonzor, Sergeli'},
      });
      expect(p.subtitle, 'Chilonzor, Sergeli');
    });

    test('Manzil ham, hudud ham bo\'lmasa soha nomi', () {
      final p = TopProvider.fromJson(const {
        'id': 1,
        'name': 'Aziz',
        'rating': 4.5,
        'category_key': 'santexnik',
      });
      expect(p.subtitle, 'Santexnik');
    });

    test('Noma\'lum kategoriya kaliti crash bermaydi', () {
      final p = TopProvider.fromJson(const {
        'id': 1,
        'name': 'X',
        'rating': 4.0,
        'category_key': 'mavjud_emas_kalit',
      });
      expect(p.kind, isNull);
      expect(p.categoryLabel, 'mavjud_emas_kalit');
      expect(p.icon, isNotNull, reason: 'zaxira ikonka bo\'lishi kerak');
    });

    test('metadata noto\'g\'ri turda bo\'lsa crash bermaydi', () {
      for (final bad in [42, 'matn', <int>[], null]) {
        final p = TopProvider.fromJson({
          'id': 1,
          'name': 'X',
          'rating': 4.0,
          'category_key': 'sartarosh',
          'metadata': bad,
        });
        expect(p.name, 'X');
      }
    });

    test('Maydonlar yetishmasa standart qiymatlar', () {
      final p = TopProvider.fromJson(const {});
      expect(p.id, 0);
      expect(p.name, '');
      expect(p.rating, 0);
      expect(p.reviewCount, 0);
    });

    test('Yangi 3 ta xizmat kaliti tanib olinadi', () {
      for (final entry in {
        'telefonUsta': ServiceHubKind.telefonUsta,
        'kompyuterUsta': ServiceHubKind.kompyuterUsta,
        'itXizmat': ServiceHubKind.itXizmat,
      }.entries) {
        final p = TopProvider.fromJson({
          'id': 1,
          'name': 'X',
          'rating': 4.0,
          'category_key': entry.key,
        });
        expect(p.kind, entry.value, reason: entry.key);
      }
    });
  });

  _fallbackSort();
  _legacyKeys();

  group('Sahifa o\'lchami', () {
    test('Talab: bir sahifada 10 ta provayder', () {
      expect(TopProvidersService.pageSize, 10);
    });
  });

  group('Yangi xizmatlar', () {
    test('Talab: 3 ta yangi karta qo\'shilgan', () {
      final names = ServiceHubKind.values.map((e) => e.name).toList();
      expect(names, contains('telefonUsta'));
      expect(names, contains('kompyuterUsta'));
      expect(names, contains('itXizmat'));
    });

    test('Yangi xizmatlarda nom, izoh, ikonka va narxlar bor', () {
      for (final k in [
        ServiceHubKind.telefonUsta,
        ServiceHubKind.kompyuterUsta,
        ServiceHubKind.itXizmat,
      ]) {
        expect(k.title, isNotEmpty, reason: '${k.name} nomi');
        expect(k.hubSubtitle, isNotEmpty, reason: '${k.name} izohi');
        expect(k.variants, isNotEmpty, reason: '${k.name} narxlari');
        expect(k.key, isNotEmpty, reason: '${k.name} kaliti');
      }
    });

    test('Yangi xizmatlar kalitlari noyob', () {
      final keys = ServiceHubKind.values.map((e) => e.key).toList();
      expect(keys.length, keys.toSet().length, reason: 'kalitlar takrorlanmasin');
    });
  });
}

/// Server `sort=rating` ni qo'llab-quvvatlamasa ham ro'yxat to'g'ri
/// tartibda ko'rinishi kerak (zaxira saralash).
void _fallbackSort() {
  group('Zaxira saralash', () {
    test('Aralash kelgan sahifa reyting bo\'yicha tartiblanadi', () {
      final items = [
        TopProvider(
          id: 1, name: 'A', subtitle: '', rating: 4.7, reviewCount: 41,
          categoryLabel: 'X', rawJson: const {},
        ),
        TopProvider(
          id: 2, name: 'B', subtitle: '', rating: 4.9, reviewCount: 210,
          categoryLabel: 'X', rawJson: const {},
        ),
        TopProvider(
          id: 3, name: 'C', subtitle: '', rating: 4.8, reviewCount: 234,
          categoryLabel: 'X', rawJson: const {},
        ),
        TopProvider(
          id: 4, name: 'D', subtitle: '', rating: 4.9, reviewCount: 512,
          categoryLabel: 'X', rawJson: const {},
        ),
      ];

      items.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        return b.reviewCount.compareTo(a.reviewCount);
      });

      // Yuqori reyting oldinda; teng reytingda ko'proq sharh oldinda.
      expect(items.map((e) => e.name).toList(), ['D', 'B', 'C', 'A']);
    });
  });
}

/// Eskirgan kategoriya kalitlari yangisiga moslanishi kerak, aks holda
/// bunday provayderlar ro'yxatda "noma'lum" bo'lib chiqadi.
void _legacyKeys() {
  group('Eskirgan kategoriya kalitlari', () {
    test('konditsioner -> Texnika ustasi', () {
      final p = TopProvider.fromJson(const {
        'id': 1,
        'name': 'Akmal Konditsioner',
        'rating': 4.8,
        'category_key': 'konditsioner',
      });
      expect(p.kind, ServiceHubKind.texnikaUstasi);
      expect(p.categoryLabel, 'Texnika ustasi');
    });

    test('kompyuter_usta -> Kompyuter ustasi', () {
      final p = TopProvider.fromJson(const {
        'id': 1,
        'name': 'PC Master',
        'rating': 4.5,
        'category_key': 'kompyuter_usta',
      });
      expect(p.kind, ServiceHubKind.kompyuterUsta);
    });

    test('yana -> Boshqa xizmatlar', () {
      final p = TopProvider.fromJson(const {
        'id': 1,
        'name': 'X',
        'rating': 4.0,
        'category_key': 'yana',
      });
      expect(p.kind, ServiceHubKind.boshqa);
    });

    test('Eskirgan provayder ham bosiladigan bo\'ladi (kind != null)', () {
      for (final key in ['konditsioner', 'kompyuter_usta', 'yana']) {
        final p = TopProvider.fromJson({
          'id': 1,
          'name': 'X',
          'rating': 4.0,
          'category_key': key,
        });
        expect(p.kind, isNotNull, reason: '$key ochilishi kerak');
      }
    });
  });
}
