import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Text-to-Speech service wrapping flutter_tts for pronunciation.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Web uses browser's SpeechSynthesis API
      await _tts.setLanguage('en-US');
    } else {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.4); // Slower for spelling clarity
      await _tts.setVolume(1.0);
    }
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
