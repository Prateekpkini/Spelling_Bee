import 'package:cloud_firestore/cloud_firestore.dart';

class Word {
  final String id;
  final String grade;
  final String spellingBritish;
  final String spellingAmerican;
  final String partOfSpeech;
  final String meaning;
  final String jumbledLetters;

  const Word({
    required this.id,
    required this.grade,
    required this.spellingBritish,
    required this.spellingAmerican,
    required this.partOfSpeech,
    required this.meaning,
    required this.jumbledLetters,
  });

  factory Word.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Word(
      id: doc.id,
      grade: data['grade'] ?? '',
      spellingBritish: data['spelling_british'] ?? '',
      spellingAmerican: data['spelling_american'] ?? '',
      partOfSpeech: data['part_of_speech'] ?? '',
      meaning: data['meaning'] ?? '',
      jumbledLetters: data['jumbled_letters'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'grade': grade,
      'spelling_british': spellingBritish,
      'spelling_american': spellingAmerican,
      'part_of_speech': partOfSpeech,
      'meaning': meaning,
      'jumbled_letters': jumbledLetters,
    };
  }
}
