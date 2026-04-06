import '../../domain/repositories/chat_repository.dart';
import '../sources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl({required this.remote});

  @override
  Future<String> sendMessage(String message) {
    return remote.sendMessage(message, []);
  }
}
