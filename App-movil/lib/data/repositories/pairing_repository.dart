import 'package:flutter/foundation.dart';

abstract class PairingRepository {
  ValueListenable<bool> get paired;
}
