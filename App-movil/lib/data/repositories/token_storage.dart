// Interfaz del almacén del token de sesión.

/// Guarda, lee y borra el token de sesión.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}
