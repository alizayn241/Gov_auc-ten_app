import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repo;
  SendMessageUseCase(this.repo);

  Future<String> call(
    String message,
    List<Map<String, String>> history,
  ) {
    return repo.sendMessage(message);
  }
}
