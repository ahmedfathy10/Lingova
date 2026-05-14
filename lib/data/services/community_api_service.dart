import 'dart:convert';

import '../../core/api_config.dart';
import '../models/community_post.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class CommunityApiService {
  Future<List<CommunityPost>> getPosts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/community/posts');
    final response = await getJson(uri);
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final posts = json['posts'] as List? ?? const [];
      return posts
          .whereType<Map<String, dynamic>>()
          .map(CommunityPost.fromJson)
          .toList();
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
  }

  Future<CommunityPost> createPost({
    required String studentId,
    required String authorName,
    required String message,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/community/posts'),
      {
        'studentId': studentId,
        'authorName': authorName,
        'message': message,
      },
    );

    final json = _readJson(response.body);
    if (response.statusCode == 201) {
      return CommunityPost.fromJson(
        Map<String, dynamic>.from(json['post'] as Map? ?? const {}),
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
