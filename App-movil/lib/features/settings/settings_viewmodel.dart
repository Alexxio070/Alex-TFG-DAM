import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _dark = false;
  Color _accent = kAccentColors.first;

  bool get dark => _dark;
  Color get accent => _accent;

  void setDark(bool value) => _update(() => _dark = value);
  void setAccent(Color value) => _update(() => _accent = value);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
