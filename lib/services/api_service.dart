import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:spelling_bee/models/examiner.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/models/word.dart';

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) {
      final host = html.window.location.hostname ?? 'localhost';
      return 'http://$host:3000/api';
    }
    return 'http://10.86.6.243:3000/api';
  }

  String? _jwtToken;

  void setToken(String token) {
    _jwtToken = token;
  }

  void clearToken() {
    _jwtToken = null;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
    };
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  // --- Admin ---

  Future<void> createTeacher(String name, String? school, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/teachers'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'school': school,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to create teacher';
      throw Exception(error);
    }
  }

  Future<List<Examiner>> getTeachers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/teachers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['teachers'];
      return data.map((e) => Examiner.fromJson(e)).toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to fetch teachers';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/settings'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['settings'];
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to fetch settings';
      throw Exception(error);
    }
  }

  Future<void> updateSettings(int timerSeconds, int initialShields, int initialPasses) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/settings'),
      headers: _headers,
      body: jsonEncode({
        'timer_seconds': timerSeconds,
        'initial_shields': initialShields,
        'initial_passes': initialPasses,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to update settings';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> uploadWords(String grade, List<int> fileBytes, String fileName) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/admin/words/upload'));
    request.headers.addAll({
      if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
    });
    
    request.fields['grade'] = grade;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to upload words';
      throw Exception(error);
    }
  }

  // --- Examiner ---

  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String grade,
    String? section,
    String? schoolName,
    String? schoolAddress,
    String? city,
    String? district,
    String? state,
    String? parentMobile,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/examiner/students'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'grade': grade,
        'section': section,
        'school_name': schoolName,
        'school_address': schoolAddress,
        'city': city,
        'district': district,
        'state': state,
        'parent_mobile': parentMobile,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to register student';
      throw Exception(error);
    }
  }

  Future<List<Result>> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/leaderboard'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['results'];
      return data.map((e) => Result.fromJson(e)).toList();
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to fetch leaderboard';
      throw Exception(error);
    }
  }

  // --- Game ---

  Future<Map<String, dynamic>> validateToken(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/game/validate/$token'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to validate token';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> startGame(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/game/start/$token'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to start game';
      throw Exception(error);
    }
  }

  Future<void> submitResult(Result result) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/game/submit'),
      headers: _headers,
      body: jsonEncode({
        'student_id': result.studentId, // Note: result might not have studentId if we didn't store it, we might need to adjust
        'student_name': result.studentName,
        'grade': result.grade,
        'final_score': result.finalScore,
        'correct_answers': result.correctAnswers,
        'wrong_answers': result.wrongAnswers,
        'passes_used': result.passesUsed,
        'time_remaining_seconds': result.timeRemainingSeconds,
        'accuracy': result.accuracy,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to submit result';
      throw Exception(error);
    }
  }
}

// Global instance for now, can be provided via Riverpod later
final apiService = ApiService();
