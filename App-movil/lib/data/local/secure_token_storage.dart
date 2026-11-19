// Guarda el token de sesión cifrado en el móvil (Android Keystore).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../repositories/token_storage.dart';

const _key = 'session_token';

/// [TokenStorage] sobre `flutter_secure_storage`.
class SecureTokenStorage implements TokenStorage {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
