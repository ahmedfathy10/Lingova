import '../data/models/admin_course_part.dart';
import '../data/models/vocabulary_word.dart';

class VocabularyCourseRef {
  final String language;
  final String course;

  const VocabularyCourseRef({required this.language, required this.course});

  String get key => '${language.trim()}|${course.trim()}';

  String get label => course.trim().isEmpty ? language : course.trim();
}

class VocabularyHierarchy {
  static List<VocabularyCourseRef> coursesFromData({
    required List<AdminCoursePart> parts,
    required List<VocabularyWord> words,
  }) {
    final map = <String, VocabularyCourseRef>{};
    for (final part in parts) {
      if (part.language.trim().isEmpty || part.course.trim().isEmpty) {
        continue;
      }
      final ref = VocabularyCourseRef(
        language: part.language.trim(),
        course: part.course.trim(),
      );
      map[ref.key] = ref;
    }
    for (final word in words) {
      if (word.courseLanguage.trim().isEmpty || word.course.trim().isEmpty) {
        continue;
      }
      final ref = VocabularyCourseRef(
        language: word.courseLanguage.trim(),
        course: word.course.trim(),
      );
      map[ref.key] = ref;
    }
    return map.values.toList()..sort((a, b) => a.label.compareTo(b.label));
  }

  static List<String> levelsForCourse({
    required List<AdminCoursePart> parts,
    required List<VocabularyWord> words,
    required VocabularyCourseRef course,
  }) {
    final values = <String>{};
    for (final part in parts) {
      if (!_matchesCourse(part, course)) continue;
      if (part.level.trim().isNotEmpty) {
        values.add(part.level.trim());
      }
    }
    for (final word in words) {
      if (!_matchesCourseWord(word, course)) continue;
      if (word.level.trim().isNotEmpty) {
        values.add(word.level.trim());
      }
    }
    final list = values.toList()..sort();
    return list;
  }

  static List<String> lessonsForLevel({
    required List<AdminCoursePart> parts,
    required List<VocabularyWord> words,
    required VocabularyCourseRef course,
    required String level,
  }) {
    final values = <String>{};
    for (final part in parts) {
      if (!_matchesCourse(part, course)) continue;
      if (part.level.trim() != level.trim()) continue;
      if (part.lecture.trim().isNotEmpty) {
        values.add(part.lecture.trim());
      }
    }
    for (final word in words) {
      if (!_matchesCourseWord(word, course)) continue;
      if (word.level.trim() != level.trim()) continue;
      if (word.lesson.trim().isNotEmpty) {
        values.add(word.lesson.trim());
      }
    }
    final list = values.toList()..sort();
    return list;
  }

  static List<VocabularyWord> wordsForLesson({
    required List<VocabularyWord> words,
    required VocabularyCourseRef course,
    required String level,
    required String lesson,
  }) {
    return words
        .where(
          (word) =>
              _matchesCourseWord(word, course) &&
              word.level.trim() == level.trim() &&
              word.lesson.trim() == lesson.trim(),
        )
        .toList()
      ..sort((a, b) => a.word.compareTo(b.word));
  }

  static int wordCountForCourse(
    List<VocabularyWord> words,
    VocabularyCourseRef course,
  ) {
    return words.where((word) => _matchesCourseWord(word, course)).length;
  }

  static int wordCountForLevel(
    List<VocabularyWord> words,
    VocabularyCourseRef course,
    String level,
  ) {
    return words
        .where(
          (word) =>
              _matchesCourseWord(word, course) &&
              word.level.trim() == level.trim(),
        )
        .length;
  }

  static int wordCountForLesson(
    List<VocabularyWord> words,
    VocabularyCourseRef course,
    String level,
    String lesson,
  ) {
    return wordsForLesson(
      words: words,
      course: course,
      level: level,
      lesson: lesson,
    ).length;
  }

  static bool _matchesCourse(AdminCoursePart part, VocabularyCourseRef course) {
    return part.language.trim() == course.language &&
        part.course.trim() == course.course;
  }

  static bool _matchesCourseWord(VocabularyWord word, VocabularyCourseRef course) {
    return word.courseLanguage.trim() == course.language &&
        word.course.trim() == course.course;
  }
}
