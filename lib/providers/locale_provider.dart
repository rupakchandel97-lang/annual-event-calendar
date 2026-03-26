import 'dart:ui';

import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  static const supportedLanguageCodes = ['en', 'es', 'hi'];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  void syncWithUserLanguage(String? languageCode) {
    final next = _normalize(languageCode);
    if (next == _locale.languageCode) {
      return;
    }
    _locale = Locale(next);
    notifyListeners();
  }

  void setLanguageCode(String languageCode) {
    final next = _normalize(languageCode);
    if (next == _locale.languageCode) {
      return;
    }
    _locale = Locale(next);
    notifyListeners();
  }

  String _normalize(String? value) {
    if (value == null || !supportedLanguageCodes.contains(value)) {
      return 'en';
    }
    return value;
  }
}
