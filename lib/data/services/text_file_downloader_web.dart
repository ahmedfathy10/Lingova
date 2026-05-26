// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html';

Future<void> downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  final blob = Blob([content], mimeType);
  final url = Url.createObjectUrlFromBlob(blob);
  AnchorElement(href: url)
    ..download = fileName
    ..click();
  Url.revokeObjectUrl(url);
}
