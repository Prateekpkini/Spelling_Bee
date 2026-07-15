import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/services/firestore_service.dart';
import 'package:spelling_bee/services/token_service.dart';

/// Singleton FirestoreService provider.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Singleton TokenService provider.
final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(ref.watch(firestoreServiceProvider));
});

/// Stream of all students.
final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(firestoreServiceProvider).studentsStream();
});

/// Provider for registering a new student and returning the generated token.
final registerStudentProvider = FutureProvider.family<String, Student>((ref, student) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  await firestoreService.addStudent(student);
  return student.token;
});
