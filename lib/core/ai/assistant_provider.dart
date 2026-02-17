import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

/// Abstract contract every AI provider must implement.
/// Adding a new provider = implement this interface, register it.
abstract class AssistantProvider {
  /// Human-readable name, shown in settings UI.
  String get name;

  /// The model identifier sent to the API.
  String get modelId;

  /// Single-shot request — returns a complete [AssistantResponse].
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  });

  /// Streaming request — yields text chunks for real-time UI updates.
  /// Providers that don't support streaming may yield a single chunk.
  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  });
}
