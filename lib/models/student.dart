import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String grade;
  final String section;
  final String schoolName;
  final String schoolAddress;
  final String city;
  final String district;
  final String state;
  final String parentMobile;
  final String token;
  final String tokenStatus; // 'active' | 'used'

  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.schoolName,
    required this.schoolAddress,
    required this.city,
    required this.district,
    required this.state,
    required this.parentMobile,
    required this.token,
    this.tokenStatus = 'active',
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['name'] ?? '',
      grade: data['grade'] ?? '',
      section: data['section'] ?? '',
      schoolName: data['school_name'] ?? '',
      schoolAddress: data['school_address'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      parentMobile: data['parent_mobile'] ?? '',
      token: data['token'] ?? '',
      tokenStatus: data['token_status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'grade': grade,
      'section': section,
      'school_name': schoolName,
      'school_address': schoolAddress,
      'city': city,
      'district': district,
      'state': state,
      'parent_mobile': parentMobile,
      'token': token,
      'token_status': tokenStatus,
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? grade,
    String? section,
    String? schoolName,
    String? schoolAddress,
    String? city,
    String? district,
    String? state,
    String? parentMobile,
    String? token,
    String? tokenStatus,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      schoolName: schoolName ?? this.schoolName,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      parentMobile: parentMobile ?? this.parentMobile,
      token: token ?? this.token,
      tokenStatus: tokenStatus ?? this.tokenStatus,
    );
  }
}
