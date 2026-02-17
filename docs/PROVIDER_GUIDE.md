# Adding a New AI Provider to Vero

Adding a provider requires implementing one Dart interface and registering it. No native code required.

## Step 1: Implement `AssistantProvider`

Create a new file in `lib/core/ai/`:

```dart
// lib/core/ai/my_provider.dart

import 'package:dio/dio.dart';
import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/ai/response_parser.dart';
import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

class MyProvider implements AssistantProvider {
  final String apiKey;
  final Dio _dio;

  MyProvider({required this.apiKey})
      : _dio = Dio(BaseOptions(baseUrl: 'https://api.myprovider.com'));

  @override
  String get name => 'My Provider';

  @override
  String get modelId => 'my-model-v1';

  @override
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  }) async {
    // Call your API here
    final response = await _dio.post('/v1/chat', data: {
      'model': modelId,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...history.map((m) => m.toJson()),
      ],
    });

    final text = response.data['choices'][0]['message']['content'] as String;
    return ResponseParser.parse(text); // handles JSON + fallback
  }

  @override
  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  }) async* {
    // Implement streaming if your provider supports it
    // Or just yield the full response as a single chunk:
    final response = await send(history: history, systemPrompt: systemPrompt);
    yield response.speech;
  }
}
```

## Step 2: Add constants

In `lib/shared/constants.dart`, add:

```dart
static const String kProviderMyProvider = 'my_provider';
static const String kMyProviderApiKey = 'my_provider_api_key';
static const String kDefaultMyProviderModel = 'my-model-v1';
```

## Step 3: Register in `ProviderRegistry`

In `lib/core/ai/provider_registry.dart`:

```dart
// In currentProvider():
case VeroConstants.kProviderMyProvider:
  final key = await _storage.read(key: VeroConstants.kMyProviderApiKey);
  if (key == null || key.isEmpty) return null;
  return MyProvider(apiKey: key);

// In providerDisplayNames:
VeroConstants.kProviderMyProvider: 'My Provider',
```

## Step 4: Add API key field to Settings

In `lib/features/settings/settings_screen.dart`, add a `_apiKeyField` call for your provider in `_credentialsSection()`.

## Step 5: Test

```bash
flutter test test/core/ai/my_provider_test.dart
```

## Notes

- `ResponseParser.parse()` handles all JSON parsing with robust fallback. Always use it — don't parse directly.
- Providers should not store API keys in memory longer than needed.
- The `stream()` method can be a simple wrapper around `send()` if the API doesn't support streaming.
- Open a PR with your provider + a test file. One test asserting a mocked response parses correctly is sufficient.
