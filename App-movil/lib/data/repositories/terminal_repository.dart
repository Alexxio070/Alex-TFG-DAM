abstract class TerminalRepository {
  Stream<String> get output;
  Stream<void> get sessionEnded;
  Future<void> createSession();
  void send(String data);
  Future<void> close();
}
