import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:gov_auction_app/features/chat/data/sources/chat_remote_data_source.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_state.dart';


final chatRemoteProvider = Provider((ref) {
  return ChatRemoteDataSource(ref.watch(dioClientProvider));
});

final chatRepositoryProvider = Provider((ref) {
  return ChatRepositoryImpl(remote: ref.watch(chatRemoteProvider));
});

final sendMessageUseCaseProvider = Provider((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final chatViewModelProvider =
    StateNotifierProvider<ChatViewModel, ChatState>((ref) {
  return ChatViewModel(ref.watch(sendMessageUseCaseProvider));
});

class ChatViewModel extends StateNotifier<ChatState> {
  final SendMessageUseCase _send;

  ChatViewModel(this._send)
      : super(
          const ChatState(
            messages: [],
          ),
        );

  Future<void> send(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updated = [...state.messages, userMsg];

    state = state.copyWith(
      isSending: true,
    );

    try {
      final history = updated
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final reply = await _send(text, history);

      state = state.copyWith(
        isSending: false,
        messages: [
          ...updated,
          ChatMessage(
            id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'AI service unavailable',
      );
    }
  }
    void clear() {
    state = const ChatState(
      messages: [],
    );
  }
}

