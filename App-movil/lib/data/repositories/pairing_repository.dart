import 'package:flutter/foundation.dart';

abstract class PairingRepository {
  ValueListenable<bool> get paired;
  Future<void> pair();
  Future<void> unpair();
}
