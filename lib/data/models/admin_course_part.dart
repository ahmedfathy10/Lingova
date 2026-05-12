class AdminCoursePart {
  final String id;
  final String type;
  final String language;
  final String course;
  final String level;
  final String lecture;
  final String part;
  final String vimeoUrl;
  final String courseType;
  final String price;
  final String courseLevel;
  final String duration;
  final String imageDataUrl;
  final List<String> learningOutcomes;
  final DateTime? createdAt;
  final String createdBy;

  const AdminCoursePart({
    required this.id,
    required this.type,
    required this.language,
    required this.course,
    required this.level,
    required this.lecture,
    required this.part,
    required this.vimeoUrl,
    required this.courseType,
    required this.price,
    required this.courseLevel,
    required this.duration,
    required this.imageDataUrl,
    required this.learningOutcomes,
    required this.createdAt,
    required this.createdBy,
  });

  factory AdminCoursePart.fromJson(Map<String, dynamic> json) {
    return AdminCoursePart(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'part',
      language: json['language']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      lecture: json['lecture']?.toString() ?? '',
      part: json['part']?.toString() ?? '',
      vimeoUrl: json['vimeoUrl']?.toString() ?? '',
      courseType: json['courseType']?.toString() ?? 'free',
      price: json['price']?.toString() ?? '',
      courseLevel: json['courseLevel']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      imageDataUrl: json['imageDataUrl']?.toString() ?? '',
      learningOutcomes: (json['learningOutcomes'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      createdBy: json['createdBy']?.toString() ?? 'Admin',
    );
  }

  bool get isCourse => type == 'course';
  bool get isLevel => type == 'level';
  bool get isLecture => type == 'lecture';
  bool get isPart => type == 'part';
  bool get isPaid => courseType == 'paid';
  String get courseTypeLabel => isPaid ? 'Paid' : 'Free';
  String get priceLabel => isPaid && price.isNotEmpty ? '$price EGP' : 'Free';

  String get createdAtLabel {
    final value = createdAt;
    if (value == null) {
      return '-';
    }
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}
