import 'dart:html' as html;

String get apiBaseUrl {
  final host = html.window.location.hostname;
  if (host == 'localhost' || host == '127.0.0.1') {
    return 'http://localhost:3000';
  }

  return 'https://lingova-production.up.railway.app';
}
