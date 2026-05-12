import 'dart:convert';

import '../../core/api_config.dart';
import '../models/course_question.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class QuestionApiService {
  Future<List<CourseQuestion>> getStudentQuestions({
    required String studentId,
    required String courseTitle,
    required String courseLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/questions').replace(
      queryParameters: {
        'studentId': studentId,
        'courseTitle': courseTitle,
        'courseLanguage': courseLanguage,
      },
    );
    final response = await getJson(uri);
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final questions = json['questions'] as List? ?? const [];
      return questions
          .whereType<Map<String, dynamic>>()
          .map(CourseQuestion.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<CourseQuestion> createQuestion(Map<String, dynamic> question) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/questions'),
      question,
    );
    final json = _readJson(response.body);
    if (response.statusCode == 201) {
      return CourseQuestion.fromJson(
        Map<String, dynamic>.from(json['question'] as Map? ?? const {}),
      );
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Map<String, dynamic> _readJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  String _readMessage(Map<String, dynamic> json, int statusCode) {
    final message = json['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return 'حدث خطأ غير متوقع.';
  }
}
