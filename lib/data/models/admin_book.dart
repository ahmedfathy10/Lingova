class AdminBook {
  final String id;
  final String title;
  final String subtitle;
  final String course;
  final String language;
  final bool isFree;
  final String url;
  final DateTime? createdAt;
  final String createdBy;

  const AdminBook({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.course,
    required this.language,
    required this.isFree,
    required this.url,
    this.createdAt,
    required this.createdBy,
  });

  factory AdminBook.fromJson(Map<String, dynamic> json) {
    final isFreeValue = json['isFree'];
    final isFree = isFreeValue is bool
        ? isFreeValue
        : (isFreeValue?.toString().toLowerCase() ?? 'true') != 'false';

    return AdminBook(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      course: json['course'] as String? ?? '',
      language: json['language'] as String? ?? '',
      isFree: isFree,
      url: json['url'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'course': course,
      'language': language,
      'isFree': isFree,
      'url': url,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
