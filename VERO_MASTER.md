# Vero — Open Source AI-Powered Android Assistant
### Master Project Document

> A modular, voice-activated Android assistant built with Flutter, powered by any LLM (Claude, GPT, Gemini, and more), with deep device integration and an open skill system.

---

## Table of Contents

1. [Vision & Goals](#1-vision--goals)
2. [Why This Doesn't Exist Yet](#2-why-this-doesnt-exist-yet)
3. [Tech Stack](#3-tech-stack)
4. [Architecture](#4-architecture)
5. [Folder Structure](#5-folder-structure)
6. [Core Systems](#6-core-systems)
   - [AI Provider Layer](#61-ai-provider-layer)
   - [Skill System](#62-skill-system)
   - [Speech Pipeline](#63-speech-pipeline)
   - [Native Bridge (Kotlin)](#64-native-bridge-kotlin)
   - [Assistant Brain](#65-assistant-brain)
7. [Android Permissions & Requirements](#7-android-permissions--requirements)
8. [The System Prompt Strategy](#8-the-system-prompt-strategy)
9. [MVP Roadmap](#9-mvp-roadmap)
10. [Known Limitations & Challenges](#10-known-limitations--challenges)
11. [Open Source Strategy](#11-open-source-strategy)
12. [Future Features (Post-MVP)](#12-future-features-post-mvp)

---

## 1. Vision & Goals

Vero is a **fully open source, privacy-respecting, LLM-powered voice assistant for Android**. Unlike Google Assistant or Alexa, Vero is:

- **Pluggable** — users choose their own AI backend (Claude, GPT-4, Gemini, local models, etc.)
- **Open** — every skill, every provider, every native bridge is transparent and community-extensible
- **Capable** — real device control, wake word detection, app launching, and natural conversation
- **Private** — no data sent anywhere except to the AI provider the user explicitly configures

### Core Capabilities (MVP)

- Wake word detection (always-on, low power)
- Natural language voice input via speech-to-text
- LLM-powered response and command parsing
- Device control: volume, brightness, Do Not Disturb
- Launch and interact with third-party apps via Intents
- Text-to-speech response output
- Persistent background service
- Settings UI for provider config and API keys

---

## 2. Why This Doesn't Exist Yet

| Project | Gap |
|---|---|
| **Dicio** | Open source Android assistant, but uses weak local NLU — no LLM integration |
| **Mycroft / OVOS** | Fully open, LLM-pluggable, but Linux/smart speaker focused — Android app never matured |
| **Leon AI** | Open source but server/desktop only, no native Android device control |
| **Replika / Character.ai** | LLM-powered but zero device control, purely conversational |
| **Perplexity Assistant** | Closest commercial rival, but closed source and not pluggable |
| **Alexa on Android** | Has device control and skills, but closed, tied to Amazon |

**The gap:** No mature, open source, Flutter-based, LLM-pluggable Android assistant with real device control exists. Vero fills it.

---

## 3. Tech Stack

### Flutter / Dart Layer

| Role | Package |
|---|---|
| Speech to text | `speech_to_text` |
| Text to speech | `flutter_tts` |
| Wake word | `picovoice_flutter` (Porcupine SDK) |
| Background service | `flutter_background_service` |
| Screen brightness | `screen_brightness` |
| Volume control | `volume_controller` |
| Launch apps / intents | `android_intent_plus` + `url_launcher` |
| HTTP / API calls | `dio` |
| Local storage (API keys, settings) | `flutter_secure_storage` |
| State management | `riverpod` |
| Permissions | `permission_handler` |
| Notifications | `flutter_local_notifications` |

### Native Android Layer (Kotlin)

| Role | Approach |
|---|---|
| Persistent background | `ForegroundService` with ongoing notification |
| Device control bridge | `MethodChannel` → `AudioManager`, `Settings.System` |
| Wake word detection | Picovoice native SDK via Flutter plugin |
| Accessibility service | Custom `AccessibilityService` subclass (optional, for advanced control) |
| App launching | `Intent` + `PackageManager` |
| Battery optimization bypass | Guided user flow to whitelist app |

### AI Providers (Pluggable)

| Provider | API |
|---|---|
| **Anthropic Claude** | `api.anthropic.com/v1/messages` |
| **OpenAI GPT** | `api.openai.com/v1/chat/completions` |
| **Google Gemini** | `generativelanguage.googleapis.com` |
| **Ollama (local)** | `localhost:11434/api/chat` (self-hosted) |
| **Custom / OpenAI-compatible** | User-supplied base URL |

### Dev Tooling

- **Language:** Dart (Flutter) + Kotlin
- **Min SDK:** Android 8.0 (API 26)
- **Target SDK:** Android 14 (API 34)
- **Build:** Gradle + Flutter CLI
- **CI:** GitHub Actions
- **Linting:** `flutter_lints`, `dart analyze`

---

## 4. Architecture

### High-Level Flow

```
User speaks
     │
     ▼
┌─────────────────────────┐
│   Wake Word Detection   │  ← Picovoice Porcupine (always-on, ~1% CPU)
│   (ForegroundService)   │
└────────────┬────────────┘
             │ wake word detected
             ▼
┌─────────────────────────┐
│   Speech-to-Text (STT)  │  ← Android SpeechRecognizer or Whisper
└────────────┬────────────┘
             │ transcript string
             ▼
┌─────────────────────────┐
│    AssistantBrain       │  ← orchestrates everything
│  - injects system prompt│
│  - manages history      │
│  - calls AI provider    │
└────────────┬────────────┘
             │ AssistantResponse (speech + optional skill)
             ▼
     ┌───────┴────────┐
     │                │
     ▼                ▼
┌─────────┐    ┌─────────────┐
│   TTS   │    │ Skill Router│  ← executes device command
│ speaks  │    │             │
│response │    │ VolumeSkill │
└─────────┘    │ BrightnessSkill│
               │ LaunchAppSkill │
               └─────────────┘
```

### Provider Abstraction

```
AssistantBrain
      │
      │ uses
      ▼
AssistantProvider (abstract interface)
      │
      ├── ClaudeProvider
      ├── OpenAIProvider
      ├── GeminiProvider
      └── OllamaProvider (local)
```

### Skill Abstraction

```
SkillRegistry (Map<String, Skill>)
      │
      ├── VolumeSkill       → DeviceControlChannel (Kotlin)
      ├── BrightnessSkill   → DeviceControlChannel (Kotlin)
      ├── LaunchAppSkill    → AppLauncherChannel (Kotlin)
      ├── DoNotDisturbSkill → NotificationManager
      └── [community skills]
```

---

## 5. Folder Structure

```
Vero/
├── lib/
│   ├── core/
│   │   ├── ai/
│   │   │   ├── assistant_provider.dart        # abstract interface + models
│   │   │   ├── claude_provider.dart           # Anthropic implementation
│   │   │   ├── openai_provider.dart           # OpenAI implementation
│   │   │   ├── gemini_provider.dart           # Google Gemini implementation
│   │   │   ├── ollama_provider.dart           # local Ollama implementation
│   │   │   └── provider_registry.dart         # factory + provider map
│   │   │
│   │   ├── skills/
│   │   │   ├── skill.dart                     # abstract Skill interface
│   │   │   ├── volume_skill.dart
│   │   │   ├── brightness_skill.dart
│   │   │   ├── launch_app_skill.dart
│   │   │   ├── dnd_skill.dart                 # Do Not Disturb
│   │   │   └── skill_registry.dart            # registers all skills
│   │   │
│   │   ├── speech/
│   │   │   ├── stt_service.dart               # speech-to-text abstraction
│   │   │   └── tts_service.dart               # text-to-speech abstraction
│   │   │
│   │   ├── channels/
│   │   │   ├── device_control_channel.dart    # Dart side of MethodChannel
│   │   │   └── app_launcher_channel.dart      # Dart side of MethodChannel
│   │   │
│   │   └── assistant_brain.dart               # main orchestrator
│   │
│   ├── features/
│   │   ├── chat/
│   │   │   ├── chat_screen.dart               # main conversation UI
│   │   │   ├── chat_bubble.dart
│   │   │   └── chat_notifier.dart             # Riverpod state
│   │   │
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── provider_settings.dart         # API key entry, model select
│   │   │   └── wake_word_settings.dart
│   │   │
│   │   └── onboarding/
│   │       ├── onboarding_screen.dart
│   │       └── permissions_flow.dart          # request all required permissions
│   │
│   ├── shared/
│   │   ├── models/
│   │   │   ├── message.dart
│   │   │   └── assistant_response.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── constants.dart
│   │
│   └── main.dart
│
├── android/
│   └── app/src/main/
│       ├── kotlin/com/Vero/assistant/
│       │   ├── MainActivity.kt
│       │   ├── VeroForegroundService.kt       # persistent background service
│       │   ├── DeviceControlChannel.kt        # volume, brightness, DND
│       │   ├── AppLauncherChannel.kt          # intent-based app launching
│       │   └── WakeWordChannel.kt             # wake word bridge (if needed)
│       │
│       └── res/
│           └── drawable/
│               └── ic_notification.xml        # required for ForegroundService
│
├── docs/
│   ├── SKILL_GUIDE.md                         # how to write a community skill
│   ├── PROVIDER_GUIDE.md                      # how to add a new AI provider
│   └── SETUP.md                               # first-time dev setup
│
├── pubspec.yaml
├── README.md
└── Vero_MASTER.md                             # this document
```

---

## 6. Core Systems

### 6.1 AI Provider Layer

The provider interface is the foundation of Vero's pluggability. Every AI backend implements the same contract.

```dart
// lib/core/ai/assistant_provider.dart

abstract class AssistantProvider {
  String get name;           // e.g. "Claude (Anthropic)"
  String get modelId;        // e.g. "claude-opus-4-5-20251101"

  /// Single-shot request
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  });

  /// Streaming request (for real-time UI)
  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  });
}

class AssistantResponse {
  final String speech;                    // what TTS speaks aloud
  final String? skillId;                  // skill to execute, or null
  final Map<String, dynamic>? skillArgs;  // arguments for the skill
  final String rawText;                   // full response for chat UI

  const AssistantResponse({
    required this.speech,
    required this.rawText,
    this.skillId,
    this.skillArgs,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      speech: json['speech'] as String,
      skillId: json['skill'] as String?,
      skillArgs: json['args'] as Map<String, dynamic>?,
      rawText: jsonEncode(json),
    );
  }
}
```

**Claude Implementation example:**

```dart
// lib/core/ai/claude_provider.dart

class ClaudeProvider implements AssistantProvider {
  final String apiKey;
  final Dio _dio;

  ClaudeProvider({required this.apiKey}) : _dio = Dio();

  @override
  String get name => 'Claude (Anthropic)';

  @override
  String get modelId => 'claude-opus-4-5-20251101';

  @override
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  }) async {
    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
      data: {
        'model': modelId,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': history.map((m) => m.toJson()).toList(),
      },
    );

    final text = response.data['content'][0]['text'] as String;
    final json = jsonDecode(text) as Map<String, dynamic>;
    return AssistantResponse.fromJson(json);
  }
}
```

---

### 6.2 Skill System

Skills are discrete, testable units of device capability. New skills can be contributed by the community without touching the core.

```dart
// lib/core/skills/skill.dart

abstract class Skill {
  String get id;           // unique key, e.g. "set_volume"
  String get description;  // used in system prompt to describe capability
  Map<String, String> get argDescriptions; // arg name → description

  Future<SkillResult> execute(Map<String, dynamic> args);
}

class SkillResult {
  final bool success;
  final String? message; // optional override for TTS confirmation

  const SkillResult({required this.success, this.message});
}
```

**Volume Skill:**

```dart
// lib/core/skills/volume_skill.dart

class VolumeSkill implements Skill {
  @override
  String get id => 'set_volume';

  @override
  String get description => 'Sets the device media volume';

  @override
  Map<String, String> get argDescriptions => {
    'level': 'Integer 0–100 representing volume percentage',
  };

  @override
  Future<SkillResult> execute(Map<String, dynamic> args) async {
    final level = (args['level'] as num).toInt().clamp(0, 100);
    await VolumeController().setVolume(level / 100);
    return SkillResult(success: true);
  }
}
```

**Skill Registry builds the system prompt dynamically:**

```dart
// lib/core/skills/skill_registry.dart

class SkillRegistry {
  final Map<String, Skill> _skills = {};

  void register(Skill skill) => _skills[skill.id] = skill;

  Skill? find(String id) => _skills[id];

  /// Generates the "Available skills" section of the system prompt
  String buildSkillManifest() {
    return _skills.values.map((s) {
      final args = s.argDescriptions.entries
          .map((e) => '  - ${e.key}: ${e.value}')
          .join('\n');
      return '- ${s.id}: ${s.description}\n$args';
    }).join('\n\n');
  }
}
```

---

### 6.3 Speech Pipeline

```dart
// lib/core/speech/stt_service.dart

class SttService {
  final SpeechToText _stt = SpeechToText();

  Future<bool> initialize() => _stt.initialize();

  Stream<String> listen() async* {
    final controller = StreamController<String>();

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          controller.add(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    yield* controller.stream;
  }

  Future<void> stop() => _stt.stop();
}
```

```dart
// lib/core/speech/tts_service.dart

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text) => _tts.speak(text);
  Future<void> stop() => _tts.stop();
}
```

---

### 6.4 Native Bridge (Kotlin)

**VeroForegroundService.kt** — keeps the app alive:

```kotlin
class VeroForegroundService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Vero is listening")
            .setContentText("Say your wake word to activate")
            .setSmallIcon(R.drawable.ic_notification)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY // restart if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

**DeviceControlChannel.kt:**

```kotlin
class DeviceControlChannel(private val context: Context) {

    fun register(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, "Vero/device_control")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setVolume" -> {
                        val level = call.argument<Int>("level") ?: 0
                        setVolume(level)
                        result.success(null)
                    }
                    "setBrightness" -> {
                        val level = call.argument<Int>("level") ?: 50
                        setBrightness(level)
                        result.success(null)
                    }
                    "setDoNotDisturb" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        setDoNotDisturb(enabled)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setVolume(level: Int) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        audio.setStreamVolume(
            AudioManager.STREAM_MUSIC,
            (level / 100.0 * max).toInt(),
            0
        )
    }

    private fun setBrightness(level: Int) {
        Settings.System.putInt(
            context.contentResolver,
            Settings.System.SCREEN_BRIGHTNESS,
            (level / 100.0 * 255).toInt()
        )
    }

    private fun setDoNotDisturb(enabled: Boolean) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        nm.setInterruptionFilter(
            if (enabled) NotificationManager.INTERRUPTION_FILTER_NONE
            else NotificationManager.INTERRUPTION_FILTER_ALL
        )
    }
}
```

---

### 6.5 Assistant Brain

The orchestrator that ties everything together:

```dart
// lib/core/assistant_brain.dart

class AssistantBrain {
  final AssistantProvider provider;
  final SkillRegistry skillRegistry;
  final TtsService tts;
  final List<Message> _history = [];

  AssistantBrain({
    required this.provider,
    required this.skillRegistry,
    required this.tts,
  });

  Future<AssistantResponse> process(String userInput) async {
    // Add user message to history
    _history.add(Message(role: 'user', content: userInput));

    // Build system prompt dynamically with current skills
    final systemPrompt = _buildSystemPrompt();

    // Call AI provider
    final response = await provider.send(
      history: _history,
      systemPrompt: systemPrompt,
    );

    // Add assistant response to history
    _history.add(Message(role: 'assistant', content: response.rawText));

    // Execute skill if present
    if (response.skillId != null) {
      final skill = skillRegistry.find(response.skillId!);
      if (skill != null && response.skillArgs != null) {
        await skill.execute(response.skillArgs!);
      }
    }

    // Speak the response
    await tts.speak(response.speech);

    return response;
  }

  String _buildSystemPrompt() => '''
You are Vero, a helpful voice assistant running on Android.

Always respond with a valid JSON object in this exact format:
{
  "speech": "what you say out loud (keep it concise and natural)",
  "skill": "skill_id or null if no device action needed",
  "args": { ...skill arguments } or null
}

Available skills:
${skillRegistry.buildSkillManifest()}

Guidelines:
- Keep "speech" short and conversational
- Confirm actions in "speech" (e.g., "Done, volume set to 50%")
- For pure conversation, set "skill" and "args" to null
- Never include markdown or extra formatting in your response
- Always return valid JSON
''';

  void clearHistory() => _history.clear();
}
```

---

## 7. Android Permissions & Requirements

| Permission | Why It's Needed | How to Request |
|---|---|---|
| `RECORD_AUDIO` | Wake word + STT | `permission_handler` |
| `FOREGROUND_SERVICE` | Background persistence | Declared in manifest |
| `FOREGROUND_SERVICE_MICROPHONE` | Mic access in foreground service (API 34+) | Declared in manifest |
| `WRITE_SETTINGS` | Screen brightness control | Special intent flow |
| `ACCESS_NOTIFICATION_POLICY` | Do Not Disturb control | Special intent flow |
| `RECEIVE_BOOT_COMPLETED` | Auto-start after reboot | Declared in manifest |
| `INTERNET` | AI API calls | Declared in manifest |
| `VIBRATE` | Optional haptic feedback | Declared in manifest |

**Special permissions** (WRITE_SETTINGS, ACCESS_NOTIFICATION_POLICY) require the user to manually grant via the Settings app. Vero's onboarding flow should guide users through this step-by-step.

**Battery optimization:** Android OEMs (especially Samsung and Xiaomi) aggressively kill background processes. Vero must prompt users to add it to the battery optimization allowlist during onboarding. Use the `IGNORE_BATTERY_OPTIMIZATIONS` intent.

---

## 8. The System Prompt Strategy

The system prompt is the single most important configuration in the app. It determines whether the LLM acts like a real assistant or just a chatbot.

### Key principles:

**Force structured JSON output** — every response must be parseable. The brain catches any JSON parse errors and falls back to treating the raw text as speech only.

**Dynamic skill manifest** — the system prompt is built at runtime by `SkillRegistry`, so new skills are automatically described to the AI without hardcoding.

**Conversation memory** — the full `_history` array is sent with every request (up to the provider's context limit). This enables multi-turn commands like "set the volume to 30... actually make it 50."

**Graceful degradation** — if the AI returns non-JSON (e.g., due to a provider hiccup), the brain catches the parse error and speaks the raw text instead of crashing.

### Example interaction:

```
User:  "Hey Vero, turn the volume down to 20 and set brightness to max"

Vero → Claude:
[system prompt with skill manifest]
[full conversation history]
User: "turn the volume down to 20 and set brightness to max"

Claude → Vero:
{
  "speech": "Sure, volume set to 20 and brightness all the way up.",
  "skill": "set_volume",
  "args": { "level": 20 }
}

// Note: multi-action support means we handle an array of skills in v2
```

---

## 9. MVP Roadmap

### Phase 1 — AI Core (Week 1–2)
**Goal:** Working conversational loop with structured output

- [ ] Project scaffold (Flutter + Kotlin shell)
- [ ] `AssistantProvider` interface + `ClaudeProvider`
- [ ] `OpenAIProvider` (identical structure, easy second provider)
- [ ] `AssistantBrain` with history management
- [ ] `TtsService` (speak responses)
- [ ] Basic chat UI (message bubbles, input)
- [ ] Settings screen (API key entry, provider selector)
- [ ] JSON response parsing + error fallback

**Deliverable:** Type a message, get a spoken AI response.

---

### Phase 2 — Device Control (Week 2–3)
**Goal:** Voice commands execute real device actions

- [ ] `VeroForegroundService.kt`
- [ ] `DeviceControlChannel.kt` (volume, brightness, DND)
- [ ] `VolumeSkill`, `BrightnessSkill`, `DoNotDisturbSkill`
- [ ] `SkillRegistry` with dynamic system prompt generation
- [ ] Permissions onboarding flow (WRITE_SETTINGS, RECORD_AUDIO)
- [ ] STT integration (`SttService`)
- [ ] Full loop: voice in → Claude → skill → TTS confirmation

**Deliverable:** "Set volume to 30%" works end to end.

---

### Phase 3 — Wake Word (Week 3–4)
**Goal:** Hands-free activation

- [ ] Picovoice Porcupine integration (`picovoice_flutter`)
- [ ] Wake word detection inside `ForegroundService`
- [ ] Battery optimization onboarding (guide to allowlist)
- [ ] Visual feedback when wake word detected (waveform/pulse animation)
- [ ] OEM-specific battery exemption guidance (Samsung, Xiaomi, etc.)

**Deliverable:** "Hey Vero" activates the assistant from any screen.

---

### Phase 4 — App Launching + Polish (Week 4–5)
**Goal:** Launch apps, interact with the Android ecosystem

- [ ] `AppLauncherChannel.kt` (intent-based launching)
- [ ] `LaunchAppSkill` with package name resolution
- [ ] Installed app index (user can say "open Spotify" without knowing package names)
- [ ] `GeminiProvider` implementation
- [ ] `OllamaProvider` (local model support)
- [ ] GitHub Actions CI pipeline
- [ ] README, SKILL_GUIDE.md, PROVIDER_GUIDE.md
- [ ] v0.1.0 GitHub release + APK

**Deliverable:** Public open source release.

---

## 10. Known Limitations & Challenges

### Background Persistence
Android's Doze mode and OEM battery optimizations are the #1 reliability issue. A `ForegroundService` with `START_STICKY` is necessary but not sufficient on all devices. The onboarding flow must walk users through manufacturer-specific battery settings.

### Accessibility Service
For advanced capabilities (reading screen content, simulating taps, interacting with other app UIs), an `AccessibilityService` is needed. There is no mature Flutter plugin for this — it requires a custom Kotlin implementation exposed via `MethodChannel`. Google Play is also stricter about approving apps that declare this permission, which can complicate distribution. For the open source / sideloaded audience, this is fine.

### Wake Word Accuracy
Picovoice Porcupine is excellent but requires a custom wake word model for anything other than their built-in phrases. Custom models are free for open source use via their console.

### Context Window Limits
Sending the full conversation history with every request works well for short sessions but will hit token limits on long conversations. The `AssistantBrain` should implement a rolling window (keep the last N messages) or summarization strategy.

### Multi-Action Commands
The current MVP schema handles one skill per response. A natural command like "set volume to 30 and open Spotify" requires an array of skills. This is a v0.2 feature: change `skill`/`args` to `actions: [{skill, args}]`.

### iOS
iOS is significantly more locked down. Background microphone access, always-on processing, and system settings control are either restricted or unavailable. A potential iOS version would be a reduced-capability companion app, not a full assistant replacement.

### Play Store Distribution
Apps using `RECORD_AUDIO` in a foreground service and `WRITE_SETTINGS` face additional Play Store scrutiny. For the initial release, distribution via GitHub (direct APK) and F-Droid is recommended. Play Store submission can follow once the permission story is clean.

---

## 11. Open Source Strategy

### License
**Apache 2.0** — permissive enough for community adoption, compatible with commercial use, protects contributors.

### Repository Structure
```
github.com/[org]/Vero
├── Issues: feature requests, bug reports, skill ideas
├── Discussions: architecture decisions, provider support
├── Projects: MVP board tracking phases 1–4
└── Releases: tagged APK builds starting v0.1.0
```

### Contribution Points
The project is designed so contributors can participate at different levels:

- **Skill authors** — write a new `Skill` class following the guide, open a PR. No native code required.
- **Provider authors** — implement `AssistantProvider` for a new AI backend. Pure Dart.
- **Native contributors** — extend the Kotlin layer with new device control capabilities.
- **Core contributors** — architecture, brain, performance, battery optimization.

### Documentation Priority
- `README.md` — quick start, demo GIF, provider setup
- `SKILL_GUIDE.md` — how to write and contribute a skill
- `PROVIDER_GUIDE.md` — how to add a new AI provider
- `SETUP.md` — dev environment setup, Picovoice API key, first build

---

## 12. Future Features (Post-MVP)

| Feature | Complexity | Notes |
|---|---|---|
| Multi-action commands | Low | Change response schema to `actions[]` array |
| On-device LLM | Medium | ONNX Runtime or MediaPipe for fully offline mode |
| Custom wake word UI | Medium | Picovoice console integration for user-trained models |
| Accessibility service skills | High | Read screen, simulate taps — no plugin, pure Kotlin |
| Conversation summarization | Medium | Prevent context window overflow on long sessions |
| Locale / language support | Medium | Multi-language STT + TTS + system prompt |
| Tasker / Automation integration | Low | Expose intents that Tasker can trigger |
| Plugin/APK skill loading | High | Dynamic skill loading from external APKs |
| Widget | Low | Home screen widget for quick activation |
| Wear OS companion | High | Separate project, shared AI layer |
| iOS companion app | High | Reduced capability, shared provider layer |

---

*Document version: 0.1 — Living document, updated as architecture evolves.*
*Last updated: February 2026*
*Authors: Vero project contributors*
