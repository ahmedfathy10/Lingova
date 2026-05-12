class CourseQuestion {
  final String id;
  final String studentId;
  final String studentName;
  final String courseTitle;
  final String courseLanguage;
  final String levelTitle;
  final String lectureTitle;
  final String partTitle;
  final String vimeoUrl;
  final String question;
  final String answer;
  final String status;
  final String createdAt;
  final String answeredAt;
  final String answeredBy;

  const CourseQuestion({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseTitle,
    required this.courseLanguage,
    required this.levelTitle,
    required this.lectureTitle,
    required this.partTitle,
    required this.vimeoUrl,
    required this.question,
    required this.answer,
    required this.status,
    required this.createdAt,
    required this.answeredAt,
    required this.answeredBy,
  });

  factory CourseQuestion.fromJson(Map<String, dynamic> json) {
    return CourseQuestion(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      levelTitle: json['levelTitle']?.toString() ?? '',
      lectureTitle: json['lectureTitle']?.toString() ?? '',
      partTitle: json['partTitle']?.toString() ?? '',
      vimeoUrl: json['vimeoUrl']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
      answeredAt: json['answeredAt']?.toString() ?? '',
      answeredBy: json['answeredBy']?.toString() ?? '',
    );
  }

  bool get isAnswered => status == 'answered' && answer.trim().isNotEmpty;
}
