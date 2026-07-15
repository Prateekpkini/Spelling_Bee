import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/word.dart';
import 'package:spelling_bee/providers/student_provider.dart';

/// Fetches the entire word bank for a given grade (shuffled).
final wordBankProvider = FutureProvider.family<List<Word>, String>((ref, grade) async {
  return ref.watch(firestoreServiceProvider).getWordsByGrade(grade);
});
