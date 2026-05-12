import 'dart:io';

Future<void> downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  final file = File(fileName);
  await file.writeAsString(content);
}
