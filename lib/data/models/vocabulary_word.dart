class VocabularyWord {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String example;
  final String languageCode;
  final String course;
  final String courseLanguage;
  final String level;
  final String lesson;
  final String translation;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.example,
    this.languageCode = 'en',
    this.course = '',
    this.courseLanguage = '',
    this.level = '',
    this.lesson = '',
    this.translation = '',
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? 'en',
      course: json['course']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      lesson: json['lesson']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'example': example,
      'languageCode': languageCode,
      'course': course,
      'courseLanguage': courseLanguage,
      'level': level,
      'lesson': lesson,
      'translation': translation,
    };
  }
}
