class AudioResource {
  final String id;
  final String title;
  final String description;
  final String course;
  final String courseLanguage;
  final String level;
  final String accessType;
  final String fileType;
  final String linkType;
  final String url;
  final List<AudioResourceItem> items;

  const AudioResource({
    required this.id,
    required this.title,
    required this.description,
    required this.course,
    required this.courseLanguage,
    required this.level,
    required this.accessType,
    required this.fileType,
    required this.linkType,
    required this.url,
    required this.items,
  });

  factory AudioResource.fromJson(Map<String, dynamic> json) {
    return AudioResource(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      accessType: json['accessType']?.toString() ?? 'free',
      fileType: json['fileType']?.toString() ?? 'audio',
      linkType: json['linkType']?.toString() ?? 'clip',
      url: json['url']?.toString() ?? '',
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AudioResourceItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'course': course,
      'courseLanguage': courseLanguage,
      'level': level,
      'accessType': accessType,
      'fileType': fileType,
      'linkType': linkType,
      'url': url,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  bool get isPaid => accessType == 'paid';
  bool get isFolder => linkType == 'folder';
}

class AudioResourceItem {
  final String id;
  final String title;
  final String url;
  final String fileType;

  const AudioResourceItem({
    required this.id,
    required this.title,
    required this.url,
    required this.fileType,
  });

  factory AudioResourceItem.fromJson(Map<String, dynamic> json) {
    return AudioResourceItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? 'audio',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url, 'fileType': fileType};
  }
}
