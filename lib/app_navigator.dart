import 'package:flutter/widgets.dart';

/// Global navigator key — istalgan joydan (qo'ng'iroq ekrani, kelishuv
/// dialoglari, budilnik) navigatsiya/dialog ochish uchun.
///
/// Alohida faylda turadi, chunki uni ham `main.dart`, ham widget fayllar
/// (masalan `call_screen.dart`) ishlatadi — `main.dart`ni import qilib
/// aylanma (circular) bog'liqlik yaratmaslik uchun.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
