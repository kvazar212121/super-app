import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Asosiy ekrandagi katakchalar va yangi qo'shimcha xizmatlar bilan mos
/// keladigan barcha xizmat turlari.
enum ServiceHubKind {
  sartarosh,
  salon,
  futbol,
  ishchi,
  usta,
  elektrik,
  santexnik,
  // 5 ta yangi:
  tozalash,
  avtoYordam,
  konditsioner,
  enaga,
  repetitor,
  yana,
}

extension ServiceHubKindX on ServiceHubKind {
  String get title => switch (this) {
        ServiceHubKind.sartarosh => 'Sartarosh',
        ServiceHubKind.salon => 'Salon',
        ServiceHubKind.futbol => 'Futbol',
        ServiceHubKind.ishchi => 'Ishchi',
        ServiceHubKind.usta => 'Usta',
        ServiceHubKind.elektrik => 'Elektrik',
        ServiceHubKind.santexnik => 'Santexnik',
        ServiceHubKind.tozalash => 'Tozalash',
        ServiceHubKind.avtoYordam => 'Avto-yordam',
        ServiceHubKind.konditsioner => 'Konditsioner',
        ServiceHubKind.enaga => 'Enaga',
        ServiceHubKind.repetitor => 'Repetitor',
        ServiceHubKind.yana => 'Yana xizmatlar',
      };

  String get hubSubtitle => switch (this) {
        ServiceHubKind.sartarosh => 'Yaqin atrofdagi sartaroshlar va band qilish',
        ServiceHubKind.salon => 'Salonda vaqt bron qilish',
        ServiceHubKind.futbol => 'Futbol maydonini band qilish',
        ServiceHubKind.ishchi => 'Ishchi yollash va kunlik ishlar',
        ServiceHubKind.usta => 'Usta chaqirish va ta’mirlash',
        ServiceHubKind.elektrik => 'Elektr montaj va favqulodda chaqiruv',
        ServiceHubKind.santexnik => 'Santexnik va suv oqimi',
        ServiceHubKind.tozalash => 'Uy yoki ofis tozalash xizmati',
        ServiceHubKind.avtoYordam => 'Evakuator, akkumulyator, yo‘l yordami',
        ServiceHubKind.konditsioner => 'Konditsioner montaj va profilaktika',
        ServiceHubKind.enaga => 'Bola qarovchi va enaga',
        ServiceHubKind.repetitor => 'Repetitor va o‘qituvchi xizmati',
        ServiceHubKind.yana => 'Boshqa xizmatlar va yordam',
      };

  IconData get icon => switch (this) {
        ServiceHubKind.sartarosh => LucideIcons.scissors,
        ServiceHubKind.salon => LucideIcons.sparkles,
        ServiceHubKind.futbol => LucideIcons.trophy,
        ServiceHubKind.ishchi => LucideIcons.users,
        ServiceHubKind.usta => LucideIcons.wrench,
        ServiceHubKind.elektrik => LucideIcons.zap,
        ServiceHubKind.santexnik => LucideIcons.droplet,
        ServiceHubKind.tozalash => LucideIcons.sprayCan,
        ServiceHubKind.avtoYordam => LucideIcons.car,
        ServiceHubKind.konditsioner => LucideIcons.wind,
        ServiceHubKind.enaga => LucideIcons.baby,
        ServiceHubKind.repetitor => LucideIcons.bookOpen,
        ServiceHubKind.yana => LucideIcons.moreHorizontal,
      };

  Color get accent => switch (this) {
        ServiceHubKind.sartarosh => Colors.blue,
        ServiceHubKind.salon => Colors.pink,
        ServiceHubKind.futbol => Colors.green,
        ServiceHubKind.ishchi => Colors.orange,
        ServiceHubKind.usta => Colors.teal,
        ServiceHubKind.elektrik => const Color(0xFFD97706),
        ServiceHubKind.santexnik => Colors.lightBlue,
        ServiceHubKind.tozalash => Colors.cyan,
        ServiceHubKind.avtoYordam => Colors.deepOrange,
        ServiceHubKind.konditsioner => Colors.indigo,
        ServiceHubKind.enaga => Colors.purple,
        ServiceHubKind.repetitor => Colors.deepPurple,
        ServiceHubKind.yana => Colors.blueGrey,
      };

  /// Universal booking formasidagi variantlar (oststur).
  /// Birinchi qator — variant nomi, ikkinchisi — taxminiy minimal narx (so'm).
  List<({String label, double basePrice})> get variants => switch (this) {
        ServiceHubKind.sartarosh => const [
            (label: 'Erkaklar kesimi', basePrice: 50000),
            (label: 'Soqol olish', basePrice: 25000),
            (label: 'Bolalar kesimi', basePrice: 35000),
            (label: 'Styling', basePrice: 60000),
          ],
        ServiceHubKind.salon => const [
            (label: 'Manikyur', basePrice: 70000),
            (label: 'Pedikyur', basePrice: 90000),
            (label: 'Soch turmagi', basePrice: 80000),
            (label: 'Make-up', basePrice: 150000),
          ],
        ServiceHubKind.futbol => const [
            (label: '1 soat (kichik maydon)', basePrice: 200000),
            (label: '1 soat (katta maydon)', basePrice: 350000),
            (label: '2 soat (kichik maydon)', basePrice: 380000),
            (label: '2 soat (katta maydon)', basePrice: 650000),
          ],
        ServiceHubKind.ishchi => const [
            (label: 'Yuk ko‘taruvchi (1 kishi)', basePrice: 150000),
            (label: 'Yuk ko‘taruvchi (2 kishi)', basePrice: 280000),
            (label: 'Qora ish — 4 soat', basePrice: 200000),
            (label: 'Qora ish — kunlik', basePrice: 400000),
          ],
        ServiceHubKind.usta => const [
            (label: 'Mebel yig‘ish', basePrice: 150000),
            (label: 'Eshik/oyna ta’miri', basePrice: 120000),
            (label: 'Devorga osish/biriktirish', basePrice: 80000),
            (label: 'Boshqa ta’mirlash', basePrice: 100000),
          ],
        ServiceHubKind.elektrik => const [
            (label: 'Rozetka/lyustra montaj', basePrice: 100000),
            (label: 'Simlash', basePrice: 250000),
            (label: 'Shoshilinch chaqiruv', basePrice: 200000),
            (label: 'Uy elektr tekshiruvi', basePrice: 180000),
          ],
        ServiceHubKind.santexnik => const [
            (label: 'Smesitel almashtirish', basePrice: 120000),
            (label: 'Toshma/probka tozalash', basePrice: 150000),
            (label: 'Quvur ulash', basePrice: 200000),
            (label: 'Shoshilinch chaqiruv', basePrice: 250000),
          ],
        ServiceHubKind.tozalash => const [
            (label: '1 xonali kvartira', basePrice: 200000),
            (label: '2 xonali kvartira', basePrice: 320000),
            (label: '3 xonali kvartira', basePrice: 450000),
            (label: 'Ofis (50 m²)', basePrice: 400000),
          ],
        ServiceHubKind.avtoYordam => const [
            (label: 'Evakuator', basePrice: 250000),
            (label: 'Akkumulyator quvvatlash', basePrice: 80000),
            (label: 'Shinopo‘la (1 g‘ildirak)', basePrice: 70000),
            (label: 'Yo‘l ustasi', basePrice: 150000),
          ],
        ServiceHubKind.konditsioner => const [
            (label: 'Montaj', basePrice: 600000),
            (label: 'Demontaj', basePrice: 250000),
            (label: 'Profilaktika tozalash', basePrice: 180000),
            (label: 'Gaz to‘ldirish', basePrice: 350000),
          ],
        ServiceHubKind.enaga => const [
            (label: 'Soatlik (3 soat)', basePrice: 120000),
            (label: 'Yarim kun (5 soat)', basePrice: 200000),
            (label: 'To‘liq kun (10 soat)', basePrice: 380000),
            (label: 'Tunda (8 soat)', basePrice: 350000),
          ],
        ServiceHubKind.repetitor => const [
            (label: 'Matematika (1 dars)', basePrice: 120000),
            (label: 'Ingliz tili (1 dars)', basePrice: 100000),
            (label: 'Fizika (1 dars)', basePrice: 130000),
            (label: 'Test tayyorlov (1 dars)', basePrice: 150000),
          ],
        ServiceHubKind.yana => const [
            (label: 'Boshqa xizmat', basePrice: 100000),
          ],
      };
}
