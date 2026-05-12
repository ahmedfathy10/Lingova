class ExamQuestion {
  final String id;
  final String type;
  final String prompt;
  final List<String> options;
  final List<String> correctAnswers;

  const ExamQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswers,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id']?.toString() ?? '',
      type: normalizeQuestionType(json['type']?.toString()),
      prompt: json['prompt']?.toString() ?? '',
      options: (json['options'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      correctAnswers: (json['correctAnswers'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'prompt': prompt,
      'options': options,
      'correctAnswers': correctAnswers,
    };
  }
}

String normalizeQuestionType(String? type) {
  switch (type) {
    case 'multiple_choice':
    case 'single_choice':
      return 'mcq';
    case 'true_false':
    case 'complete':
    case 'audio':
    case 'video':
      return type!;
    default:
      return 'mcq';
  }
}

class CourseExam {
  final String id;
  final String title;
  final String description;
  final String type;
  final String courseTitle;
  final String courseLanguage;
  final String levelTitle;
  final int afterLectureIndex;
  final int passScore;
  final int durationMinutes;
  final List<ExamQuestion> questions;

  const CourseExam({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.courseTitle,
    required this.courseLanguage,
    required this.levelTitle,
    required this.afterLectureIndex,
    required this.passScore,
    required this.durationMinutes,
    required this.questions,
  });

  factory CourseExam.fromJson(Map<String, dynamic> json) {
    return CourseExam(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'lecture_quiz',
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      levelTitle: json['levelTitle']?.toString() ?? '',
      afterLectureIndex:
          int.tryParse(json['afterLectureIndex']?.toString() ?? '') ?? 0,
      passScore: int.tryParse(json['passScore']?.toString() ?? '') ?? 60,
      durationMinutes:
          int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 10,
      questions: (json['questions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExamQuestion.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'courseTitle': courseTitle,
      'courseLanguage': courseLanguage,
      'levelTitle': levelTitle,
      'afterLectureIndex': afterLectureIndex,
      'passScore': passScore,
      'durationMinutes': durationMinutes,
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

  String get typeLabel => type == 'level_final' ? 'نهاية مستوى' : 'كويز';
}

class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final String courseTitle;
  final String courseLanguage;
  final String levelTitle;
  final String type;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final bool passed;
  final String submittedAt;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.courseTitle,
    required this.courseLanguage,
    required this.levelTitle,
    required this.type,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.passed,
    required this.submittedAt,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      levelTitle: json['levelTitle']?.toString() ?? '',
      type: json['type']?.toString() ?? 'lecture_quiz',
      score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
      totalQuestions:
          int.tryParse(json['totalQuestions']?.toString() ?? '') ?? 0,
      correctAnswers:
          int.tryParse(json['correctAnswers']?.toString() ?? '') ?? 0,
      passed: json['passed'] == true,
      submittedAt: json['submittedAt']?.toString() ?? '',
    );
  }

  String get statusLabel => passed ? 'ناجح' : 'لم ينجح';

  String get typeLabel => type == 'level_final' ? 'نهاية مستوى' : 'كويز';

  String get submittedAtLabel {
    final parsed = DateTime.tryParse(submittedAt)?.toLocal();
    if (parsed == null) {
      return '';
    }
    final date =
        '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    final time =
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class ExamReportSummary {
  final int attemptsCount;
  final int passedCount;
  final int failedCount;
  final int averageScore;

  const ExamReportSummary({
    required this.attemptsCount,
    required this.passedCount,
    required this.failedCount,
    required this.averageScore,
  });

  factory ExamReportSummary.fromJson(Map<String, dynamic> json) {
    return ExamReportSummary(
      attemptsCount: int.tryParse(json['attemptsCount']?.toString() ?? '') ?? 0,
      passedCount: int.tryParse(json['passedCount']?.toString() ?? '') ?? 0,
      failedCount: int.tryParse(json['failedCount']?.toString() ?? '') ?? 0,
      averageScore: int.tryParse(json['averageScore']?.toString() ?? '') ?? 0,
    );
  }
}

class ExamReport {
  final ExamReportSummary summary;
  final List<ExamResult> results;

  const ExamReport({required this.summary, required this.results});

  factory ExamReport.fromJson(Map<String, dynamic> json) {
    final summaryJson =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final results = json['results'] as List? ?? const [];
    return ExamReport(
      summary: ExamReportSummary.fromJson(summaryJson),
      results: results
          .whereType<Map<String, dynamic>>()
          .map(ExamResult.fromJson)
          .toList(),
    );
  }
}

class StudentExamBundle {
  final List<CourseExam> exams;
  final List<ExamResult> results;

  const StudentExamBundle({required this.exams, required this.results});
}
