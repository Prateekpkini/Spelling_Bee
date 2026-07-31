import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// High-quality Text-to-Speech service for the Spelling Bee quiz.
///
/// Key design decisions:
/// - Selects the highest-quality English voice available (Google cloud voices
///   on Chrome, Microsoft Neural voices on Edge, Samantha on Safari/iOS).
/// - Retries voice loading on web because `getVoices()` returns empty until
///   the browser's `voiceschanged` event fires.
/// - Uses `en-GB` language for British spelling pronunciation.
/// - All speak calls are non-blocking and fire-and-forget — avoids hanging
///   when the browser blocks audio before a user gesture.
/// - Provides two modes: [speakWord] (slow, loud) and [speakMeaning] (natural).
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _voiceReady = false;

  // ─── Voice quality ranking (best first) ───────────────────────────
  static const _rankedVoices = [
    // Google cloud voices (Chrome)
    'Google UK English Female',
    'Google UK English Male',
    'Google US English',
    // Microsoft Neural voices (Edge / Windows 11)
    'Microsoft Libby Online',
    'Microsoft Sonia Online',
    'Microsoft Ryan Online',
    'Microsoft Jenny Online',
    'Microsoft Aria Online',
    // Microsoft desktop voices (Windows)
    'Microsoft Hazel Desktop',
    'Microsoft Zira Desktop',
    'Microsoft Zira',
    'Microsoft David Desktop',
    'Microsoft David',
    // Apple voices (macOS / iOS / Safari)
    'Samantha',
    'Daniel',
    'Karen',
    'Moira',
    'Fiona',
  ];

  /// Initialise the TTS engine. Safe to call multiple times.
  /// Never blocks — voice selection runs in background if needed.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true; // Set early to prevent re-entrant calls

    // Language — en-GB for British spelling pronunciation
    await _tts.setLanguage('en-GB');
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(kIsWeb ? 0.8 : 0.42);

    // NOTE: Do NOT call awaitSpeakCompletion(true) on web.
    // It causes speak() to hang if the browser blocks audio
    // (no user gesture yet), which breaks auto-pronunciation.

    // Select voice (best-effort, non-blocking on failure)
    await _loadVoice();
  }

  // ─── Voice selection with retry ────────────────────────────────────

  Future<void> _loadVoice() async {
    for (int attempt = 0; attempt < 3; attempt++) {
      final success = await _trySetBestVoice();
      if (success) {
        _voiceReady = true;
        return;
      }
      // Wait for voices to load (web fires `voiceschanged` asynchronously)
      if (kIsWeb && attempt < 2) {
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    debugPrint('TtsService: using default browser voice');
  }

  Future<bool> _trySetBestVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null || (voices as List).isEmpty) return false;

      final voiceList = List<Map<Object?, Object?>>.from(voices);

      // Filter to English voices only
      final englishVoices = voiceList.where((v) {
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        return locale.startsWith('en');
      }).toList();

      if (englishVoices.isEmpty) return false;

      // Try ranked preferences in order
      for (final preferred in _rankedVoices) {
        final match = englishVoices.cast<Map<Object?, Object?>>().where((v) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          return name.contains(preferred.toLowerCase());
        }).firstOrNull;

        if (match != null) {
          await _tts.setVoice({
            'name': match['name'].toString(),
            'locale': match['locale'].toString(),
          });
          debugPrint('TtsService: selected voice "${match['name']}"');
          return true;
        }
      }

      // Fallback: prefer en-GB, then any English voice
      final gbVoice = englishVoices.cast<Map<Object?, Object?>>().where((v) {
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        return locale.contains('gb') || locale.contains('uk');
      }).firstOrNull;

      final fallback = gbVoice ?? englishVoices.first;
      await _tts.setVoice({
        'name': fallback['name'].toString(),
        'locale': fallback['locale'].toString(),
      });
      debugPrint('TtsService: fallback voice "${fallback['name']}"');
      return true;
    } catch (e) {
      debugPrint('TtsService: voice selection error: $e');
      return false;
    }
  }

  // ─── Public API ────────────────────────────────────────────────────

  /// Speak a **spelling word** — slow, clear, loud.
  ///
  /// Web SpeechSynthesis `rate`:  0.1–10 (1.0 = normal).
  /// Native flutter_tts `rate`:   0.0–1.0 (0.5 = normal on most engines).
  Future<void> speakWord(String text) async {
    try {
      await init();
      await _tts.stop();

      // Slow & deliberate for spelling clarity
      await _tts.setSpeechRate(kIsWeb ? 0.75 : 0.38);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TtsService.speakWord error: $e');
    }
  }

  /// Speak a **meaning / definition** — natural, conversational pace.
  Future<void> speakMeaning(String text) async {
    try {
      await init();
      await _tts.stop();

      // Natural reading speed for sentences
      await _tts.setSpeechRate(kIsWeb ? 0.9 : 0.48);
      await _tts.setPitch(1.02);
      await _tts.setVolume(1.0);

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TtsService.speakMeaning error: $e');
    }
  }

  /// Legacy alias — routes to [speakWord].
  Future<void> speak(String text) => speakWord(text);

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
