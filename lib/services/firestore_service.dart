import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/models/word.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:uuid/uuid.dart';

// Only import dart:html conditionally so it compiles on Android too
import 'package:universal_html/html.dart' as html;

/// Mocked FirestoreService using HTML local storage for persistence across reloads
class FirestoreService {
  List<Student> _students = [];
  final List<Result> _results = [];
  
  final List<Word> _words = [
    const Word(
      id: '1', grade: '1', spellingBritish: 'colour', spellingAmerican: 'color',
      partOfSpeech: 'noun', meaning: 'The property possessed by an object of producing different sensations on the eye.', jumbledLetters: 'oulroc',
    ),
    const Word(
      id: '2', grade: '1', spellingBritish: 'centre', spellingAmerican: 'center',
      partOfSpeech: 'noun', meaning: 'The middle point of a circle or sphere.', jumbledLetters: 'etncer',
    ),
    const Word(
      id: '3', grade: '1', spellingBritish: 'flavour', spellingAmerican: 'flavor',
      partOfSpeech: 'noun', meaning: 'The distinctive taste of a food or drink.', jumbledLetters: 'vraoufl',
    ),
  ];

  final _studentsController = StreamController<List<Student>>.broadcast();
  final _resultsController = StreamController<List<Result>>.broadcast();

  FirestoreService() {
    _loadFromStorage();
    _studentsController.add(_students);
    _resultsController.add(_results);
  }

  void _loadFromStorage() {
    if (kIsWeb) {
      final data = html.window.localStorage['mock_students'];
      if (data != null) {
        try {
          final List<dynamic> decoded = jsonDecode(data);
          _students = decoded.map((e) => Student(
            id: e['id'], name: e['name'], grade: e['grade'],
            section: e['section'], schoolName: e['school_name'],
            schoolAddress: e['school_address'], city: e['city'],
            district: e['district'], state: e['state'],
            parentMobile: e['parent_mobile'], token: e['token'],
            tokenStatus: e['token_status'],
          )).toList();
        } catch (_) {}
      }
    }
  }

  void _saveToStorage() {
    if (kIsWeb) {
      final data = jsonEncode(_students.map((e) => e.toFirestore()).toList());
      html.window.localStorage['mock_students'] = data;
    }
  }

  Future<String> addStudent(Student student) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = const Uuid().v4();
    final newStudent = student.copyWith(id: id);
    _students.add(newStudent);
    _saveToStorage();
    _studentsController.add(_students);
    return id;
  }

  Future<Student?> getStudentByToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _students.firstWhere((s) => s.token == token);
    } catch (e) {
      return null;
    }
  }

  Future<void> markTokenUsed(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _students[index] = _students[index].copyWith(tokenStatus: 'used');
      _saveToStorage();
      _studentsController.add(_students);
    }
  }

  Stream<List<Student>> studentsStream() => _studentsController.stream;

  Future<List<Word>> getWordsByGrade(String grade) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final filtered = _words.where((w) => w.grade == grade).toList();
    filtered.shuffle();
    return filtered;
  }

  Future<void> saveResult(Result result) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _results.add(result);
    _results.sort(Result.leaderboardCompare);
    _resultsController.add(_results);
  }

  Stream<List<Result>> resultsStream() => _resultsController.stream;
  Future<List<Result>> getResults() async => List.from(_results);
}
