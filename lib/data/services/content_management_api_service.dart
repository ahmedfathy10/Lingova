import 'dart:convert';

import '../../core/api_config.dart';
import '../models/audio_resource.dart';
import '../models/vocabulary_word.dart';
import 'auth_api_service.dart';
import 'auth_http_client.dart';

class ContentManagementApiService {
  Future<List<VocabularyWord>> getVocabulary({String? token}) async {
    final response = await getJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/${token == null ? '' : 'admin/'}vocabulary',
      ),
      headers: token == null ? const {} : _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final words = json['words'] as List? ?? const [];
      return words
          .whereType<Map<String, dynamic>>()
          .map(VocabularyWord.fromJson)
          .toList();
    }
    throw AuthApiException(_readMessage(json));
  }

  Future<void> createVocabularyWord(String token, VocabularyWord word) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/vocabulary'),
      word.toJson(),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(_readMessage(_readJson(response.body)));
  }

  Future<int> createVocabularyWords(
    String token,
    List<VocabularyWord> words,
  ) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/vocabulary'),
      {'words': words.map((word) => word.toJson()).toList()},
      headers: _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (json['count'] as num?)?.toInt() ?? words.length;
    }
    throw AuthApiException(_readMessage(json));
  }

  Future<void> deleteVocabularyWord(String token, String id) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/vocabulary/$id/delete'),
      const {},
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(_readMessage(_readJson(response.body)));
  }

  Future<List<AudioResource>> getAudioResources({String? token}) async {
    final response = await getJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/${token == null ? '' : 'admin/'}audio-resources',
      ),
      headers: token == null ? const {} : _headers(token),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      final resources = json['resources'] as List? ?? const [];
      return resources
          .whereType<Map<String, dynamic>>()
          .map(AudioResource.fromJson)
          .toList();
    }
    throw AuthApiException(_readMessage(json));
  }

  Future<void> createAudioResource(String token, AudioResource resource) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/audio-resources'),
      resource.toJson(),
      headers: _headers(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(_readMessage(_readJson(response.body)));
  }

  Future<void> deleteAudioResource(String token, String id) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/audio-resources/$id/delete'),
      const {},
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw AuthApiException(_readMessage(_readJson(response.body)));
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

  String _readMessage(Map<String, dynamic> json) {
    return json['message']?.toString() ?? 'حدث خطأ غير متوقع.';
  }
}
