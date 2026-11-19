// ViewModel de navegación entre secciones.

import 'package:flutter/foundation.dart';

import '../auth/auth_viewmodel.dart';

/// Secciones de la app con su nombre visible.
enum Section {
  home('Inicio'),
  metrics('Métricas'),
  terminal('Terminal'),
  notes('Notas'),
  settings('Ajustes');

  const Section(this.label);
  final String label;
}

/// Sección activa.
class ShellViewModel extends ChangeNotifier {
  ShellViewModel(this._auth) {
    _auth.addListener(notifyListeners);
  }

  final AuthViewModel _auth;
  Section _active = Section.home;

  Section get active => _active;
  bool get isPaired => _auth.stage == AuthStage.loggedIn;

  /// Cambia a [section].
  void select(Section section) {
    _active = section;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(notifyListeners);
    super.dispose();
  }
}
