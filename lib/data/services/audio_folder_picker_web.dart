import 'dart:convert';

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

const _audioExtensions = {'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'};

Future<List<PickedAudioFolderFile>?> pickAudioFolderFiles() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: _audioExtensions.toList(),
    allowMultiple: true,
    withData: true,
    dialogTitle: 'اختر ملفات الصوت داخل الفولدر',
  );
  if (result == null) return null;

  final files = result.files
      .where((file) => _audioExtensions.contains(_extension(file.name)))
      .where((file) => file.bytes != null)
      .map(
        (file) => PickedAudioFolderFile(
          title: _titleFromName(file.name),
          dataUrl:
              'data:${_mimeType(_extension(file.name))};base64,${base64Encode(file.bytes!)}',
          relativePath: _relativePath(file),
        ),
      )
      .toList();
  files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return files;
}

String _relativePath(PlatformFile file) {
  final candidate = file.path ?? file.identifier ?? file.name;
  return candidate
      .replaceAll('\\', '/')
      .split('/')
      .where((part) {
        return part.isNotEmpty && part != '.' && part != '..';
      })
      .join('/');
}

String _titleFromName(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

String _mimeType(String extension) {
  switch (extension) {
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'm4a':
      return 'audio/mp4';
    case 'aac':
      return 'audio/aac';
    case 'ogg':
      return 'audio/ogg';
    case 'flac':
      return 'audio/flac';
    default:
      return 'audio/mpeg';
  }
}
