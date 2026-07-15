import 'package:uuid/uuid.dart';
import 'package:spelling_bee/services/firestore_service.dart';
import 'package:spelling_bee/models/student.dart';

enum TokenStatus { valid, used, notFound }

class TokenValidationResult {
  final TokenStatus status;
  final Student? student;

  const TokenValidationResult({required this.status, this.student});
}

/// Manages token generation and lifecycle validation.
class TokenService {
  static const _uuid = Uuid();
  final FirestoreService _firestoreService;

  TokenService(this._firestoreService);

  /// Generates a cryptographically unique token string.
  String generateToken() {
    return _uuid.v4().replaceAll('-', '');
  }

  /// Validates a token against Firestore without modifying its status.
  Future<TokenValidationResult> validateToken(String token) async {
    final student = await _firestoreService.getStudentByToken(token);

    if (student == null) {
      return const TokenValidationResult(status: TokenStatus.notFound);
    }

    if (student.tokenStatus == 'used') {
      return TokenValidationResult(status: TokenStatus.used, student: student);
    }

    return TokenValidationResult(status: TokenStatus.valid, student: student);
  }

  /// Marks a token as permanently used. Called only on "Start Championship" tap.
  Future<void> markTokenUsed(String studentId) async {
    await _firestoreService.markTokenUsed(studentId);
  }
}
