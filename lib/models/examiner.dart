

class Examiner {
  final String uid;
  final String username;
  final String email;

  final String? school;

  const Examiner({
    required this.uid,
    required this.username,
    required this.email,
    this.school,
  });

  factory Examiner.fromJson(Map<String, dynamic> data) {
    return Examiner(
      uid: data['id']?.toString() ?? '',
      username: data['name'] ?? '',
      email: data['email'] ?? '',
      school: data['school'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'name': username,
      'email': email,
      'school': school,
    };
  }
}
