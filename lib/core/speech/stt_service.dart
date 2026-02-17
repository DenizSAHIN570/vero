import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps the [SpeechToText] plugin with a clean async API.
class SttService {
  SttService._();
  static final SttService instance = SttService._();

  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (error) {
        // Non-fatal: log and continue
        // ignore: avoid_print
        print('[STT] Error: ${error.errorMsg}');
      },
    );
    return _initialized;
  }

  bool get isAvailable => _initialized && _stt.isAvailable;
  bool get isListening => _stt.isListening;

  /// Starts listening and returns a stream of final transcription results.
  Stream<String> listen({
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) {
    final controller = StreamController<String>();

    _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          controller.add(result.recognizedWords);
          controller.close();
        }
      },
      listenFor: listenFor,
      pauseFor: pauseFor,
      cancelOnError: true,
      onDevice: false,
    );

    return controller.stream;
  }

  Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> cancel() async {
    if (_stt.isListening) await _stt.cancel();
  }
}
