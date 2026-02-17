import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/ai/claude_provider.dart';
import 'package:vero/core/ai/gemini_provider.dart';
import 'package:vero/core/ai/ollama_provider.dart';
import 'package:vero/core/ai/openai_provider.dart';
import 'package:vero/shared/constants.dart';

/// Builds and caches the currently configured [AssistantProvider].
/// Re-reads from secure storage when called.
class ProviderRegistry {
  ProviderRegistry._();

  static const _storage = FlutterSecureStorage();

  /// Returns the currently selected [AssistantProvider], fully configured.
  /// Returns null if no provider is configured (first run).
  static Future<AssistantProvider?> currentProvider() async {
    final providerId = await _storage.read(key: VeroConstants.kProviderKey);

    switch (providerId) {
      case VeroConstants.kProviderClaude:
        final key = await _storage.read(key: VeroConstants.kClaudeApiKey);
        if (key == null || key.isEmpty) return null;
        return ClaudeProvider(apiKey: key);

      case VeroConstants.kProviderOpenAi:
        final key = await _storage.read(key: VeroConstants.kOpenAiApiKey);
        if (key == null || key.isEmpty) return null;
        return OpenAIProvider(apiKey: key);

      case VeroConstants.kProviderGemini:
        final key = await _storage.read(key: VeroConstants.kGeminiApiKey);
        if (key == null || key.isEmpty) return null;
        return GeminiProvider(apiKey: key);

      case VeroConstants.kProviderOllama:
        final url = await _storage.read(key: VeroConstants.kOllamaBaseUrl);
        final model = await _storage.read(key: VeroConstants.kOllamaModel);
        return OllamaProvider(
          baseUrl: url,
          modelId: model,
        );

      default:
        return null;
    }
  }

  /// All supported provider IDs and their display names.
  static const Map<String, String> providerDisplayNames = {
    VeroConstants.kProviderClaude: 'Claude (Anthropic)',
    VeroConstants.kProviderOpenAi: 'GPT (OpenAI)',
    VeroConstants.kProviderGemini: 'Gemini (Google)',
    VeroConstants.kProviderOllama: 'Ollama (local)',
  };
}

/// Riverpod provider for the active [AssistantProvider].
final assistantProviderPod = FutureProvider<AssistantProvider?>((ref) {
  return ProviderRegistry.currentProvider();
});
