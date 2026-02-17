import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/ai/response_parser.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

class OpenAIProvider implements AssistantProvider {
  final String apiKey;
  final String _modelId;
  final Dio _dio;

  OpenAIProvider({
    required this.apiKey,
    String? modelId,
  })  : _modelId = modelId ?? VeroConstants.kDefaultOpenAiModel,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.openai.com',
          headers: {
            'Authorization': 'Bearer $apiKey',
            'content-type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  @override
  String get name => 'GPT (OpenAI)';

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
      '/v1/chat/completions',
      data: {
        'model': _modelId,
        'max_tokens': 1024,
        'messages': messages,
        // Force JSON output for reliable parsing
        'response_format': {'type': 'json_object'},
      },
    );

    final text =
        response.data['choices'][0]['message']['content'] as String;
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
      '/v1/chat/completions',
      options: Options(responseType: ResponseType.stream),
      data: {
        'model': _modelId,
        'max_tokens': 1024,
        'messages': messages,
        'stream': true,
      },
    );

    final stream = response.data!.stream.transform(utf8.decoder);

    await for (final chunk in stream) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = json['choices'][0]['delta'] as Map<String, dynamic>?;
            final text = delta?['content'] as String?;
            if (text != null) yield text;
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    }
  }
}
