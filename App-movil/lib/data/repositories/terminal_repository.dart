// Interfaz de una sesión de terminal remota.

/// Una sesión de terminal: se crea, se le mandan teclas y devuelve la salida. Hay una instancia por
/// pestaña.
abstract class TerminalRepository {
  /// Texto que escribe la sesión.
  Stream<String> get output;

  /// Avisa cuando la sesión termina sola (`exit`, Ctrl+D).
  Stream<void> get sessionEnded;
  Future<void> createSession();
  void send(String data);
  Future<void> close();
}
