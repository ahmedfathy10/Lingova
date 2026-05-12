import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<String?> pickCourseImageDataUrl() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
  );

  final file = result?.files.first;
  if (file == null) {
    return null;
  }

  Uint8List? bytes = file.bytes;

  if (bytes == null && file.path != null) {
    try {
      bytes = await File(file.path!).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  if (bytes == null) {
    return null;
  }

  final extension = file.extension?.toLowerCase() ?? '';
  final mimeType =
      {
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'gif': 'image/gif',
        'webp': 'image/webp',
      }[extension] ??
      'image/png';

  final base64Data = await compute(_encodeBase64, bytes);
  return 'data:$mimeType;base64,$base64Data';
}

String _encodeBase64(Uint8List bytes) {
  return base64Encode(bytes);
}
