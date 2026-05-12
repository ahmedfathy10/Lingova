import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_content.dart';
import '../services/auth_http_client.dart';

class CourseApiDataSource {
  Future<List<Course>> getCourses() async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/courses'),
    );
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الكورسات.');
    }

    final json = _readJson(response.body);
    final courses = json['courses'] as List? ?? const [];
    return courses
        .whereType<Map<String, dynamic>>()
        .map(_courseFromJson)
        .toList();
  }

  Future<CourseContent> getCourseContent({
    required String studentId,
    required Course course,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/course-content').replace(
      queryParameters: {
        'studentId': studentId,
        'courseTitle': course.title,
        'courseLanguage': course.language,
      },
    );
    final response = await getJson(uri);
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل محتوى الكورس.');
    }

    return CourseContent.fromJson(_readJson(response.body));
  }

  Future<List<Course>> getEnglishCourses() async {
    final courses = await getCourses();
    return courses.where((course) => course.language == 'الإنجليزية').toList();
  }

  Future<List<Course>> getGermanCourses() async {
    final courses = await getCourses();
    return courses.where((course) => course.language == 'الألمانية').toList();
  }

  Course _courseFromJson(Map<String, dynamic> json) {
    final language = json['language']?.toString() ?? '';
    final levelBadge = json['levelBadge']?.toString() ?? 'Course';
    return Course(
      title: json['title']?.toString() ?? '',
      level: json['level']?.toString() ?? levelBadge,
      price: json['price']?.toString() ?? 'مجانا',
      levelBadge: levelBadge,
      icon: _iconFor(language),
      language: language,
      lessonsCount: json['lessonsCount']?.toString() ?? '0 درس',
      duration: json['duration']?.toString() ?? '-',
      description: json['description']?.toString() ?? '',
      imageDataUrl: json['imageDataUrl']?.toString() ?? '',
      learningOutcomes: (json['learningOutcomes'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }

  IconData _iconFor(String language) {
    if (language == 'الألمانية') {
      return Icons.flag_rounded;
    }
    return Icons.language_rounded;
  }
}

Map<String, dynamic> _readJson(String body) {
  try {
    return Map<String, dynamic>.from(const JsonDecoder().convert(body) as Map);
  } catch (_) {
    return const {};
  }
}
