// 3D ko'rinish HAQIQATAN rasmni o'zgartirishini o'lchaydi.
//
// Nega kerak: oldingi testlar `Transform` mavjudligini tekshirardi,
// lekin transform NOTO'G'RI bo'lsa (masalan birlik matritsa) ham
// o'tib ketardi. Bu yerda widget haqiqatan render qilinadi va
// ekrandagi nuqtalar QAYERGA tushgani o'lchanadi.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/widgets/map_3d_view.dart';

/// Bola widget ekranda egallagan to'rtburchak.
Rect _rectOf(WidgetTester tester, Key key) =>
    tester.getRect(find.byKey(key));

void main() {
  const bolaKey = Key('xarita_bolasi');

  Widget qur(double tilt, {double bearing = 0}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: Map3DView(
                tilt: tilt,
                bearing: bearing,
                child: Container(key: bolaKey, color: Colors.green),
              ),
            ),
          ),
        ),
      );

  group('3D haqiqatan ko\'rinishni o\'zgartiradi', () {
    testWidgets('Egilganda xarita KATTALASHADI (bo\'sh joy qolmaydi)',
        (tester) async {
      await tester.pumpWidget(qur(0));
      final tekis = _rectOf(tester, bolaKey);

      await tester.pumpWidget(qur(1));
      await tester.pump();
      final egik = _rectOf(tester, bolaKey);

      // Egilganda xarita kengayishi SHART: aks holda ekran chetlarida
      // bo'sh (kulrang) joy ko'rinib qoladi.
      expect(egik.width, greaterThan(tekis.width),
          reason: '3D da xarita kengaymadi — chetda bo\'shliq qoladi');
      expect(egik.height, greaterThan(tekis.height),
          reason: '3D da xarita balandlashmadi');

      // VA u ko'rinadigan maydonni TO'LIQ qoplashi kerak.
      // Bu tekshiruv haqiqiy kamchilikni topgan edi: avval pastda
      // ~75px bo'sh joy qolar edi.
      expect(egik.top, lessThanOrEqualTo(tekis.top),
          reason: 'tepada bo\'sh joy qoldi');
      expect(egik.bottom, greaterThanOrEqualTo(tekis.bottom - 2),
          reason: 'pastda bo\'sh joy qoldi (xarita ostida kulrang chiziq)');
    });

    testWidgets('Yarim egilish — oraliq holat (animatsiya silliq)',
        (tester) async {
      await tester.pumpWidget(qur(0));
      final a = _rectOf(tester, bolaKey).width;
      await tester.pumpWidget(qur(0.5));
      await tester.pump();
      final b = _rectOf(tester, bolaKey).width;
      await tester.pumpWidget(qur(1));
      await tester.pump();
      final c = _rectOf(tester, bolaKey).width;

      expect(b, greaterThan(a), reason: 'yarim egilish ta\'sir qilmadi');
      expect(c, greaterThan(b), reason: 'to\'liq egilish oraliqdan katta bo\'lsin');
    });

    testWidgets('Egilish ekran chegarasidan CHIQMAYDI', (tester) async {
      // ClipRect bo'lmasa egilgan xarita qo'shni widgetlar ustiga chiqadi.
      await tester.pumpWidget(qur(1));
      await tester.pump();
      expect(find.byType(ClipRect), findsWidgets);

      // Ko'rinadigan qism 400x700 doirasida qolishi kerak.
      final clip = tester.getRect(find.byType(ClipRect).first);
      expect(clip.width, lessThanOrEqualTo(301));
      expect(clip.height, lessThanOrEqualTo(401));
    });

    testWidgets('Burilish (bearing) natijani o\'zgartiradi', (tester) async {
      await tester.pumpWidget(qur(1, bearing: 0));
      await tester.pump();
      final t0 = tester
          .widget<Transform>(find.byType(Transform).first)
          .transform
          .clone();

      await tester.pumpWidget(qur(1, bearing: math.pi / 3));
      await tester.pump();
      final t60 = tester
          .widget<Transform>(find.byType(Transform).first)
          .transform
          .clone();

      expect(t0 == t60, isFalse,
          reason: 'burilish matritsani o\'zgartirmadi — '
              'xarita yo\'nalishga burilmaydi');
    });

    testWidgets('2D da o\'lcham AYNAN o\'zgarmaydi', (tester) async {
      // Eng muhim xavfsizlik: 2D da hech narsa siljimasligi kerak,
      // aks holda foydalanuvchi bosgan joy xaritadagi boshqa nuqtaga
      // tushadi.
      await tester.pumpWidget(qur(0));
      final r = _rectOf(tester, bolaKey);
      expect(r.width, 300);
      expect(r.height, 400);
    });

    testWidgets('Juda kichik tilt ham 2D deb qaraladi (titramasin)',
        (tester) async {
      await tester.pumpWidget(qur(0.0005));
      final r = _rectOf(tester, bolaKey);
      expect(r.width, 300, reason: 'sezilmas tiltda transform qo\'llanmasin');
    });
  });

  group('Perspektiva matritsasi to\'g\'ri', () {
    testWidgets('Chuqurlik (perspective) yozuvi bor', (tester) async {
      await tester.pumpWidget(qur(1));
      await tester.pump();
      final m = tester
          .widget<Transform>(find.byType(Transform).first)
          .transform;

      // [3,2] yozuvi — aynan perspektiva. U bo'lmasa "3D" tekis
      // qiyshaygan rasm bo'lib qoladi, chuqurlik hissi bo'lmaydi.
      expect(m.entry(3, 2), isNot(0.0),
          reason: 'perspektiva yo\'q — 3D hissi bo\'lmaydi');
      expect(m.entry(3, 2).abs(), lessThan(0.01),
          reason: 'perspektiva juda kuchli — xarita tanib bo\'lmas holga keladi');
    });

    testWidgets('X o\'qi bo\'yicha egilish bor (ekran ostiga)', (tester) async {
      await tester.pumpWidget(qur(1));
      await tester.pump();
      final m = tester
          .widget<Transform>(find.byType(Transform).first)
          .transform;
      // rotateX qo'llanganda [1,1] = cos(angle) < 1 bo'ladi.
      expect(m.entry(1, 1).abs(), lessThan(1.0),
          reason: 'xarita egilmagan');
      expect(m.entry(1, 1).abs(), greaterThan(0.3),
          reason: 'juda ko\'p egilgan — tile\'lar o\'qilmaydi');
    });
  });
}
