# Writing a Vero Skill (Phase 2+)

Skills are the units of device capability in Vero. Each skill is a self-contained Dart class that:
1. Declares what it does (for the system prompt)
2. Executes a device action when called

No native Kotlin code is required unless you need a new `MethodChannel` capability.

## Step 1: Implement `Skill`

```dart
// lib/core/skills/my_skill.dart

import 'package:vero/core/skills/skill.dart';

class MySkill implements Skill {
  @override
  String get id => 'my_action'; // must be unique, snake_case

  @override
  String get description => 'Does something useful on the device';

  @override
  Map<String, String> get argDescriptions => {
    'target': 'What to act on (e.g., "screen", "speaker")',
    'value': 'Integer value 0–100',
  };

  @override
  Future<SkillResult> execute(Map<String, dynamic> args) async {
    final value = (args['value'] as num).toInt().clamp(0, 100);

    // Your device action here
    // e.g., call a MethodChannel, use a Flutter plugin, etc.

    return SkillResult(success: true);
    // Optionally override TTS confirmation:
    // return SkillResult(success: true, message: 'Done, set to $value%');
  }
}
```

## Step 2: Register in `SkillRegistry`

In `lib/core/skills/skill_registry.dart`:

```dart
void _registerDefaults() {
  // ...existing skills...
  register(MySkill());
}
```

## Step 3: The LLM will use it automatically

The `SkillRegistry.buildSkillManifest()` method generates the system prompt section describing all skills. Once registered, the LLM will know about your skill and can invoke it.

## Skill contract

When the LLM wants to use your skill, it returns:

```json
{
  "speech": "Done, I've triggered my_action.",
  "skill": "my_action",
  "args": { "target": "screen", "value": 75 }
}
```

Your `execute()` method receives the `args` map and returns a `SkillResult`.

## Guidelines

- Keep skills **single-purpose** — one action per skill.
- Validate and clamp all numeric inputs.
- Handle errors gracefully — return `SkillResult(success: false)` rather than throwing.
- If your skill needs a new Android capability, add a new `MethodChannel` in Kotlin and a corresponding `channel.dart` file in `lib/core/channels/`.
- Test by writing a unit test that mocks the MethodChannel.
