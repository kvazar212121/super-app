import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// Xarita tile provayderi sozlamalari — BITTA joyda.
///
/// Nega markaziy: ilovada 6 ta xarita ekrani bor. Ilgari har birida tile
/// manzili qo'lda yozilgan edi, shu sababli provayderni almashtirish uchun
/// 6 joyni tahrirlash kerak bo'lardi (va bittasini unutish oson edi).
///
/// ⚠️ MUHIM — tile serverlari haqida:
///   `tile.openstreetmap.org` va CartoDB'ning ochiq serveri OMMAVIY
///   ilovalarda ishlatilishi TAQIQLANGAN (OSM Tile Usage Policy). Ular
///   demo/o'rganish uchun. Foydalanuvchi ko'paysa so'rovlar bloklanadi va
///   xarita oq bo'lib qoladi.
///
///   Shuning uchun o'z kalitingiz bilan ishlaydigan provayder kerak.
///   Standart holatda MapTiler ishlatiladi (oyiga 100 000 so'rov bepul).
///
/// Kalitni build paytida beriladi (kodga yozilmaydi):
///   flutter build apk --dart-define=MAPTILER_KEY=sizning_kalitingiz
class MapConfig {
  MapConfig._();

  /// MapTiler kaliti. Build paytida `--dart-define=MAPTILER_KEY=...` orqali
  /// beriladi. Bo'sh bo'lsa — zaxira (OSM) ishlatiladi va ogohlantirish
  /// chiqadi.
  static const String maptilerKey = String.fromEnvironment('MAPTILER_KEY');

  /// Kalit sozlanganmi.
  static bool get hasKey => maptilerKey.isNotEmpty;

  /// MapTiler uslubi.
  ///
  /// `streets-v4` — eng yangi avlod: 160 qatlam (v2 da 90 ta),
  /// binolar balandligi `height` maydonidan olinadi va 3D
  /// ko'rinishda ancha aniq chiqadi. Vektor rejimda aynan shu
  /// style 3D binolarni beradi.
  static const String style = 'streets-v4';

  /// Qorong'i rejim uslubi.
  static const String darkStyle = 'streets-v4-dark';

  /// Ilova identifikatori — tile serverlari uchun (User-Agent).
  static const String userAgent = 'uz.hubservis.app';

  /// Asosiy tile manzili.
  ///
  /// [dark] — qorong'i uslub kerak bo'lsa.
  static String tileUrl({bool dark = false}) => tileUrlFor(maptilerKey, dark: dark);

  /// [tileUrl] ning sof (toza) ko'rinishi — kalit tashqaridan beriladi.
  ///
  /// Nega alohida: `maptilerKey` compile-time konstanta, ya'ni testda uni
  /// o'zgartirib bo'lmaydi. Shu sababli kalitli tarmoq faqat haqiqiy
  /// relizda ishga tushardi va test bilan qoplanmagan edi. Endi ikkala
  /// holat ham sinaladi.
  static String tileUrlFor(String key, {bool dark = false}) {
    if (key.isNotEmpty) {
      final s = dark ? darkStyle : style;
      return 'https://api.maptiler.com/maps/$s/{z}/{x}/{y}.png?key=$key';
    }
    // Kalit yo'q (dev/debug): OSM. Production'da ishlatilmasin.
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// VEKTOR style manzili — HAQIQIY 3D uchun.
  ///
  /// Farqi: `tileUrl` rasm (raster) beradi, uni faqat qiyshaytirish
  /// mumkin — bu soxta 3D. Vektor style esa binolar balandligini
  /// (`fill-extrusion`) o'z ichiga oladi, shuning uchun kamera
  /// egilganda binolar CHINAKAM ko'tariladi, xuddi Yandex/Google
  /// xaritalaridagidek.
  ///
  /// MapTiler `streets-v2` style'ida "Building 3D" qatlami bor.
  static String styleUrl({bool dark = false}) {
    if (hasKey) {
      final s = dark ? darkStyle : style;
      return 'https://api.maptiler.com/maps/$s/style.json?key=$maptilerKey';
    }
    // Kalitsiz vektor xarita yo'q — chaqiruvchi 3D ni o'chirishi kerak.
    return '';
  }

  /// 3D ko'rinish mumkinmi (vektor style uchun kalit kerak).
  static bool get supports3D => hasKey;

  /// Asosiy manzil ishlamasa ishlatiladigan zaxira.
  static String get fallbackUrl =>
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Tile'ning maksimal masshtabi.
  static const int maxZoom = 19;

  /// Tayyor [TileLayer] — barcha ekranlar shuni ishlatadi.
  static TileLayer tileLayer({bool dark = false}) {
    return TileLayer(
      urlTemplate: tileUrl(dark: dark),
      fallbackUrl: fallbackUrl,
      userAgentPackageName: userAgent,
      maxNativeZoom: maxZoom,
      // Tile so'rovlarini kamaytiradi: ekrandan chiqqan bo'laklar darrov
      // o'chirilmaydi, foydalanuvchi qaytsa qayta so'ralmaydi.
      keepBuffer: 3,
      panBuffer: 1,
    );
  }

  /// Xarita ma'lumoti manbasi — LITSENZIYA TALABI.
  ///
  /// OpenStreetMap (ODbL) va MapTiler shartlariga ko'ra manba ko'rsatilishi
  /// SHART. Buni tashlab ketish litsenziya buzilishi hisoblanadi.
  ///
  /// [bottomInset] — pastdagi tugmalar balandligi. Atribut ular ostida
  /// qolib ketmasligi uchun shu qadar tepaga suriladi.
  static Widget attribution({double bottomInset = 0}) {
    // Chapda: o'ngdagi "meni ko'rsat"/"kengaytirish" tugmalari bilan
    // ustma-ust tushmasligi uchun.
    final w = RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        if (hasKey)
          TextSourceAttribution(
            'MapTiler',
            onTap: () => launchUrl(
              Uri.parse('https://www.maptiler.com/copyright/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        TextSourceAttribution(
          'OpenStreetMap',
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
    if (bottomInset <= 0) return w;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: w,
    );
  }
}
