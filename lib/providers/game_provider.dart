import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/word.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/services/api_service.dart';

// ── Game Status ──────────────────────────────────────────────────────

enum GameStatus { ready, playing, paused, ended }

enum EndReason { timerExpired, shieldsLost, surrendered, allWordsCleared }

enum FeedbackType { correct, wrong, passed, reward }

// ── Feedback Event ──────────────────────────────────────────────────

class FeedbackEvent {
  final FeedbackType type;
  final String message;
  final List<String> rewards; // e.g. ["+30s Time", "+1 Pass"]

  const FeedbackEvent({
    required this.type,
    required this.message,
    this.rewards = const [],
  });
}

// ── Game State ──────────────────────────────────────────────────────

class GameState {
  final int score;
  final int correctCount;
  final int wrongCount;
  final int shields;
  final int passes;
  final int passesUsed;
  final int timeRemainingMs; // in milliseconds for precision
  final List<Word> wordBank;
  final Set<int> skippedIndices;
  final int currentWordIndex;
  final GameStatus status;
  final EndReason? endReason;
  final FeedbackEvent? feedback;
  final String studentId;
  final String studentName;
  final String grade;
  final bool offlineMode;       // true = airplane-mode flow
  final bool resultSubmitted;   // true = results uploaded to server
  final String? gameToken;      // stored for offline submission

  const GameState({
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.shields = 5,
    this.passes = 5,
    this.passesUsed = 0,
    this.timeRemainingMs = 30 * 60 * 1000, // 30 minutes
    this.wordBank = const [],
    this.skippedIndices = const {},
    this.currentWordIndex = 0,
    this.status = GameStatus.ready,
    this.endReason,
    this.feedback,
    this.studentId = '',
    this.studentName = '',
    this.grade = '',
    this.offlineMode = false,
    this.resultSubmitted = false,
    this.gameToken,
  });

  int get timeRemainingSeconds => (timeRemainingMs / 1000).ceil();

  int get minutes => timeRemainingSeconds ~/ 60;
  int get seconds => timeRemainingSeconds % 60;

  Word? get currentWord {
    if (wordBank.isEmpty || currentWordIndex >= wordBank.length) return null;
    return wordBank[currentWordIndex];
  }

  bool get hasWordsRemaining {
    for (var i = currentWordIndex; i < wordBank.length; i++) {
      if (!skippedIndices.contains(i)) return true;
    }
    return false;
  }

  double get accuracy {
    final total = correctCount + wrongCount;
    if (total == 0) return 0.0;
    return (correctCount / total) * 100;
  }

  GameState copyWith({
    int? score,
    int? correctCount,
    int? wrongCount,
    int? shields,
    int? passes,
    int? passesUsed,
    int? timeRemainingMs,
    List<Word>? wordBank,
    Set<int>? skippedIndices,
    int? currentWordIndex,
    GameStatus? status,
    EndReason? endReason,
    FeedbackEvent? feedback,
    String? studentId,
    String? studentName,
    String? grade,
    bool? offlineMode,
    bool? resultSubmitted,
    String? gameToken,
  }) {
    return GameState(
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      shields: shields ?? this.shields,
      passes: passes ?? this.passes,
      passesUsed: passesUsed ?? this.passesUsed,
      timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
      wordBank: wordBank ?? this.wordBank,
      skippedIndices: skippedIndices ?? this.skippedIndices,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      status: status ?? this.status,
      endReason: endReason ?? this.endReason,
      feedback: feedback,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      grade: grade ?? this.grade,
      offlineMode: offlineMode ?? this.offlineMode,
      resultSubmitted: resultSubmitted ?? this.resultSubmitted,
      gameToken: gameToken ?? this.gameToken,
    );
  }
}

// ── Game Notifier ───────────────────────────────────────────────────

class GameNotifier extends StateNotifier<GameState> {
  Timer? _timer;
  final Ref _ref;

  GameNotifier(this._ref) : super(const GameState());

  /// Initialize the game with a word bank, student info, and settings.
  void initGame({
    required List<Word> wordBank,
    required String studentId,
    required String studentName,
    required String grade,
    required int timerSeconds,
    required int initialShields,
    required int initialPasses,
    bool offlineMode = false,
    String? gameToken,
  }) {
    _timer?.cancel();
    state = GameState(
      wordBank: wordBank,
      studentId: studentId,
      studentName: studentName,
      grade: grade,
      timeRemainingMs: timerSeconds * 1000,
      shields: initialShields,
      passes: initialPasses,
      status: GameStatus.ready,
      offlineMode: offlineMode,
      gameToken: gameToken,
    );
  }

  /// Start the championship — begins the countdown timer.
  void startGame() {
    state = state.copyWith(status: GameStatus.playing);
    _startTimer();
    // Advance to first available word
    _advanceToNextWord();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.status != GameStatus.playing) return;

      final remaining = state.timeRemainingMs - 100;
      if (remaining <= 0) {
        timer.cancel();
        _endGame(EndReason.timerExpired);
      } else {
        state = state.copyWith(timeRemainingMs: remaining);
      }
    });
  }

  /// Pause timer (for feedback animations).
  void pauseTimer() {
    if (state.status == GameStatus.playing) {
      state = state.copyWith(status: GameStatus.paused);
    }
  }

  /// Resume timer after feedback.
  void resumeTimer() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing, feedback: null);
    }
  }

  /// Submit an answer for the current word.
  void submitAnswer(String answer) {
    final word = state.currentWord;
    if (word == null || state.status != GameStatus.playing) return;

    // Pause timer during feedback
    pauseTimer();

    final trimmedAnswer = answer.trim().toLowerCase();
    final isCorrect = trimmedAnswer == word.spellingBritish.trim().toLowerCase() ||
        trimmedAnswer == word.spellingAmerican.trim().toLowerCase();

    if (isCorrect) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  void _handleCorrect() {
    final newCorrect = state.correctCount + 1;
    final newScore = state.score + 1;

    // Calculate rewards
    final rewards = <String>[];
    var newTime = state.timeRemainingMs;
    var newPasses = state.passes;
    var newShields = state.shields;

    // Every 3 correct = +30 seconds
    if (newCorrect % 3 == 0) {
      newTime += 30 * 1000;
      rewards.add('+30s Time');
    }

    // Every 5 correct = +1 Pass (cap at 5)
    if (newCorrect % 5 == 0 && newPasses < 5) {
      newPasses++;
      rewards.add('+1 Pass');
    }

    // Every 10 correct = +1 Shield (cap at 5)
    if (newCorrect % 10 == 0 && newShields < 5) {
      newShields++;
      rewards.add('+1 Shield');
    }

    state = state.copyWith(
      score: newScore,
      correctCount: newCorrect,
      timeRemainingMs: newTime,
      passes: newPasses,
      shields: newShields,
      feedback: FeedbackEvent(
        type: rewards.isNotEmpty ? FeedbackType.reward : FeedbackType.correct,
        message: 'Correct!',
        rewards: rewards,
      ),
    );
  }

  void _handleWrong() {
    final newWrong = state.wrongCount + 1;
    final newShields = state.shields - 1;

    state = state.copyWith(
      wrongCount: newWrong,
      shields: newShields,
      feedback: FeedbackEvent(
        type: FeedbackType.wrong,
        message: newShields <= 0 ? 'No shields remaining!' : 'Incorrect!',
      ),
    );

    // Check if shields are depleted
    if (newShields <= 0) {
      _endGame(EndReason.shieldsLost);
    }
  }

  /// Move to next word after feedback is dismissed.
  void nextWord() {
    resumeTimer();
    _advanceToNextWord();
  }

  /// Pass the current word (costs 1 pass).
  void passWord() {
    if (state.passes <= 0 || state.status != GameStatus.playing) return;

    pauseTimer();

    final newSkipped = Set<int>.from(state.skippedIndices)
      ..add(state.currentWordIndex);

    state = state.copyWith(
      passes: state.passes - 1,
      passesUsed: state.passesUsed + 1,
      skippedIndices: newSkipped,
      feedback: const FeedbackEvent(
        type: FeedbackType.passed,
        message: 'Word skipped!',
      ),
    );

    // Check if any words remain
    if (!state.hasWordsRemaining) {
      _endGame(EndReason.allWordsCleared);
      return;
    }
  }

  /// Surrender the championship.
  void surrender() {
    _endGame(EndReason.surrendered);
  }

  void _advanceToNextWord() {
    var nextIndex = state.currentWordIndex;

    // If we haven't submitted/passed the current word yet and it's the first call
    if (state.status == GameStatus.playing || state.status == GameStatus.paused) {
      nextIndex = state.currentWordIndex + 1;
    }

    // Find next non-skipped word
    while (nextIndex < state.wordBank.length &&
        state.skippedIndices.contains(nextIndex)) {
      nextIndex++;
    }

    if (nextIndex >= state.wordBank.length) {
      // Check if there are any non-skipped words before current
      // (shouldn't happen since we only skip forward, but safety check)
      _endGame(EndReason.allWordsCleared);
      return;
    }

    state = state.copyWith(currentWordIndex: nextIndex);
  }

  void _endGame(EndReason reason) {
    _timer?.cancel();
    state = state.copyWith(
      status: GameStatus.ended,
      endReason: reason,
      feedback: null,
    );

    // In offline mode, do NOT auto-submit — the upload screen handles it.
    // In normal mode, save immediately as before.
    if (!state.offlineMode) {
      _saveResult();
    }
  }

  Future<void> _saveResult() async {
    final result = Result(
      id: '',
      studentId: state.studentId,
      studentName: state.studentName,
      grade: state.grade,
      finalScore: state.score,
      correctAnswers: state.correctCount,
      wrongAnswers: state.wrongCount,
      passesUsed: state.passesUsed,
      timeRemainingSeconds: state.timeRemainingSeconds,
      accuracy: state.accuracy,
      createdAt: DateTime.now(),
    );

    try {
      await apiService.submitResult(result);
      state = state.copyWith(resultSubmitted: true);
    } catch (e) {
      print('Failed to save result: $e');
    }
  }

  /// Manually submit the result (for offline mode upload screen).
  Future<void> submitResultManually() async {
    final result = Result(
      id: '',
      studentId: state.studentId,
      studentName: state.studentName,
      grade: state.grade,
      finalScore: state.score,
      correctAnswers: state.correctCount,
      wrongAnswers: state.wrongCount,
      passesUsed: state.passesUsed,
      timeRemainingSeconds: state.timeRemainingSeconds,
      accuracy: state.accuracy,
      createdAt: DateTime.now(),
    );

    if (state.offlineMode && state.gameToken != null) {
      await apiService.submitOfflineResult(result, state.gameToken!);
    } else {
      await apiService.submitResult(result);
    }

    state = state.copyWith(resultSubmitted: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Provider ────────────────────────────────────────────────────────

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});
