import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vero/core/ai/provider_registry.dart';
import 'package:vero/core/assistant_brain.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/models/message.dart';

/// Possible states the chat UI can be in.
enum ChatStatus {
  idle,
  listening,   // STT active
  thinking,    // waiting for LLM response
  speaking,    // TTS active
  error,
}

/// The immutable state object for the chat screen.
class ChatState {
  final List<Message> messages;
  final ChatStatus status;
  final String? errorMessage;
  final bool hasProvider; // false = no API key configured yet

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.errorMessage,
    this.hasProvider = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    ChatStatus? status,
    String? errorMessage,
    bool? hasProvider,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage,
      hasProvider: hasProvider ?? this.hasProvider,
    );
  }
}

/// Notifier that owns chat state and orchestrates AssistantBrain.
class ChatNotifier extends AsyncNotifier<ChatState> {
  AssistantBrain? _brain;
  static const _storage = FlutterSecureStorage();

  @override
  Future<ChatState> build() async {
    await _initBrain();
    return ChatState(hasProvider: _brain != null);
  }

  Future<void> _initBrain() async {
    final provider = await ProviderRegistry.currentProvider();
    if (provider != null) {
      _brain = AssistantBrain(provider: provider);
    }
  }

  /// Re-initialise after settings change (new API key / provider swap).
  Future<void> reinitialize() async {
    state = const AsyncValue.loading();
    await _initBrain();
    state = AsyncValue.data(ChatState(hasProvider: _brain != null));
  }

  /// Send a text message through the brain.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final current = state.value ?? const ChatState();

    if (_brain == null) {
      state = AsyncValue.data(current.copyWith(
        status: ChatStatus.error,
        errorMessage: 'No AI provider configured. Go to Settings to add an API key.',
      ));
      return;
    }

    // Optimistically add user message to UI
    final userMsg = Message.user(text);
    state = AsyncValue.data(current.copyWith(
      messages: [...current.messages, userMsg],
      status: ChatStatus.thinking,
      errorMessage: null,
    ));

    try {
      final response = await _brain!.process(text);

      final assistantMsg = Message.assistant(response.speech);
      final updated = state.value!;
      state = AsyncValue.data(updated.copyWith(
        messages: [...updated.messages, assistantMsg],
        status: ChatStatus.speaking,
      ));

      // TTS speaks asynchronously; mark idle after a short buffer
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data(state.value!.copyWith(status: ChatStatus.idle));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        status: ChatStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  void clearConversation() {
    _brain?.clearHistory();
    final current = state.value ?? const ChatState();
    state = AsyncValue.data(current.copyWith(messages: [], errorMessage: null));
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('authentication')) {
      return 'Invalid API key. Please check your settings.';
    }
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Network error. Check your internet connection.';
    }
    if (msg.contains('429')) {
      return 'Rate limit hit. Please wait a moment.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
