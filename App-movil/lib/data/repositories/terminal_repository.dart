abstract class TerminalRepository {
  Stream<String> get output;
  void send(String data);
}
