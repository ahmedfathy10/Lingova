import 'dart:convert';

import '../../core/api_config.dart';
import '../models/support_message.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class SupportApiService {
  Future<List<SupportMessage>> getMessages({required String studentId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/messages').replace(
      queryParameters: {'studentId': studentId},
    );

    final response = await getJson(uri);
    final json = _readJson(response.body);

    if (response.statusCode == 200) {
      final messages = json['messages'] as List? ?? const [];
      return messages
          .whereType<Map<String, dynamic>>()
          .map(SupportMessage.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<SupportMessage> createMessage({
    required String studentId,
    required String message,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/support/messages'),
      {
        'studentId': studentId,
        'message': message,
      },
    );

    final json = _readJson(response.body);

    if (response.statusCode == 201) {
      return SupportMessage.fromJson(
        Map<String, dynamic>.from(json['message'] as Map? ?? const {}),
      );
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<List<SupportMessage>> getAdminMessages(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/support-messages'),
      headers: _headers(token),
    );

    final json = _readJson(response.body);

    if (response.statusCode == 200) {
      final messages = json['messages'] as List? ?? const [];
      return messages
          .whereType<Map<String, dynamic>>()
          .map(SupportMessage.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<SupportMessage> sendAdminMessage({
    required String token,
    required String studentId,
    required String message,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/support-messages'),
      {
        'studentId': studentId,
        'message': message,
      },
      headers: _headers(token),
    );

    final json = _readJson(response.body);

    if (response.statusCode == 201) {
      return SupportMessage.fromJson(
        Map<String, dynamic>.from(json['message'] as Map? ?? const {}),
      );
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<void> markAdminMessagesRead({
    required String token,
    required String studentId,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/support-messages/read'),
      {
        'studentId': studentId,
      },
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      final json = _readJson(response.body);
      throw AuthApiException(_readMessage(json, response.statusCode));
    }
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

    return 'حدث خطأ غير متوقع.';
  }
}