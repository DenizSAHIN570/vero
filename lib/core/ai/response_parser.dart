import 'dart:convert';

import 'package:vero/shared/models/assistant_response.dart';

/// Robustly parses LLM text output into an [AssistantResponse].
///
/// Strategy (in order):
/// 1. Direct JSON parse — ideal happy path.
/// 2. Regex extraction — handles LLMs that wrap JSON in ```json ... ``` fences
///    or add prose before/after the JSON block.
/// 3. Raw text fallback — speak the raw response rather than crashing.
class ResponseParser {
  ResponseParser._();

  /// Top-level entry point used by all providers.
  static AssistantResponse parse(String rawText) {
    // 1. Try direct parse
    final direct = _tryDirect(rawText.trim());
    if (direct != null) return direct;

    // 2. Try extracting from markdown fences
    final fenced = _tryFenced(rawText);
    if (fenced != null) return fenced;

    // 3. Try regex scan for first { ... } block
    final scanned = _tryScan(rawText);
    if (scanned != null) return scanned;

    // 4. Last resort: speak raw text
    return AssistantResponse.fromRawText(_sanitizeRawText(rawText));
  }

  static AssistantResponse? _tryDirect(String text) {
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return AssistantResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static AssistantResponse? _tryFenced(String text) {
    // Matches ```json ... ``` or ``` ... ```
    final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = fenceRegex.firstMatch(text);
    if (match != null) {
      return _tryDirect(match.group(1)!.trim());
    }
    return null;
  }

  static AssistantResponse? _tryScan(String text) {
    // Find the outermost { ... } block
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return _tryDirect(text.substring(start, end + 1));
    }
    return null;
  }

  /// Strip markdown, extra whitespace from raw fallback text.
  static String _sanitizeRawText(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
