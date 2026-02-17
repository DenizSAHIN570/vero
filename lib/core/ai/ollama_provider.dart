import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/ai/response_parser.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

/// Ollama provider for locally-hosted models.
/// Requires Ollama running at [baseUrl] (default: http://localhost:11434).
class OllamaProvider implements AssistantProvider {
  final String baseUrl;
  final String _modelId;
  final Dio _dio;

  OllamaProvider({
    String? baseUrl,
    String? modelId,
  })  : baseUrl = baseUrl ?? VeroConstants.kDefaultOllamaUrl,
        _modelId = modelId ?? VeroConstants.kDefaultOllamaModel,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? VeroConstants.kDefaultOllamaUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(minutes: 3),
        ));

  @override
  String get name => 'Ollama (local)';

  @override
  String get modelId => _modelId;

  @override
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  }) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => m.toJson()),
    ];

    final response = await _dio.post(
      '/api/chat',
      data: {
        'model': _modelId,
        'messages': messages,
        'stream': false,
        'format': 'json',
      },
    );

    final text = response.data['message']['content'] as String;
    return ResponseParser.parse(text);
  }

  @override
  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  }) async* {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => m.toJson()),
    ];

    final response = await _dio.post<ResponseBody>(
      '/api/chat',
      options: Options(responseType: ResponseType.stream),
      data: {
        'model': _modelId,
        'messages': messages,
        'stream': true,
      },
    );

    final stream = response.data!.stream.transform(utf8.decoder);

    await for (final chunk in stream) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final text = json['message']?['content'] as String?;
          if (text != null) yield text;
          if (json['done'] == true) return;
        } catch (_) {
          // Skip malformed lines
        }
      }
    }
  }
}
