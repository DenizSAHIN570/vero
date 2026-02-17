import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/speech/tts_service.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

/// The central orchestrator for Vero.
///
/// Phase 1: processes text input → LLM → TTS.
/// Phase 2: will also route to the SkillRegistry for device actions.
class AssistantBrain {
  final AssistantProvider provider;
  final TtsService _tts;
  final List<Message> _history = [];

  AssistantBrain({
    required this.provider,
    TtsService? tts,
  }) : _tts = tts ?? TtsService.instance;

  /// Process a user utterance through the full pipeline:
  /// 1. Append to history
  /// 2. Call AI provider
  /// 3. Append response to history
  /// 4. Speak the response via TTS
  /// 5. Return the [AssistantResponse] for UI consumption
  Future<AssistantResponse> process(String userInput) async {
    _history.add(Message.user(userInput));

    final systemPrompt = _buildSystemPrompt();

    // Use a rolling window to avoid context overflow
    final windowedHistory = _rolledHistory();

    final response = await provider.send(
      history: windowedHistory,
      systemPrompt: systemPrompt,
    );

    _history.add(Message.assistant(response.rawText));

    // Phase 2: skill execution will go here
    // if (response.skillId != null) { ... }

    await _tts.speak(response.speech);

    return response;
  }

  /// Returns the last N messages to avoid context overflow.
  List<Message> _rolledHistory() {
    final max = VeroConstants.kMaxHistoryMessages;
    if (_history.length <= max) return List.unmodifiable(_history);
    return List.unmodifiable(_history.sublist(_history.length - max));
  }

  String _buildSystemPrompt() => '''
You are Vero, a helpful and concise voice assistant running on Android.

Always respond with a valid JSON object using exactly this schema:
{
  "speech": "what you say out loud (keep it short and conversational, 1–2 sentences max)",
  "skill": null,
  "args": null
}

Guidelines:
- Keep "speech" natural and brief — this is spoken aloud, not displayed as text
- Do not use markdown, lists, or special formatting in "speech"
- For now, always set "skill" and "args" to null
- Never include any text outside the JSON object
- Always return valid, parseable JSON
''';

  /// Clear conversation history (e.g., user taps "New conversation").
  void clearHistory() => _history.clear();

  /// Read-only view of history for the chat UI.
  List<Message> get history => List.unmodifiable(_history);

  int get messageCount => _history.length;
}
