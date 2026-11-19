// Token de sesión guardado en memoria para los tests.

import 'package:sysmote/data/repositories/token_storage.dart';

/// [TokenStorage] que guarda en una variable en vez de en el Keystore.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
