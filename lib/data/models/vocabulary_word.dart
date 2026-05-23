class VocabularyWord {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String example;
  final String languageCode;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.example,
    this.languageCode = 'en',
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'example': example,
      'languageCode': languageCode,
    };
  }
}
