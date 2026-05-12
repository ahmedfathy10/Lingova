class WatchProgressRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String courseTitle;
  final String courseLanguage;
  final String levelTitle;
  final String lectureTitle;
  final String partTitle;
  final String vimeoUrl;
  final String duration;
  final String completedAt;
  final String watchDate;
  final int watchCount;

  const WatchProgressRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.courseTitle,
    required this.courseLanguage,
    required this.levelTitle,
    required this.lectureTitle,
    required this.partTitle,
    required this.vimeoUrl,
    required this.duration,
    required this.completedAt,
    required this.watchDate,
    required this.watchCount,
  });

  factory WatchProgressRecord.fromJson(Map<String, dynamic> json) {
    return WatchProgressRecord(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      studentPhone: json['studentPhone']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      levelTitle: json['levelTitle']?.toString() ?? '',
      lectureTitle: json['lectureTitle']?.toString() ?? '',
      partTitle: json['partTitle']?.toString() ?? '',
      vimeoUrl: json['vimeoUrl']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      completedAt: json['completedAt']?.toString() ?? '',
      watchDate: json['watchDate']?.toString() ?? '',
      watchCount: int.tryParse(json['watchCount']?.toString() ?? '') ?? 1,
    );
  }

  String get completedAtLabel {
    final parsed = DateTime.tryParse(completedAt);
    if (parsed == null) {
      return completedAt;
    }
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class WatchReportSummary {
  final int completedPartsCount;
  final int studentsCount;
  final int coursesCount;
  final int totalWatchCount;

  const WatchReportSummary({
    required this.completedPartsCount,
    required this.studentsCount,
    required this.coursesCount,
    required this.totalWatchCount,
  });

  factory WatchReportSummary.fromJson(Map<String, dynamic> json) {
    return WatchReportSummary(
      completedPartsCount: _readInt(json['completedPartsCount']),
      studentsCount: _readInt(json['studentsCount']),
      coursesCount: _readInt(json['coursesCount']),
      totalWatchCount: _readInt(json['totalWatchCount']),
    );
  }

  static int _readInt(Object? value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class WatchReport {
  final String date;
  final WatchReportSummary summary;
  final List<WatchProgressRecord> records;

  const WatchReport({
    required this.date,
    required this.summary,
    required this.records,
  });

  factory WatchReport.fromJson(Map<String, dynamic> json) {
    final records = json['records'] as List? ?? const [];
    return WatchReport(
      date: json['date']?.toString() ?? '',
      summary: WatchReportSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      records: records
          .whereType<Map<String, dynamic>>()
          .map(WatchProgressRecord.fromJson)
          .toList(),
    );
  }
}
