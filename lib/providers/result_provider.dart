import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/providers/student_provider.dart';

/// Real-time stream of all results sorted by leaderboard ranking.
final resultsStreamProvider = StreamProvider<List<Result>>((ref) {
  return ref.watch(firestoreServiceProvider).resultsStream();
});

/// One-shot fetch of all results for export.
final resultsExportProvider = FutureProvider<List<Result>>((ref) async {
  return ref.watch(firestoreServiceProvider).getResults();
});
