import 'dart:convert';

import '../../core/api_config.dart';
import '../../domain/entities/course_content.dart';
import '../models/watch_progress_record.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class WatchProgressApiService {
  Future<List<WatchProgressRecord>> getCourseProgress({
    required String studentId,
    required String courseTitle,
    required String courseLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/watch-progress').replace(
      queryParameters: {
        'studentId': studentId,
        'courseTitle': courseTitle,
        'courseLanguage': courseLanguage,
      },
    );
    final response = await getJson(uri);
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final records = json['records'] as List? ?? const [];
      return records
          .whereType<Map<String, dynamic>>()
          .map(WatchProgressRecord.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<void> completePart({
    required String studentId,
    required CourseContent content,
    required CourseLevelContent level,
    required CourseLectureContent lecture,
    required CoursePartContent part,
  }) async {
    final response =
        await postJson(Uri.parse('${ApiConfig.baseUrl}/api/watch-progress'), {
          'studentId': studentId,
          'courseTitle': content.title,
          'courseLanguage': content.language,
          'levelTitle': level.title,
          'lectureTitle': lecture.title,
          'partTitle': part.title,
          'vimeoUrl': part.vimeoUrl,
          'duration': part.duration,
        });
    if (response.statusCode == 200) {
      return;
    }

    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<WatchReport> getAdminWatchReport({
    required String token,
    required DateTime date,
  }) async {
    final dateText =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/watch-report',
    ).replace(queryParameters: {'date': dateText});
    final response = await getJson(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return WatchReport.fromJson(json);
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
    return statusCode == 401
        ? 'انتهت جلسة الأدمن. سجل الدخول مرة أخرى.'
        : 'حدث خطأ غير متوقع.';
  }
}
