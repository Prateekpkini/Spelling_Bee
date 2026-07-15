import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.accuracy,
    required this.createdAt,
  });

  factory Result.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Result(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      studentName: data['student_name'] ?? '',
      grade: data['grade'] ?? '',
      finalScore: data['final_score'] ?? 0,
      correctAnswers: data['correct_answers'] ?? 0,
      wrongAnswers: data['wrong_answers'] ?? 0,
      passesUsed: data['passes_used'] ?? 0,
      timeRemainingSeconds: data['time_remaining_seconds'] ?? 0,
      accuracy: (data['accuracy'] ?? 0).toDouble(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'grade': grade,
      'final_score': finalScore,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'passes_used': passesUsed,
      'time_remaining_seconds': timeRemainingSeconds,
      'accuracy': accuracy,
      'created_at': FieldValue.serverTimestamp(),
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
