import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'translations.dart';

/// Ilova tili boshqaruvchisi (uz | ru). Tanlov saqlanadi va o'zgarganда
/// butun ilova qayta chiziladi (barcha `.tr` yangilanadi).
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  String _lang = 'uz';
  String get lang => _lang;
  Locale get locale => Locale(_lang);
  bool get isRu => _lang == 'ru';

  static const _prefsKey = 'app_lang';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'ru' || saved == 'uz') _lang = saved!;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    if (lang != 'ru' && lang != 'uz') return;
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, lang);
    } catch (_) {}
  }

  /// O'zbekcha matnни joriy tilга tarjima qiladi (topilmasa o'zbekchani qaytaradi).
  String translate(String uz) {
    if (_lang == 'uz') return uz;
    return kTranslationsRu[uz] ?? uz;
  }
}

/// `'Salom'.tr` — joriy tilga tarjima. Butun ilova locale o'zgarganда qayta chiziladi.
extension TrExtension on String {
  String get tr => LocaleController.instance.translate(this);
}
