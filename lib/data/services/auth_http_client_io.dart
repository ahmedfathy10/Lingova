import 'dart:convert';
import 'dart:io';

import 'api_response.dart';

Future<ApiResponse> postJson(
  Uri uri,
  Map<String, dynamic> body, {
  Map<String, String>? headers,
}) async {
  return requestJson(uri, method: 'POST', body: body, headers: headers);
}

Future<ApiResponse> getJson(Uri uri, {Map<String, String>? headers}) async {
  return requestJson(uri, method: 'GET', headers: headers);
}

Future<ApiResponse> patchJson(
  Uri uri,
  Map<String, dynamic> body, {
  Map<String, String>? headers,
}) async {
  return requestJson(uri, method: 'PATCH', body: body, headers: headers);
}

Future<ApiResponse> deleteJson(Uri uri, {Map<String, String>? headers}) async {
  return requestJson(uri, method: 'DELETE', headers: headers);
}

Future<ApiResponse> requestJson(
  Uri uri, {
  required String method,
  Map<String, dynamic>? body,
  Map<String, String>? headers,
}) async {
  final client = HttpClient();

  try {
    final request = await client.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    headers?.forEach(request.headers.set);
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    return ApiResponse(statusCode: response.statusCode, body: responseBody);
  } finally {
    client.close(force: true);
  }
}
