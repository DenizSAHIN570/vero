import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:vero/core/ai/assistant_provider.dart';
import 'package:vero/core/ai/response_parser.dart';
import 'package:vero/shared/constants.dart';
import 'package:vero/shared/models/assistant_response.dart';
import 'package:vero/shared/models/message.dart';

/// Google Gemini provider using the generateContent REST API.
class GeminiProvider implements AssistantProvider {
  final String apiKey;
  final String _modelId;
  final Dio _dio;

  GeminiProvider({
    required this.apiKey,
    String? modelId,
  })  : _modelId = modelId ?? VeroConstants.kDefaultGeminiModel,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://generativelanguage.googleapis.com',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  @override
  String get name => 'Gemini (Google)';

  @override
  String get modelId => _modelId;

  @override
  Future<AssistantResponse> send({
    required List<Message> history,
    required String systemPrompt,
  }) async {
    // Gemini uses a different message format
    final contents = history.map((m) => {
          'role': m.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': m.content}
          ],
        }).toList();

    final response = await _dio.post(
      '/v1beta/models/$_modelId:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': contents,
        'generationConfig': {
          'maxOutputTokens': 1024,
          'responseMimeType': 'application/json',
        },
      },
    );

    final text = response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
    return ResponseParser.parse(text);
  }

  @override
  Stream<String> stream({
    required List<Message> history,
    required String systemPrompt,
  }) async* {
    // Gemini streaming via streamGenerateContent
    final contents = history.map((m) => {
          'role': m.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': m.content}
          ],
        }).toList();

    final response = await _dio.post<ResponseBody>(
      '/v1beta/models/$_modelId:streamGenerateContent',
      options: Options(responseType: ResponseType.stream),
      queryParameters: {'key': apiKey, 'alt': 'sse'},
      data: {
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': contents,
      },
    );

    final stream = response.data!.stream.transform(utf8.decoder);

    await for (final chunk in stream) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final text = json['candidates']?[0]['content']['parts'][0]['text']
                as String?;
            if (text != null) yield text;
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    }
  }
}
