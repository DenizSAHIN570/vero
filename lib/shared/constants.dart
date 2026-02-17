/// App-wide constants for Vero.
class VeroConstants {
  VeroConstants._();

  // Secure storage keys
  static const String kProviderKey = 'selected_provider';
  static const String kClaudeApiKey = 'claude_api_key';
  static const String kOpenAiApiKey = 'openai_api_key';
  static const String kGeminiApiKey = 'gemini_api_key';
  static const String kOllamaBaseUrl = 'ollama_base_url';
  static const String kOllamaModel = 'ollama_model';

  // Default model IDs
  static const String kDefaultClaudeModel = 'claude-sonnet-4-5-20250929';
  static const String kDefaultOpenAiModel = 'gpt-4o';
  static const String kDefaultGeminiModel = 'gemini-1.5-pro';
  static const String kDefaultOllamaModel = 'llama3';
  static const String kDefaultOllamaUrl = 'http://localhost:11434';

  // Provider IDs (used as keys in registry)
  static const String kProviderClaude = 'claude';
  static const String kProviderOpenAi = 'openai';
  static const String kProviderGemini = 'gemini';
  static const String kProviderOllama = 'ollama';

  // Max conversation history messages to send (rolling window)
  static const int kMaxHistoryMessages = 20;

  // TTS defaults
  static const double kDefaultSpeechRate = 0.5;
  static const double kDefaultTtsPitch = 1.0;
  static const double kDefaultTtsVolume = 1.0;
}
