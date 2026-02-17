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
   - [Memory & Persistence](#66-memory--persistence)
   - [Notification Reader](#67-notification-reader)
   - [Default Assistant Integration](#68-default-assistant-integration)
7. [Android Permissions & Requirements](#7-android-permissions--requirements)
8. [The System Prompt Strategy](#8-the-system-prompt-strategy)
9. [MVP Roadmap](#9-mvp-roadmap)
10. [Known Limitations & Challenges](#10-known-limitations--challenges)
11. [Open Source Strategy](#11-open-source-strategy)
12. [Future Features (Post-MVP)](#12-future-features-post-mvp)
13. [Project Info](#13-project-info)

---

## 1. Vision & Goals

Vero is a **fully open source, privacy-respecting, LLM-powered voice assistant for Android**. Unlike Google Assistant or Alexa, Vero is:

- **Pluggable** — users choose their own AI backend (Claude, GPT-4, Gemini, local models, etc.)
- **Open** — every skill, every provider, every native bridge is transparent and community-extensible
- **Capable** — real device control, wake word detection, app launching, notification reading, and natural conversation
- **Persistent** — remembers context across sessions via local conversation memory
- **Private** — no data sent anywhere except to the AI provider the user explicitly configures

### Core Capabilities (MVP)

- Wake word detection (always-on, low power) — moved to Phase 2
- Natural language voice input via speech-to-text
- LLM-powered response and command parsing
- Multi-action commands (execute multiple skills in a single utterance)
- Device control: volume, brightness, Do Not Disturb
- Launch and interact with third-party apps via Intents
- Notification reading via NotificationListenerService
- Text-to-speech response output with proper status sync
- Persistent conversation memory across sessions (local SQLite)
- Default assistant integration (responds to home button long-press)
- Persistent background service
- Graceful error recovery with spoken fallback responses
- Settings UI for provider config, API keys, and model selection
- Light and dark theme

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

**The gap:** No mature, open source, Flutter-based, LLM-pluggable Android assistant with real device control, persistent memory, and notification awareness exists. Vero fills it.

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
| Conversation memory (persistent) | `sqflite` |
| State management | `riverpod` |
| Permissions | `permission_handler` |
| Notifications | `flutter_local_notifications` |
| URL launching ("Get API key" buttons) | `url_launcher` |

### Native Android Layer (Kotlin)

| Role | Approach |
|---|---|
| Persistent background | `ForegroundService` with ongoing notification |
| Device control bridge | `MethodChannel` → `AudioManager`, `Settings.System` |
| Wake word detection | Picovoice native SDK via Flutter plugin |
| Notification reading | `NotificationListenerService` subclass |
| Default assistant | Handle `android.intent.action.ASSIST` intent in `MainActivity` |
| App launching | `Intent` + `PackageManager` |
| Battery optimization bypass | Guided user flow to whitelist app |
| Boot auto-start | `BroadcastReceiver` for `BOOT_COMPLETED` |

### AI Providers (Pluggable)

| Provider | Base URL | Key source | Notes |
|---|---|---|---|
| **Anthropic Claude** | `api.anthropic.com/v1/messages` | console.anthropic.com | Pay-per-token |
| **OpenAI GPT** | `api.openai.com/v1/chat/completions` | platform.openai.com | Pay-per-token |
| **Google Gemini** | `generativelanguage.googleapis.com` | aistudio.google.com | **Free tier available** |
| **xAI Grok** | `api.x.ai/v1` | console.x.ai | OpenAI-compatible, very cheap |
| **Kimi (Moonshot)** | `api.moonshot.ai/v1` | platform.moonshot.ai | OpenAI-compatible, very cheap |
| **Z.ai (GLM)** | `api.z.ai/api/paas/v4` | z.ai | OpenAI-compatible, $3/mo flat tier |
| **Ollama (local)** | `localhost:11434/api/chat` | None — self-hosted | **Completely free** |
| **Custom / OpenAI-compatible** | User-supplied base URL | User-supplied | Bring your own |

> ⚠️ **Subscriptions ≠ API access.** Claude Pro/Max, ChatGPT Plus/Pro, and Grok Premium+ are **consumer subscriptions** for using those companies' own chat apps. They are entirely separate products from the API and **cannot be used in Vero**. Every provider deliberately walls these off. A user must obtain a separate API key from the provider's developer console — this is billed per token, independent of any subscription they may hold.
>
> **Recommended free entry point:** Gemini (free API tier, no billing required) or Ollama (fully local).

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
User speaks "Hey Vero..."
     │
     ▼
┌─────────────────────────┐
│   Wake Word Detection   │  ← Picovoice Porcupine (always-on, ~1% CPU)
│   (ForegroundService)   │
└────────────┬────────────┘
             │ wake word detected
             ▼
┌─────────────────────────┐
│   Speech-to-Text (STT)  │  ← Android SpeechRecognizer
└────────────┬────────────┘
             │ transcript string
             ▼
┌─────────────────────────┐
│    AssistantBrain       │  ← orchestrates everything
│  - loads memory         │
│  - injects system prompt│
│  - manages history      │
│  - calls AI provider    │
│  - persists memory      │
└────────────┬────────────┘
             │ AssistantResponse (speech + actions[])
             ▼
     ┌───────┴────────┐
     │                │
     ▼                ▼
┌─────────┐    ┌──────────────────┐
│   TTS   │    │   Skill Router   │  ← executes all actions in sequence
│ speaks  │    │                  │
│response │    │ VolumeSkill      │
└─────────┘    │ BrightnessSkill  │
               │ LaunchAppSkill   │
               │ DndSkill         │
               │ NotificationSkill│
               └──────────────────┘
```

### Multi-Action Response Schema

The response schema supports an array of actions, enabling commands like
"turn off DND, set brightness to 80, and open YouTube" in a single utterance:

```json
{
  "speech": "Sure, DND off, brightness at 80, opening YouTube.",
  "actions": [
    { "skill": "set_do_not_disturb", "args": { "enabled": false } },
    { "skill": "set_brightness",     "args": { "level": 80 } },
    { "skill": "launch_app",         "args": { "package": "com.google.android.youtube" } }
  ]
}
```

Single-action commands use a one-element array. `"actions": []` means conversation only.

### Provider Abstraction

```
AssistantBrain
      │
      │ uses
      ▼
AssistantProvider (abstract interface)
      │
      ├── ClaudeProvider              API key → console.anthropic.com
      ├── OpenAIProvider              API key → platform.openai.com
      ├── GeminiProvider              API key → aistudio.google.com (free tier)
      ├── OpenAICompatibleProvider    (abstract base for OAI-compatible providers)
      │     ├── GrokProvider          API key → console.x.ai
      │     ├── KimiProvider          API key → platform.moonshot.ai
      │     ├── ZaiProvider           API key → z.ai
      │     └── CustomProvider        user-supplied base URL + key
      └── OllamaProvider              local, no key
```

Grok, Kimi, and Z.ai all use the OpenAI wire format. They extend a shared `OpenAICompatibleProvider` that accepts a configurable `baseUrl` and `defaultModel`, so adding new OpenAI-compatible providers in future requires only a few lines.

### Skill Abstraction

```
SkillRegistry (Map<String, Skill>)
      │
      ├── VolumeSkill        → DeviceControlChannel (Kotlin)
      ├── BrightnessSkill    → DeviceControlChannel (Kotlin)
      ├── LaunchAppSkill     → AppLauncherChannel (Kotlin)
      ├── DoNotDisturbSkill  → DeviceControlChannel (Kotlin)
      ├── ReadNotifSkill     → NotificationChannel (Kotlin)
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
│   │   │   ├── openai_compatible_provider.dart # shared base for OAI-wire providers
│   │   │   ├── claude_provider.dart           # Anthropic native format
│   │   │   ├── openai_provider.dart
│   │   │   ├── gemini_provider.dart
│   │   │   ├── grok_provider.dart             # extends OpenAICompatibleProvider
│   │   │   ├── kimi_provider.dart             # extends OpenAICompatibleProvider
│   │   │   ├── zai_provider.dart              # extends OpenAICompatibleProvider
│   │   │   ├── custom_provider.dart           # extends OpenAICompatibleProvider
│   │   │   ├── ollama_provider.dart
│   │   │   ├── provider_registry.dart
│   │   │   └── response_parser.dart
│   │   │
│   │   ├── skills/
│   │   │   ├── skill.dart                     # abstract Skill interface
│   │   │   ├── skill_registry.dart
│   │   │   ├── volume_skill.dart
│   │   │   ├── brightness_skill.dart
│   │   │   ├── dnd_skill.dart
│   │   │   ├── launch_app_skill.dart
│   │   │   ├── read_notifications_skill.dart
│   │   │   └── app_index.dart                 # fuzzy app name resolver
│   │   │
│   │   ├── memory/
│   │   │   ├── memory_store.dart              # SQLite persistence
│   │   │   └── conversation_summary.dart      # summarization strategy
│   │   │
│   │   ├── speech/
│   │   │   ├── stt_service.dart
│   │   │   └── tts_service.dart               # includes speakAndWait()
│   │   │
│   │   ├── channels/
│   │   │   ├── device_control_channel.dart
│   │   │   ├── app_launcher_channel.dart
│   │   │   ├── notification_channel.dart      # Dart side of NotificationListener
│   │   │   └── service_channel.dart           # start/stop ForegroundService
│   │   │
│   │   └── assistant_brain.dart               # main orchestrator
│   │
│   ├── features/
│   │   ├── chat/
│   │   │   ├── chat_screen.dart
│   │   │   ├── chat_bubble.dart
│   │   │   └── chat_notifier.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── provider_settings.dart         # model selector
│   │   │   └── wake_word_settings.dart
│   │   │
│   │   └── onboarding/
│   │       ├── onboarding_screen.dart
│   │       └── permissions_flow.dart
│   │
│   ├── shared/
│   │   ├── models/
│   │   │   ├── message.dart
│   │   │   └── assistant_response.dart        # updated for actions[]
│   │   ├── theme/
│   │   │   └── app_theme.dart                 # dark + light themes
│   │   └── constants.dart
│   │
│   └── main.dart
│
├── android/
│   └── app/src/main/
│       ├── kotlin/com/vero/assistant/
│       │   ├── MainActivity.kt                # handles ASSIST intent
│       │   ├── VeroForegroundService.kt
│       │   ├── DeviceControlChannel.kt
│       │   ├── AppLauncherChannel.kt
│       │   ├── NotificationListenerService.kt
│       │   ├── WakeWordChannel.kt             # Phase 3
│       │   └── BootReceiver.kt
│       │
│       └── res/drawable/
│           └── ic_notification.xml
│
├── docs/
│   ├── SKILL_GUIDE.md
│   ├── PROVIDER_GUIDE.md
│   └── SETUP.md
│
├── pubspec.yaml
├── README.md
└── VERO_MASTER.md
```

---

## 6. Core Systems

### 6.1 AI Provider Layer

The provider interface is the foundation of Vero's pluggability. Every AI backend implements the same contract.

**Auth model — API keys only.** All providers require an API key from their developer console. Consumer subscriptions (Claude Pro, ChatGPT Plus, Grok Premium+, etc.) are completely separate products and **cannot be used here** — this is each provider's deliberate policy, not a Vero limitation. The Settings screen shows a "Get API key →" deep link for each provider so users can obtain one in one tap.

Grok, Kimi, and Z.ai all speak the OpenAI wire format, so they share a base class:

```dart
// lib/core/ai/openai_compatible_provider.dart
abstract class OpenAICompatibleProvider implements AssistantProvider {
  final String apiKey;
  final String baseUrl;
  final String defaultModel;
  // ... shared send() / stream() implementation using OpenAI format
}

// Three lines to add a new compatible provider:
class GrokProvider extends OpenAICompatibleProvider {
  GrokProvider({required String apiKey}) : super(
    apiKey: apiKey,
    baseUrl: 'https://api.x.ai/v1',
    defaultModel: 'grok-4-fast',
  );
}

class KimiProvider extends OpenAICompatibleProvider {
  KimiProvider({required String apiKey}) : super(
    apiKey: apiKey,
    baseUrl: 'https://api.moonshot.ai/v1',
    defaultModel: 'kimi-latest',
  );
}

class ZaiProvider extends OpenAICompatibleProvider {
  ZaiProvider({required String apiKey}) : super(
    apiKey: apiKey,
    baseUrl: 'https://api.z.ai/api/paas/v4',
    defaultModel: 'glm-4-plus',
  );
}
```

**Provider key setup links** ("Get API key →" buttons in Settings):

| Provider | URL | Free tier? |
|---|---|---|
| Claude | console.anthropic.com/settings/keys | No |
| OpenAI | platform.openai.com/api-keys | No |
| Gemini | aistudio.google.com/apikey | **Yes** |
| Grok | console.x.ai | No |
| Kimi | platform.moonshot.ai | No (min $1 credit) |
| Z.ai | z.ai/subscribe | $3/mo flat or PAYG |
| Ollama | — (local) | **Free** |

```dart
abstract class AssistantProvider {
  String get name;
  String get modelId;

  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  });

  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  });
}
```

---

### 6.2 Skill System

Skills are discrete, testable units of device capability. The system now supports **multi-action responses** — the LLM can return an array of actions, all of which are executed sequentially.

```dart
// Updated AssistantResponse model
class AssistantResponse {
  final String speech;
  final List<SkillAction> actions;   // replaces single skillId/skillArgs
  final String rawText;
}

class SkillAction {
  final String skillId;
  final Map<String, dynamic> args;
}
```

The `AssistantBrain` executes all actions in order before speaking:

```dart
for (final action in response.actions) {
  final skill = skillRegistry.find(action.skillId);
  if (skill != null) {
    final result = await skill.execute(action.args);
    if (result.message != null) overrideSpeech = result.message;
  }
}
await tts.speakAndWait(overrideSpeech ?? response.speech);
```

---

### 6.3 Speech Pipeline

**TtsService** exposes `speakAndWait()` which completes only after TTS finishes, enabling proper `ChatStatus` sync:

```dart
Future<void> speakAndWait(String text) async {
  final completer = Completer<void>();
  _tts.setCompletionHandler(() => completer.complete());
  await _tts.speak(text);
  await completer.future;
}
```

**SttService** is unchanged — stream-based, returns final transcription results.

---

### 6.4 Native Bridge (Kotlin)

**VeroForegroundService** — persistent background service with `START_STICKY`.

**DeviceControlChannel** — volume, brightness, DND via `MethodChannel("vero/device_control")`.

**AppLauncherChannel** — app launching + installed app list via `MethodChannel("vero/app_launcher")`.

**NotificationListenerService** — reads active notifications and exposes them to Flutter via `MethodChannel("vero/notifications")`:

```kotlin
class VeroNotificationListener : NotificationListenerService() {
  fun getActiveNotifications(): List<Map<String, String>> {
    return activeNotifications.map { sbn ->
      mapOf(
        "app"   to sbn.packageName,
        "title" to (sbn.notification.extras.getString("android.title") ?: ""),
        "text"  to (sbn.notification.extras.getString("android.text") ?: ""),
        "time"  to sbn.postTime.toString()
      )
    }
  }
}
```

**MainActivity** — handles `android.intent.action.ASSIST` intent so Vero responds to the home button long-press when set as default assistant:

```kotlin
override fun onNewIntent(intent: Intent) {
  super.onNewIntent(intent)
  if (intent.action == Intent.ACTION_ASSIST) {
    // Notify Flutter side to activate listening
    channel.invokeMethod("onAssistActivated", null)
  }
}
```

**BootReceiver** — starts `VeroForegroundService` automatically after device reboot.

---

### 6.5 Assistant Brain

The orchestrator. Key changes from Phase 1:

- Accepts `SkillRegistry` and executes multi-action responses
- Loads persisted history from `MemoryStore` on construction
- Saves new messages to `MemoryStore` after each turn
- Uses `speakAndWait()` for proper status sync
- Graceful error recovery: catches all exceptions, speaks a fallback phrase rather than showing a silent error

```dart
Future<AssistantResponse> process(String userInput) async {
  _history.add(Message.user(userInput));
  await _memoryStore.save(Message.user(userInput));

  try {
    final response = await provider.send(
      history: _rolledHistory(),
      systemPrompt: _buildSystemPrompt(),
    );

    _history.add(Message.assistant(response.rawText));
    await _memoryStore.save(Message.assistant(response.rawText));

    // Execute all actions in sequence
    String? overrideSpeech;
    for (final action in response.actions) {
      final skill = skillRegistry?.find(action.skillId);
      if (skill != null) {
        final result = await skill.execute(action.args);
        if (result.message != null) overrideSpeech = result.message;
      }
    }

    await _tts.speakAndWait(overrideSpeech ?? response.speech);
    return response;

  } catch (e) {
    // Graceful spoken fallback
    const fallback = "Sorry, I ran into a problem. Please try again.";
    await _tts.speakAndWait(fallback);
    rethrow; // let ChatNotifier show the error banner too
  }
}
```

---

### 6.6 Memory & Persistence

Conversation history is persisted to a local SQLite database via `sqflite`. This enables Vero to remember context across app restarts.

```dart
// lib/core/memory/memory_store.dart

class MemoryStore {
  static const _dbName = 'vero_memory.db';
  static const _tableName = 'messages';

  Future<void> save(Message message) async { ... }
  Future<List<Message>> loadRecent({int limit = 50}) async { ... }
  Future<void> clear() async { ... }
}
```

**Summarization strategy** (for long-term memory): when history exceeds `kMaxHistoryMessages`, older messages are summarized into a single system-injected context block rather than discarded. This preserves important facts (user's name, preferences, recurring tasks) without blowing the context window.

The `AssistantBrain` loads the last N messages from `MemoryStore` on initialization, so every session begins with awareness of recent conversations.

---

### 6.7 Notification Reader

Vero can read active notifications aloud via a `NotificationListenerService`. This requires the user to grant Notification Access in Android settings (guided in onboarding).

`ReadNotificationsSkill` calls the Kotlin listener and formats the response:
- "You have 3 notifications: 2 messages from WhatsApp and a Gmail from Sarah."
- Optionally filters by app: "Read my WhatsApp messages"

This is one of the key features that differentiates Vero from a pure chatbot.

---

### 6.8 Default Assistant Integration

For Vero to respond to the Android home button long-press (like Google Assistant), two things are required:

1. **User sets Vero as default digital assistant** in `Settings > Apps > Default Apps > Digital Assistant`. Onboarding guides users through this with a direct deep link.

2. **MainActivity handles the ASSIST intent:**
```kotlin
// In MainActivity, declared in AndroidManifest:
// <action android:name="android.intent.action.ASSIST" />
// <category android:name="android.intent.category.DEFAULT" />
```

When activated via the home button, Vero immediately starts listening (skips wake word detection) and responds as normal.

---

## 7. Android Permissions & Requirements

| Permission | Why It's Needed | How to Request |
|---|---|---|
| `RECORD_AUDIO` | Wake word + STT | `permission_handler` |
| `FOREGROUND_SERVICE` | Background persistence | Declared in manifest |
| `FOREGROUND_SERVICE_MICROPHONE` | Mic access in foreground service (API 34+) | Declared in manifest |
| `WRITE_SETTINGS` | Screen brightness control | Special intent flow |
| `ACCESS_NOTIFICATION_POLICY` | Do Not Disturb control | Special intent flow |
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Read active notifications | Special intent flow |
| `RECEIVE_BOOT_COMPLETED` | Auto-start after reboot | Declared in manifest |
| `INTERNET` | AI API calls | Declared in manifest |
| `VIBRATE` | Optional haptic feedback | Declared in manifest |
| `POST_NOTIFICATIONS` | Foreground service notification (API 33+) | `permission_handler` |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent OEM from killing service | Special intent flow |

**Special permissions** require the user to manually grant via the Settings app. The onboarding permissions flow handles each one with an explanation card and a direct "Grant" button that opens the correct system screen.

---

## 8. The System Prompt Strategy

The system prompt is the single most important configuration in the app.

### Key principles

**Multi-action JSON schema** — the LLM always returns an `actions` array, even for single commands or pure conversation:

```
Always respond with valid JSON:
{
  "speech": "what you say aloud (1–2 sentences, no markdown)",
  "actions": [
    { "skill": "skill_id", "args": { ...args } }
  ]
}
For conversation only, return "actions": [].
```

**Dynamic skill manifest** — `SkillRegistry.buildSkillManifest()` generates the skills section at runtime, so new community skills are automatically described to the LLM without touching the prompt.

**Memory context injection** — when summarized older history exists, it is injected as a system context block before the live conversation window:

```
[Context from previous sessions]
The user's name is Deniz. They prefer volume at 40% and use Spotify for music.
[End context]
```

**Graceful degradation** — `ResponseParser` handles malformed JSON with a 3-step fallback chain. If all parsing fails, the raw text is spoken rather than the app crashing.

**Error recovery** — the brain catches all exceptions and speaks a fallback phrase before rethrowing, so the user always gets an audible response even on failure.

---

## 9. MVP Roadmap

### Phase 1 — AI Core ✅ Complete
- Pluggable AI providers (Claude, OpenAI, Gemini, Ollama)
- AssistantBrain with rolling history
- Robust ResponseParser with fallback chain
- TtsService + SttService
- Chat UI with ThinkingBubble
- Settings screen with secure API key storage
- Dark theme

---

### Phase 2 — Full Featured Assistant (Current)
**Goal:** Everything needed to be a daily-driver assistant

**Device Control**
- [ ] Skill abstract class + SkillRegistry
- [ ] VolumeSkill, BrightnessSkill, DoNotDisturbSkill
- [ ] LaunchAppSkill with fuzzy app name resolution
- [ ] DeviceControlChannel.kt + AppLauncherChannel.kt
- [ ] VeroForegroundService.kt + BootReceiver.kt
- [ ] Phase 2 permissions in AndroidManifest

**Multi-Action Commands**
- [ ] Update `AssistantResponse` model to use `actions[]` array
- [ ] Update `ResponseParser` for new schema
- [ ] Update `AssistantBrain` to execute actions sequentially
- [ ] Update system prompt to use new schema

**Memory & Persistence**
- [ ] `MemoryStore` (SQLite via sqflite)
- [ ] Load recent history in `AssistantBrain` on init
- [ ] Save messages after each turn
- [ ] Conversation summarization for long-term context

**Wake Word** (pulled forward from Phase 3)
- [ ] Picovoice Porcupine integration
- [ ] Wake word detection inside ForegroundService
- [ ] Visual feedback on activation (waveform/pulse)

**Notification Reading**
- [ ] `VeroNotificationListener.kt`
- [ ] `NotificationChannel.dart` wrapper
- [ ] `ReadNotificationsSkill`
- [ ] Notification Access permission in onboarding

**Default Assistant Integration**
- [ ] Handle `ACTION_ASSIST` intent in `MainActivity`
- [ ] Onboarding step guiding user to set Vero as default assistant
- [ ] Skip wake word when activated via home button long-press

**Error Recovery**
- [ ] `speakAndWait()` in TtsService
- [ ] Fix ChatStatus sync (remove 300ms hack)
- [ ] Spoken fallback on all failure paths in AssistantBrain

**UI & Polish**
- [ ] Light theme + theme switcher in settings
- [ ] Mic button in ChatScreen with STT wiring
- [ ] Model selector per provider in Settings
- [ ] Onboarding screen (first run flow)
- [ ] Permissions onboarding flow

**Deliverable:** "Hey Vero, read my notifications, turn off DND, and open Spotify" works end to end.

---

### Phase 3 — Public Release
- [ ] GitHub Actions CI (build + test on every PR)
- [ ] SETUP.md developer guide
- [ ] Demo GIF for README
- [ ] F-Droid metadata
- [ ] v0.1.0 tagged APK release

---

## 10. Known Limitations & Challenges

### Background Persistence
Android's Doze mode and OEM battery optimizations are the #1 reliability issue. `START_STICKY` + foreground service is necessary but not sufficient on Samsung/Xiaomi/OnePlus. The onboarding flow must walk users through manufacturer-specific battery settings.

### Notification Listener
`NotificationListenerService` requires the user to grant access in a dedicated Android settings screen. It cannot be requested via `permission_handler`. The onboarding flow must deep-link directly to this screen.

### Default Assistant
The user must manually set Vero as the default digital assistant. This cannot be done programmatically. Onboarding provides a direct deep link to `Settings > Apps > Default Apps > Digital Assistant`.

### Multi-Action Ordering
Actions are executed sequentially. If one skill fails (e.g., app not installed), subsequent actions still run. The LLM's speech should only promise what is likely to succeed.

### Context Window Limits
The rolling window + summarization strategy handles short-to-medium sessions well. Very long sessions with complex state may still lose important context. This is an ongoing research area.

### Notification Privacy
Reading notifications gives Vero access to potentially sensitive content (messages, emails). This must be clearly communicated in onboarding, and notification data must never be sent to the LLM without user confirmation in a future privacy settings screen.

### Accessibility Service
Not yet implemented. Required for reading screen content and simulating taps. High complexity, strict Play Store scrutiny. Planned for post-MVP.

### Play Store Distribution
The combination of `RECORD_AUDIO` foreground service, `WRITE_SETTINGS`, and `BIND_NOTIFICATION_LISTENER_SERVICE` will require manual Play Store review. For v0.1.0, distribute via GitHub APK and F-Droid only.

---

## 11. Open Source Strategy

### License
**Apache 2.0** — permissive for community adoption and commercial use, with explicit patent grant protection for contributors.

### Repository
`github.com/DenizSAHIN570/vero`

```
├── Issues:      feature requests, bug reports, skill ideas
├── Discussions: architecture decisions, provider support
├── Projects:    Phase 2 task board
└── Releases:    tagged APK builds from v0.1.0
```

### Contribution Levels
- **Skill authors** — implement `Skill`, open a PR. No native code required.
- **Provider authors** — implement `AssistantProvider`. Pure Dart.
- **Native contributors** — extend Kotlin channels with new device capabilities.
- **Core contributors** — brain, memory, performance, battery optimization.

### Documentation
- `README.md` — quick start, demo, provider setup
- `SKILL_GUIDE.md` — how to write a community skill
- `PROVIDER_GUIDE.md` — how to add a new AI provider
- `SETUP.md` — dev environment setup (Phase 3)

---

## 12. Future Features (Post-MVP)

| Feature | Complexity | Notes |
|---|---|---|
| Accessibility service skills | High | Read screen, simulate taps — pure Kotlin |
| On-device LLM | Medium | ONNX Runtime / MediaPipe for offline mode |
| Custom wake word UI | Medium | Picovoice console + user-trained models |
| Locale / language support | Medium | Multi-language STT + TTS + system prompt |
| Notification reply | Medium | Reply to messages directly via Vero |
| Tasker / Automation integration | Low | Expose intents for Tasker |
| Dynamic skill loading (plugins) | High | Load skill APKs at runtime |
| Home screen widget | Low | Quick activation without opening app |
| Wear OS companion | High | Separate project, shared AI layer |
| iOS companion app | High | Reduced capability, shared provider layer |
| Conversation export | Low | Export chat history as markdown/JSON |
| Voice profiles | Medium | Per-user voice recognition and preferences |

---

## 13. Project Info

| | |
|---|---|
| **Website** | veroassistant.com |
| **Repository** | github.com/DenizSAHIN570/vero |
| **Package ID** | com.veroassistant.app |
| **Wake word** | "Hey Vero" |
| **License** | Apache 2.0 |
| **Min Android** | 8.0 (API 26) |
| **Target Android** | 14 (API 34) |

---

*Document version: 0.3 — Living document, updated as architecture evolves.*
*Last updated: February 2026*
*Authors: Vero project contributors*
