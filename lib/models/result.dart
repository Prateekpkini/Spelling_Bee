

class Result {
  final String id;
  final String studentId;
  final String studentName;
  final String grade;
  final int finalScore;
  final int correctAnswers;
  final int wrongAnswers;
  final int passesUsed;
  final int timeRemainingSeconds;
  final int timeTakenSeconds;
  final double accuracy;
  final DateTime createdAt;

  const Result({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.finalScore,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.passesUsed,
    required this.timeRemainingSeconds,
    this.timeTakenSeconds = 0,
    required this.accuracy,
    required this.createdAt,
  });

  factory Result.fromJson(Map<String, dynamic> data) {
    return Result(
      id: data['id']?.toString() ?? '',
      studentId: data['student_id']?.toString() ?? '',
      studentName: data['student_name'] ?? '',
      grade: data['grade'] ?? '',
      finalScore: (data['final_score'] ?? 0).toInt(),
      correctAnswers: (data['correct_answers'] ?? 0).toInt(),
      wrongAnswers: (data['wrong_answers'] ?? 0).toInt(),
      passesUsed: (data['passes_used'] ?? 0).toInt(),
      timeRemainingSeconds: (data['time_remaining_seconds'] ?? 0).toInt(),
      timeTakenSeconds: (data['time_taken_seconds'] ?? 0).toInt(),
      accuracy: double.tryParse(data['accuracy']?.toString() ?? '0') ?? 0.0,
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'grade': grade,
      'final_score': finalScore,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'passes_used': passesUsed,
      'time_remaining_seconds': timeRemainingSeconds,
      'time_taken_seconds': timeTakenSeconds,
      'accuracy': accuracy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Leaderboard comparison:
  /// Higher Score -> Higher Correct -> Fewer Wrong -> More Time Remaining
  static int leaderboardCompare(Result a, Result b) {
    if (a.finalScore != b.finalScore) return b.finalScore.compareTo(a.finalScore);
    if (a.correctAnswers != b.correctAnswers) return b.correctAnswers.compareTo(a.correctAnswers);
    if (a.wrongAnswers != b.wrongAnswers) return a.wrongAnswers.compareTo(b.wrongAnswers);
    return b.timeRemainingSeconds.compareTo(a.timeRemainingSeconds);
  }
}
