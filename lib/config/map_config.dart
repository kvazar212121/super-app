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

  /// MapTiler uslubi. `streets-v2` — ko'chalar, do'konlar ko'rinadigan
  /// klassik uslub. Boshqa variantlar: `basic-v2`, `bright-v2`, `outdoor-v2`.
  static const String style = 'streets-v2';

  /// Qorong'i rejim uslubi.
  static const String darkStyle = 'streets-v2-dark';

  /// Ilova identifikatori — tile serverlari uchun (User-Agent).
  static const String userAgent = 'uz.hubservis.app';

  /// Asosiy tile manzili.
  ///
  /// [dark] — qorong'i uslub kerak bo'lsa.
  static String tileUrl({bool dark = false}) {
    if (hasKey) {
      final s = dark ? darkStyle : style;
      return 'https://api.maptiler.com/maps/$s/{z}/{x}/{y}.png?key=$maptilerKey';
    }
    // Kalit yo'q (dev/debug): OSM. Production'da ishlatilmasin.
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

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
