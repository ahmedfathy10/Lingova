// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

String get apiBaseUrl {
  final host = html.window.location.hostname;
  if (host == 'localhost' || host == '127.0.0.1') {
    return 'http://localhost:3000';
  }

  return 'https://lingova-production.up.railway.app';
}
