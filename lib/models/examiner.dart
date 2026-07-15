import 'package:cloud_firestore/cloud_firestore.dart';

class Examiner {
  final String uid;
  final String username;
  final String email;

  const Examiner({
    required this.uid,
    required this.username,
    required this.email,
  });

  factory Examiner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Examiner(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
    };
  }
}
