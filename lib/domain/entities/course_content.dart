class CourseContent {
  final String title;
  final String language;
  final List<CourseLevelContent> levels;

  const CourseContent({
    required this.title,
    required this.language,
    required this.levels,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map? ?? const {};
    return CourseContent(
      title: course['title']?.toString() ?? '',
      language: course['language']?.toString() ?? '',
      levels: (course['levels'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CourseLevelContent.fromJson)
          .toList(),
    );
  }
}

class CourseLevelContent {
  final String title;
  final List<CourseLectureContent> lectures;

  const CourseLevelContent({required this.title, required this.lectures});

  factory CourseLevelContent.fromJson(Map<String, dynamic> json) {
    return CourseLevelContent(
      title: json['title']?.toString() ?? '',
      lectures: (json['lectures'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CourseLectureContent.fromJson)
          .toList(),
    );
  }
}

class CourseLectureContent {
  final String title;
  final List<CoursePartContent> parts;

  const CourseLectureContent({required this.title, required this.parts});

  factory CourseLectureContent.fromJson(Map<String, dynamic> json) {
    return CourseLectureContent(
      title: json['title']?.toString() ?? '',
      parts: (json['parts'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CoursePartContent.fromJson)
          .toList(),
    );
  }
}

class CoursePartContent {
  final String title;
  final String vimeoUrl;
  final String duration;

  const CoursePartContent({
    required this.title,
    required this.vimeoUrl,
    required this.duration,
  });

  factory CoursePartContent.fromJson(Map<String, dynamic> json) {
    return CoursePartContent(
      title: json['title']?.toString() ?? '',
      vimeoUrl: json['vimeoUrl']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}
