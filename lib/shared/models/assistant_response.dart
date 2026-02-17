import 'dart:convert';
import 'package:equatable/equatable.dart';

/// The structured response returned by the AssistantBrain after processing
/// a user message. Phase 1 only uses [speech] and [rawText].
/// Phase 2 adds [skillId] and [skillArgs].
class AssistantResponse extends Equatable {
  /// What TTS speaks aloud — short, conversational.
  final String speech;

  /// Skill to execute (null in Phase 1, populated in Phase 2+).
  final String? skillId;

  /// Arguments for the skill (null in Phase 1).
  final Map<String, dynamic>? skillArgs;

  /// Full raw text from the LLM (used for chat UI display).
  final String rawText;

  const AssistantResponse({
    required this.speech,
    required this.rawText,
    this.skillId,
    this.skillArgs,
  });

  /// Parse a structured JSON response from the LLM.
  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      speech: json['speech'] as String? ?? 'Sorry, I had trouble with that.',
      skillId: json['skill'] as String?,
      skillArgs: json['args'] as Map<String, dynamic>?,
      rawText: jsonEncode(json),
    );
  }

  /// Fallback when JSON parsing fails — treat the raw text as speech.
  factory AssistantResponse.fromRawText(String text) {
    return AssistantResponse(
      speech: text,
      rawText: text,
    );
  }

  @override
  List<Object?> get props => [speech, skillId, skillArgs, rawText];
}
