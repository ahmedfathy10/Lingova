import 'dart:convert';

import '../../core/api_config.dart';
import 'api_response.dart';
import '../models/community_post.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class CommunityApiService {
  Future<List<CommunityPost>> getPosts({String? studentId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/community/posts').replace(
      queryParameters: {
        if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
      },
    );
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

  Future<List<CommunityPost>> getAdminPosts(String token) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/community/posts'),
      headers: _headers(token),
    );
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
      {'studentId': studentId, 'authorName': authorName, 'message': message},
    );

    return _readPostResponse(response, successStatus: 201);
  }

  Future<CommunityPost> react({
    required String postId,
    required String studentId,
    required String reaction,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/community/posts/$postId/reaction'),
      {'studentId': studentId, 'reaction': reaction},
    );
    return _readPostResponse(response);
  }

  Future<CommunityPost> comment({
    required String postId,
    required String studentId,
    required String authorName,
    required String message,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/community/posts/$postId/comments'),
      {'studentId': studentId, 'authorName': authorName, 'message': message},
    );
    return _readPostResponse(response, successStatus: 201);
  }

  Future<CommunityPost> share({
    required String postId,
    required String studentId,
  }) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/community/posts/$postId/share'),
      {'studentId': studentId},
    );
    return _readPostResponse(response);
  }

  Future<void> deletePost({
    required String token,
    required String postId,
  }) async {
    final response = await postJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/community/posts/$postId/delete',
      ),
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

  Future<void> deleteComment({
    required String token,
    required String postId,
    required String commentId,
  }) async {
    final response = await postJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/community/posts/$postId/comments/$commentId/delete',
      ),
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

  Future<void> banUser({
    required String token,
    required String studentId,
  }) async {
    final response = await postJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/community/users/$studentId/ban',
      ),
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

  CommunityPost _readPostResponse(
    ApiResponse response, {
    int successStatus = 200,
  }) {
    final json = _readJson(response.body);
    if (response.statusCode == successStatus) {
      return CommunityPost.fromJson(
        Map<String, dynamic>.from(json['post'] as Map? ?? const {}),
      );
    }

    throw AuthApiException(_readMessage(json, response.statusCode));
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
