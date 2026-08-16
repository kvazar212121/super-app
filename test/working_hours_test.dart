import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/utils/working_hours.dart';

void main() {
  group('parseWorkingHours', () {
    test('"9:00-21:00" formati', () {
      expect(parseWorkingHours('9:00-21:00'), (open: 9, close: 21));
    });

    test('bo\'shliqli "09:00 - 21:00"', () {
      expect(parseWorkingHours('09:00 - 21:00'), (open: 9, close: 21));
    });

    test('qisqa "9-21"', () {
      expect(parseWorkingHours('9-21'), (open: 9, close: 21));
    });

    test('nuqtali va uzun tire "09.00–21.00"', () {
      expect(parseWorkingHours('09.00–21.00'), (open: 9, close: 21));
    });

    test('"24/7" — doim ochiq', () {
      expect(parseWorkingHours('24/7'), (open: 0, close: 24));
    });

    test('yarim tunda yopilish "10:00-00:00" -> close 24', () {
      expect(parseWorkingHours('10:00-00:00'), (open: 10, close: 24));
    });

    test('null / bo\'sh / tushunarsiz -> null', () {
      expect(parseWorkingHours(null), isNull);
      expect(parseWorkingHours(''), isNull);
      expect(parseWorkingHours('   '), isNull);
      expect(parseWorkingHours('har kuni'), isNull);
      expect(parseWorkingHours('9'), isNull, reason: 'bitta son yetarli emas');
    });

    test('teskari oraliq (21-9) qabul qilinmaydi', () {
      expect(parseWorkingHours('21:00-09:00'), isNull);
    });

    test('haqiqiy bo\'lmagan soat (99) qabul qilinmaydi', () {
      expect(parseWorkingHours('99-100'), isNull);
    });
  });

  group('isOpenAt', () {
    test('ish vaqti kiritilgan bo\'lsa SHU ishlatiladi', () {
      // 10:00-14:00 kiritilgan, standart 9-21 e'tiborga olinmaydi.
      expect(
        isOpenAt(
          hours: '10:00-14:00',
          defaultOpen: 9,
          defaultClose: 21,
          now: DateTime(2026, 1, 1, 15),
        ),
        isFalse,
        reason: '15:00 da yopiq (kiritilgan vaqt 14 gacha)',
      );
      expect(
        isOpenAt(
          hours: '10:00-14:00',
          defaultOpen: 9,
          defaultClose: 21,
          now: DateTime(2026, 1, 1, 11),
        ),
        isTrue,
      );
    });

    test('ish vaqti yo\'q bo\'lsa standart oraliq', () {
      expect(
        isOpenAt(defaultOpen: 9, defaultClose: 21, now: DateTime(2026, 1, 1, 10)),
        isTrue,
      );
      expect(
        isOpenAt(defaultOpen: 9, defaultClose: 21, now: DateTime(2026, 1, 1, 22)),
        isFalse,
      );
    });

    test('chegara qiymatlari: ochilish kiradi, yopilish kirmaydi', () {
      expect(
        isOpenAt(defaultOpen: 9, defaultClose: 21, now: DateTime(2026, 1, 1, 9)),
        isTrue,
        reason: '9:00 — ochiq',
      );
      expect(
        isOpenAt(defaultOpen: 9, defaultClose: 21, now: DateTime(2026, 1, 1, 21)),
        isFalse,
        reason: '21:00 — yopilgan',
      );
    });

    test('24/7 har doim ochiq', () {
      for (final h in [0, 3, 12, 23]) {
        expect(
          isOpenAt(
            hours: '24/7',
            defaultOpen: 9,
            defaultClose: 21,
            now: DateTime(2026, 1, 1, h),
          ),
          isTrue,
          reason: 'soat $h da ham ochiq',
        );
      }
    });
  });

  _robustness();

  group('workingHoursFrom', () {
    test('metadata.hours dan oladi', () {
      expect(
        workingHoursFrom(const {
          'metadata': {'hours': '9:00-21:00'},
        }),
        '9:00-21:00',
      );
    });

    test('metadata.working_hours ham qo\'llab-quvvatlanadi', () {
      expect(
        workingHoursFrom(const {
          'metadata': {'working_hours': '10-20'},
        }),
        '10-20',
      );
    });

    test('yo\'q bo\'lsa null', () {
      expect(workingHoursFrom(null), isNull);
      expect(workingHoursFrom(const {}), isNull);
      expect(workingHoursFrom(const {'metadata': {}}), isNull);
      expect(
        workingHoursFrom(const {
          'metadata': {'hours': '   '},
        }),
        isNull,
        reason: 'faqat bo\'shliq — yo\'q hisoblanadi',
      );
    });
  });
}

/// Backend kutilmagan turda ma'lumot qaytarganda crash bo'lmasligi.
void _robustness() {
  group('Bardoshlilik (backend kutilmagan ma\'lumot qaytarsa)', () {
    test('metadata String bo\'lsa crash bo\'lmaydi', () {
      expect(workingHoursFrom(const {'metadata': 'buzuq'}), isNull);
    });

    test('metadata raqam bo\'lsa crash bo\'lmaydi', () {
      expect(workingHoursFrom(const {'metadata': 42}), isNull);
    });

    test('metadata ro\'yxat bo\'lsa crash bo\'lmaydi', () {
      expect(workingHoursFrom(const {'metadata': []}), isNull);
    });

    test('hours raqam bo\'lsa (String emas) e\'tiborga olinmaydi', () {
      expect(
        workingHoursFrom(const {
          'metadata': {'hours': 900},
        }),
        isNull,
      );
    });

    test('yuqori darajadagi hours ham o\'qiladi', () {
      expect(workingHoursFrom(const {'hours': '8-18'}), '8-18');
    });
  });
}
