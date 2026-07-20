import 'package:flutter/widgets.dart';

/// Global navigator key — istalgan joydan (qo'ng'iroq ekrani, kelishuv
/// dialoglari, budilnik) navigatsiya/dialog ochish uchun.
///
/// Alohida faylda turadi, chunki uni ham `main.dart`, ham widget fayllar
/// (masalan `call_screen.dart`) ishlatadi — `main.dart`ni import qilib
/// aylanma (circular) bog'liqlik yaratmaslik uchun.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Ilova ildizi (RootShell) tayyor bo'ldimi.
///
/// SOVUQ START muammosi: ilova YOPIQ turib qo'ng'iroq ko'tarilsa, app splash'dan
/// boshlanadi. Agar CallScreen'ni splash ustiga push qilsak — splash keyin
/// RootShell'ga `pushReplacement` qilганда CallScreen o'chib ketadi (gaplashuv
/// oynasi yo'qoladi). Shuning uchun RootShell tayyor bo'lguncha kutamiz.
bool appReady = false;

/// RootShell tayyor bo'lganda chaqiriladi (main.dart o'rnatadi) — kutilayotgan
/// qo'ng'iroq ekranini ko'rsatish uchun.
void Function()? onAppReady;
