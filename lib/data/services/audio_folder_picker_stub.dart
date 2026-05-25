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

Future<List<PickedAudioFolderFile>?> pickAudioFolderFiles() async {
  return const <PickedAudioFolderFile>[];
}
