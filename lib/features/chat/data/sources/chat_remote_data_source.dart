import '../../../../core/network/dio_client.dart';

class ChatRemoteDataSource {
  final DioClient _client;
  ChatRemoteDataSource(this._client);

  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    final res = await _client.dio.post(
  '/chat',
  data: {
    'message': message,
    'history': history,
  },
);

    return res.data['reply'] as String;
  }
}
