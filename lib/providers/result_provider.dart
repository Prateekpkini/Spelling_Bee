import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/services/api_service.dart';

/// Provider for fetching leaderboard results (authenticated).
/// Pass a grade string to filter, or null for all grades.
final resultsProvider = FutureProvider.family<List<Result>, String?>((ref, grade) async {
  return await apiService.getLeaderboard(grade: grade);
});

/// Provider for fetching public leaderboard results (no auth).
/// Pass a grade string to filter, or null for all grades.
final publicResultsProvider = FutureProvider.family<List<Result>, String?>((ref, grade) async {
  return await apiService.getPublicLeaderboard(grade: grade);
});
