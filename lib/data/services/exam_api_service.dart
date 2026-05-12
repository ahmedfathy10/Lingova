import 'dart:convert';

import '../../core/api_config.dart';
import '../models/exam.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class ExamApiService {
  Future<List<CourseExam>> getAdminExams(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/exams'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final exams = json['exams'] as List? ?? const [];
      return exams
          .whereType<Map<String, dynamic>>()
          .map(CourseExam.fromJson)
          .toList();
    }
    throw AuthApiException(_message(json));
  }

  Future<ExamReport> getAdminExamReport(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/exam-results'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return ExamReport.fromJson(json);
    }
    throw AuthApiException(_message(json));
  }

  Future<void> createExam(String token, Map<String, dynamic> exam) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/exams'),
      exam,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 201) {
      return;
    }
    throw AuthApiException(_message(_readJson(response.body)));
  }

  Future<void> deleteExam(String token, String examId) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/exams/$examId/delete'),
      const {},
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(_message(_readJson(response.body)));
  }

  Future<void> updateExamQuestions(
    String token,
    String examId,
    List<ExamQuestion> questions,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/exams/$examId/questions'),
      {'questions': questions.map((question) => question.toJson()).toList()},
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(_message(_readJson(response.body)));
  }

  Future<StudentExamBundle> getStudentExams(String studentId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/exams',
    ).replace(queryParameters: {'studentId': studentId});
    final response = await getJson(uri);
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final exams = json['exams'] as List? ?? const [];
      final results = json['results'] as List? ?? const [];
      return StudentExamBundle(
        exams: exams
            .whereType<Map<String, dynamic>>()
            .map(CourseExam.fromJson)
            .toList(),
        results: results
            .whereType<Map<String, dynamic>>()
            .map(ExamResult.fromJson)
            .toList(),
      );
    }
    throw AuthApiException(_message(json));
  }

  Future<ExamResult> submitExam({
    required String studentId,
    required String examId,
    required Map<String, dynamic> answers,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/exams/$examId/submit'),
      {'studentId': studentId, 'answers': answers},
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return ExamResult.fromJson(
        (json['result'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
    }
    throw AuthApiException(_message(json));
  }

  Map<String, dynamic> _readJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  String _message(Map<String, dynamic> json) {
    return json['message']?.toString() ?? 'حدث خطأ غير متوقع.';
  }
}
