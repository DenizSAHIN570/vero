import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/ai/response_parser.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

class ClaudeProvider implements AssistantProvider {
  final String apiKey;
  final String _modelId;
  final Dio _dio;

  ClaudeProvider({
    required this.apiKey,
    String? modelId,
  })  : _modelId = modelId ?? VeroConstants.kDefaultClaudeModel,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.anthropic.com',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  @override
  String get name => 'Claude (Anthropic)';

  @override
  String get modelId => _modelId;

  @override
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  }) async {
    final response = await _dio.post(
      '/v1/messages',
      data: {
        'model': _modelId,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': history.map((m) => m.toJson()).toList(),
      },
    );

    final text = response.data['content'][0]['text'] as String;
    return ResponseParser.parse(text);
  }

  @override
  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      '/v1/messages',
      options: Options(responseType: ResponseType.stream),
      data: {
        'model': _modelId,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': history.map((m) => m.toJson()).toList(),
        'stream': true,
      },
    );

    final stream = response.data!.stream.transform(utf8.decoder);
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = json['delta'] as Map<String, dynamic>?;
            final text = delta?['text'] as String?;
            if (text != null) {
              buffer.write(text);
              yield text;
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    }
  }
}
