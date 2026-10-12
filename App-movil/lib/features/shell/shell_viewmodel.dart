import 'package:flutter/foundation.dart';

import '../../data/repositories/pairing_repository.dart';

enum Section {
  home('Inicio'),
  metrics('Métricas'),
  terminal('Terminal'),
  notes('Notas'),
  settings('Ajustes');

  const Section(this.label);
  final String label;
}

class ShellViewModel extends ChangeNotifier {
  ShellViewModel(this._pairing) {
    _pairing.paired.addListener(notifyListeners);
  }

  final PairingRepository _pairing;
  Section _active = Section.home;

  Section get active => _active;
  bool get isPaired => _pairing.paired.value;

  void select(Section section) {
    _active = section;
    notifyListeners();
  }

  @override
  void dispose() {
    _pairing.paired.removeListener(notifyListeners);
    super.dispose();
  }
}
