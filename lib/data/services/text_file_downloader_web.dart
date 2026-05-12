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
