# Vero

**Open source, LLM-pluggable, voice-activated Android assistant**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-8.0%2B-green?logo=android)](https://developer.android.com)

Vero is an open-source Android assistant built with Flutter. Unlike closed assistants, Vero lets you plug in any LLM backend — Claude, GPT-4, Gemini, or a local Ollama model — with no data leaving your device except to the provider you choose.

---

## Features (Phase 1 — AI Core)

- ✅ Conversational AI via Claude, GPT-4, Gemini, or local Ollama
- ✅ Text-to-speech spoken responses
- ✅ Full conversation history with rolling window
- ✅ API keys stored locally with Android Keystore encryption
- ✅ Clean dark UI with message bubbles

## Roadmap

| Phase | Description | Status |
|---|---|---|
| 1 | AI Core — LLM chat + TTS | ✅ Complete |
| 2 | Device Control — volume, brightness, DND, STT | 🔜 Next |
| 3 | Wake Word — always-on Picovoice detection | 🔜 Planned |
| 4 | App Launching + Public release | 🔜 Planned |

---

## Getting Started

### Prerequisites

- Flutter 3.x SDK
- Android Studio (or VS Code with Flutter extension)
- An API key for at least one provider (Claude, OpenAI, or Gemini), or a local Ollama installation

### Setup

```bash
git clone https://github.com/your-org/vero.git
cd vero
flutter pub get
flutter run
```

### First Run

1. Tap the settings icon (⚙️) in the top right.
2. Select your AI provider and enter your API key.
3. Tap **Save**.
4. Type a message and Vero will respond in text and speech.

---

## Architecture

```
User types/speaks
        │
        ▼
AssistantBrain          ← orchestrates everything
  ├─ Sends history + system prompt to provider
  ├─ Parses structured JSON response (with robust fallback)
  └─ Speaks response via TTS

AssistantProvider       ← pluggable AI backend
  ├─ ClaudeProvider     (Anthropic)
  ├─ OpenAIProvider     (OpenAI)
  ├─ GeminiProvider     (Google)
  └─ OllamaProvider     (local)
```

See [VERO_MASTER.md](VERO_MASTER.md) for the full architecture and design decisions.

---

## Contributing

- **New provider?** See [docs/PROVIDER_GUIDE.md](docs/PROVIDER_GUIDE.md)
- **New skill?** See [docs/SKILL_GUIDE.md](docs/SKILL_GUIDE.md) (Phase 2+)
- **Issues & features:** Open a GitHub issue

## License

Apache 2.0 — see [LICENSE](LICENSE)
