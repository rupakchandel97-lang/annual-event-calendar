import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _themeId = AppTheme.guestThemeId;

  String get themeId => _themeId;
  AppThemePalette get activeTheme => AppTheme.paletteFor(_themeId);

  void syncWithUserTheme(String? userThemeId) {
    final resolvedThemeId = userThemeId ?? AppTheme.guestThemeId;
    if (_themeId == resolvedThemeId) {
      return;
    }

    _themeId = resolvedThemeId;
    notifyListeners();
  }

  void setTheme(String themeId) {
    if (_themeId == themeId) {
      return;
    }

    _themeId = themeId;
    notifyListeners();
  }
}
