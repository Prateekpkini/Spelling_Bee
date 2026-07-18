import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/services/api_service.dart';

/// Provider for fetching all results for the leaderboard and export.
final resultsProvider = FutureProvider<List<Result>>((ref) async {
  return await apiService.getLeaderboard();
});
