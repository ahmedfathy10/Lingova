import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

class PickedAudioFolderFile {
  final String title;
  final String dataUrl;
  final String relativePath;
  final String fileType;

  const PickedAudioFolderFile({
    required this.title,
    required this.dataUrl,
    required this.relativePath,
    this.fileType = 'audio',
  });
}

const _audioExtensions = {'.mp3'};

Future<List<PickedAudioFolderFile>?> pickAudioFolderFiles() async {
  String? directoryPath;
  try {
    directoryPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'اختر فولدر الصوتيات',
    );
  } catch (_) {
    return _pickMultipleAudioFiles();
  }
  if (directoryPath == null) return null;

  final root = Directory(directoryPath);
  if (!root.existsSync()) return const <PickedAudioFolderFile>[];

  final files = <PickedAudioFolderFile>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final extension = _extension(entity.path);
    if (!_audioExtensions.contains(extension)) continue;

    final bytes = await entity.readAsBytes();
    final relativePath = _relativePath(root.path, entity.path);
    files.add(
      PickedAudioFolderFile(
        title: _titleFromPath(entity.path),
        dataUrl: 'data:${_mimeType(extension)};base64,${base64Encode(bytes)}',
        relativePath: relativePath,
      ),
    );
  }
  files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return files;
}

Future<List<PickedAudioFolderFile>?> _pickMultipleAudioFiles() async {
  final result = await FilePicker.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: const ['mp3'],
    withData: true,
  );
  if (result == null) return null;

  final files = <PickedAudioFolderFile>[];
  for (final file in result.files) {
    final name = file.name;
    final extension = _extension(name);
    if (!_audioExtensions.contains(extension)) continue;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) continue;
    files.add(
      PickedAudioFolderFile(
        title: _titleFromPath(name),
        dataUrl: 'data:${_mimeType(extension)};base64,${base64Encode(bytes)}',
        relativePath: name,
      ),
    );
  }
  files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return files;
}

String _relativePath(String rootPath, String filePath) {
  final normalizedRoot = rootPath
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'/+$'), '');
  final normalizedFile = filePath.replaceAll('\\', '/');
  if (normalizedFile.startsWith('$normalizedRoot/')) {
    return normalizedFile.substring(normalizedRoot.length + 1);
  }
  return _fileName(filePath);
}

String _titleFromPath(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  return slash < 0 ? normalized : normalized.substring(slash + 1);
}

String _extension(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot).toLowerCase();
}

String _mimeType(String extension) {
  switch (extension) {
    case '.mp3':
      return 'audio/mpeg';
    case '.wav':
      return 'audio/wav';
    case '.m4a':
      return 'audio/mp4';
    case '.aac':
      return 'audio/aac';
    case '.ogg':
      return 'audio/ogg';
    case '.flac':
      return 'audio/flac';
    default:
      return 'audio/mpeg';
  }
}
