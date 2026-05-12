import 'dart:convert';

import '../../core/api_config.dart';
import '../../domain/entities/book.dart';
import '../services/auth_http_client.dart';

class BookApiDataSource {
  Future<List<Book>> getBooks() async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/books'),
    );
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الكتب.');
    }

    final json = jsonDecode(response.body);
    final books = json['books'] as List? ?? const [];
    return books
        .whereType<Map<String, dynamic>>()
        .map(Book.fromJson)
        .toList();
  }

  Future<Book?> getBookById(String id) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/books/$id'),
    );
    if (response.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(response.body);
    return Book.fromJson(json['book']);
  }
}