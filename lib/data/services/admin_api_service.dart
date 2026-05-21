import 'dart:convert';

import '../../core/api_config.dart';
import '../models/admin_app_notification.dart';
import '../models/admin_book.dart';
import '../models/admin_course_part.dart';
import '../models/admin_subscription_request.dart';
import '../models/admin_user.dart';
import '../models/course_question.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class AdminSession {
  final String token;
  final String name;

  const AdminSession({required this.token, required this.name});
}

class AdminApiService {
  Future<AdminSession> login({
    required String email,
    required String password,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/login'),
      {'email': email, 'password': password},
    );

    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return AdminSession(
        token: json['token']?.toString() ?? '',
        name: (json['admin'] as Map?)?['name']?.toString() ?? 'Admin',
      );
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<AdminStats> getStats(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/stats'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return AdminStats.fromJson(json);
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<List<AdminUser>> getUsers(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/users'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final users = json['users'] as List? ?? const [];
      return users
          .whereType<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<List<AdminActivityLog>> getActivityLogs(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/activity-logs'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final logs = json['logs'] as List? ?? const [];
      return logs
          .whereType<Map<String, dynamic>>()
          .map(AdminActivityLog.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<List<AdminCoursePart>> getCourseParts(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/courses'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final parts = json['parts'] as List? ?? const [];
      return parts
          .whereType<Map<String, dynamic>>()
          .map(AdminCoursePart.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<List<AdminSubscriptionRequest>> getSubscriptionRequests(
    String token,
  ) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/subscriptions'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final subscriptions = json['subscriptions'] as List? ?? const [];
      return subscriptions
          .whereType<Map<String, dynamic>>()
          .map(AdminSubscriptionRequest.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<List<AdminAppNotification>> getNotifications(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/notifications'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final notifications = json['notifications'] as List? ?? const [];
      return notifications
          .whereType<Map<String, dynamic>>()
          .map(AdminAppNotification.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<String?> createNotification(
    String token,
    Map<String, dynamic> notification,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/notifications'),
      notification,
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = _readJson(response.body);
      final push = json['push'];
      if (push is Map && push['sent'] != true) {
        return push['reason']?.toString() ?? 'push_failed';
      }
      return null;
    }

    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<List<CourseQuestion>> getQuestions(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/questions'),
      headers: _headers(token),
    );
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

  Future<void> answerQuestion(
    String token,
    String questionId,
    String answer,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/questions/$questionId/answer'),
      {'answer': answer},
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }

    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> approveSubscriptionRequest(
    String token,
    String subscriptionId,
    Map<String, dynamic> paymentData,
  ) async {
    final response = await postJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/subscriptions/$subscriptionId/approve',
      ),
      paymentData,
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> createCoursePart(
    String token,
    Map<String, dynamic> coursePart,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/courses'),
      coursePart,
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> deleteCoursePart(String token, String partId) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/courses/$partId/delete'),
      const {},
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<List<AdminBook>> getBooks(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/books'),
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final books = json['books'] as List? ?? const [];
      return books
          .whereType<Map<String, dynamic>>()
          .map(AdminBook.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<void> createBook(String token, AdminBook book) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/books'),
      book.toJson(),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> updateBook(
    String token,
    String bookId,
    Map<String, dynamic> updates,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/books/$bookId'),
      updates,
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> deleteBook(String token, String bookId) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/books/$bookId/delete'),
      const {},
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> updateCoursePart(
    String token,
    String partId,
    Map<String, dynamic> updates,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/courses/$partId/update'),
      updates,
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> createUser(String token, Map<String, dynamic> user) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/users'),
      user,
      headers: _headers(token),
    );
    if (response.statusCode == 201) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> updateUser(
    String token,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId/update'),
      updates,
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> deleteUser(String token, String userId) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId/delete'),
      const {},
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(
      _readMessage(_readJson(response.body), response.statusCode),
    );
  }

  Future<void> changePassword(
    String token,
    String userId,
    String password,
  ) async {
    await updateUser(token, userId, {'password': password});
  }

  Map<String, String> _headers(String token) {
    return {'Authorization': 'Bearer $token'};
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
    if (statusCode == 401) {
      return 'انتهت جلسة الأدمن. سجل الدخول مرة أخرى.';
    }
    return 'حدث خطأ غير متوقع.';
  }
}
