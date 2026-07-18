import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/services/api_service.dart';

// We define a DTO structure for registration payload since we don't need a full Student object upfront
class RegisterStudentPayload {
  final String name;
  final String grade;
  final String? section;
  final String? schoolName;
  final String? schoolAddress;
  final String? city;
  final String? district;
  final String? state;
  final String? parentMobile;

  RegisterStudentPayload({
    required this.name,
    required this.grade,
    this.section,
    this.schoolName,
    this.schoolAddress,
    this.city,
    this.district,
    this.state,
    this.parentMobile,
  });
}

/// Provider for registering a new student and returning the generated token.
final registerStudentProvider = FutureProvider.family<String, RegisterStudentPayload>((ref, payload) async {
  final result = await apiService.registerStudent(
    name: payload.name,
    grade: payload.grade,
    section: payload.section,
    schoolName: payload.schoolName,
    schoolAddress: payload.schoolAddress,
    city: payload.city,
    district: payload.district,
    state: payload.state,
    parentMobile: payload.parentMobile,
  );
  return result['token'] as String;
});
