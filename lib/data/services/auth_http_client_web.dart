// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'api_response.dart';

Future<ApiResponse> postJson(
  Uri uri,
  Map<String, dynamic> body, {
  Map<String, String>? headers,
}) {
  return requestJson(uri, method: 'POST', body: body, headers: headers);
}

Future<ApiResponse> getJson(Uri uri, {Map<String, String>? headers}) {
  return requestJson(uri, method: 'GET', headers: headers);
}

Future<ApiResponse> patchJson(
  Uri uri,
  Map<String, dynamic> body, {
  Map<String, String>? headers,
}) {
  return requestJson(uri, method: 'PATCH', body: body, headers: headers);
}

Future<ApiResponse> deleteJson(Uri uri, {Map<String, String>? headers}) {
  return requestJson(uri, method: 'DELETE', headers: headers);
}

Future<ApiResponse> requestJson(
  Uri uri, {
  required String method,
  Map<String, dynamic>? body,
  Map<String, String>? headers,
}) {
  final completer = Completer<ApiResponse>();
  final request = HttpRequest();

  request
    ..open(method, uri.toString())
    ..setRequestHeader('Content-Type', 'application/json')
    ..onLoadEnd.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(
          ApiResponse(
            statusCode: request.status ?? 0,
            body: request.responseText ?? '',
          ),
        );
      }
    })
    ..onError.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(
          ApiResponse(
            statusCode: request.status ?? 0,
            body: request.responseText ?? '',
          ),
        );
      }
    });
  headers?.forEach(request.setRequestHeader);
  request.send(body == null ? null : jsonEncode(body));

  return completer.future;
}
