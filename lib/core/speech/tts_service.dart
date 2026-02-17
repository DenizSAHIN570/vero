import 'package:flutter_tts/flutter_tts.dart';
import 'package:vero/shared/constants.dart';

/// Wraps [FlutterTts] with a clean singleton API.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _speaking = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(VeroConstants.kDefaultSpeechRate);
    await _tts.setVolume(VeroConstants.kDefaultTtsVolume);
    await _tts.setPitch(VeroConstants.kDefaultTtsPitch);

    _tts.setStartHandler(() => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((_) => _speaking = false);

    _initialized = true;
  }

  bool get isSpeaking => _speaking;

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop(); // interrupt previous speech
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);
  Future<void> setVolume(double volume) => _tts.setVolume(volume);
}
