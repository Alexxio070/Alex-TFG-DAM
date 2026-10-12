import 'package:flutter/foundation.dart';

import '../repositories/pairing_repository.dart';

class FakePairingRepository implements PairingRepository {
  final _paired = ValueNotifier<bool>(true);

  @override
  ValueListenable<bool> get paired => _paired;
}
