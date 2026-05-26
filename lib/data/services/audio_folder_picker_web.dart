// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

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
  final input = html.FileUploadInputElement()
    ..multiple = true
    ..accept = _audioExtensions.join(',');
  input.setAttribute('webkitdirectory', '');
  input.setAttribute('directory', '');
  input.click();

  await input.onChange.first;
  final rawFiles = input.files;
  if (rawFiles == null) return null;

  final picked = <PickedAudioFolderFile>[];
  for (final file in rawFiles) {
    final relativePath = _relativePath(file);
    final extension = _extension(relativePath);
    if (!_audioExtensions.contains(extension)) continue;

    picked.add(
      PickedAudioFolderFile(
        title: _titleFromPath(relativePath),
        dataUrl: await _readDataUrl(file),
        relativePath: relativePath,
      ),
    );
  }

  picked.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return picked;
}

Future<String> _readDataUrl(html.File file) {
  final completer = Completer<String>();
  final reader = html.FileReader();
  reader.onLoad.first.then((_) {
    completer.complete(reader.result?.toString() ?? '');
  });
  reader.onError.first.then((_) {
    completer.completeError(reader.error ?? StateError('File read failed'));
  });
  reader.readAsDataUrl(file);
  return completer.future;
}

String _relativePath(html.File file) {
  final candidate = file.relativePath?.trim();
  final path = candidate == null || candidate.isEmpty ? file.name : candidate;
  return path
      .replaceAll('\\', '/')
      .split('/')
      .where((part) => part.isNotEmpty && part != '.' && part != '..')
      .join('/');
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
