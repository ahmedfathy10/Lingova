class AdminUser {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String job;
  final String language;
  final String learningReason;
  final String referralReason;
  final String status;
  final String role;
  final DateTime? createdAt;
  final String createdBy;
  final List<AdminUserEnrollment> enrollments;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.job,
    required this.language,
    required this.learningReason,
    required this.referralReason,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.createdBy,
    this.enrollments = const [],
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      job: json['job']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      learningReason: json['learningReason']?.toString() ?? '',
      referralReason: json['referralReason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      role: json['role']?.toString() ?? 'student',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      createdBy: json['createdBy']?.toString() ?? 'App',
      enrollments: (json['enrollments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminUserEnrollment.fromJson)
          .toList(),
    );
  }

  bool get isSuspended => status == 'suspended';
  bool get isAdminRole => role == 'admin';
  bool get isSystemAdmin => id == 'system-admin';
  String get roleLabel => isAdminRole ? 'أدمن' : 'طالب';

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

class AdminUserEnrollment {
  final String courseTitle;
  final String courseLanguage;
  final String paymentMethod;
  final String paymentDate;
  final String paymentPhone;
  final String paidAmount;

  const AdminUserEnrollment({
    required this.courseTitle,
    required this.courseLanguage,
    required this.paymentMethod,
    required this.paymentDate,
    required this.paymentPhone,
    required this.paidAmount,
  });

  factory AdminUserEnrollment.fromJson(Map<String, dynamic> json) {
    return AdminUserEnrollment(
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentDate: json['paymentDate']?.toString() ?? '',
      paymentPhone: json['paymentPhone']?.toString() ?? '',
      paidAmount: json['paidAmount']?.toString() ?? '',
    );
  }
}

class AdminStats {
  final int studentsCount;
  final int activeUsersCount;
  final int suspendedUsersCount;
  final int courseRegistrationsCount;
  final int coursesCount;
  final Map<String, int> registrationsByLanguage;
  final AdminRevenueStats revenue;
  final AdminActivityStats activity;

  const AdminStats({
    required this.studentsCount,
    required this.activeUsersCount,
    required this.suspendedUsersCount,
    required this.courseRegistrationsCount,
    required this.coursesCount,
    required this.registrationsByLanguage,
    required this.revenue,
    required this.activity,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final rawLanguages = json['registrationsByLanguage'];
    final revenueJson =
        (json['revenue'] as Map?)?.cast<String, dynamic>() ?? const {};
    final activityJson =
        (json['activity'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AdminStats(
      studentsCount: _readInt(json['studentsCount']),
      activeUsersCount: _readInt(json['activeUsersCount']),
      suspendedUsersCount: _readInt(json['suspendedUsersCount']),
      courseRegistrationsCount: _readInt(json['courseRegistrationsCount']),
      coursesCount: _readInt(json['coursesCount']),
      registrationsByLanguage: rawLanguages is Map
          ? rawLanguages.map(
              (key, value) => MapEntry(key.toString(), _readInt(value)),
            )
          : const {},
      revenue: AdminRevenueStats.fromJson(revenueJson),
      activity: AdminActivityStats.fromJson(activityJson),
    );
  }

  static int _readInt(Object? value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AdminRevenueStats {
  final int total;
  final int today;
  final int month;
  final List<AdminCourseRevenue> byCourse;

  const AdminRevenueStats({
    required this.total,
    required this.today,
    required this.month,
    required this.byCourse,
  });

  factory AdminRevenueStats.fromJson(Map<String, dynamic> json) {
    final rows = json['byCourse'] as List? ?? const [];
    return AdminRevenueStats(
      total: AdminStats._readInt(json['total']),
      today: AdminStats._readInt(json['today']),
      month: AdminStats._readInt(json['month']),
      byCourse: rows
          .whereType<Map<String, dynamic>>()
          .map(AdminCourseRevenue.fromJson)
          .toList(),
    );
  }
}

class AdminCourseRevenue {
  final String courseLanguage;
  final String courseTitle;
  final int purchasesCount;
  final int collectedAmount;

  const AdminCourseRevenue({
    required this.courseLanguage,
    required this.courseTitle,
    required this.purchasesCount,
    required this.collectedAmount,
  });

  factory AdminCourseRevenue.fromJson(Map<String, dynamic> json) {
    return AdminCourseRevenue(
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      purchasesCount: AdminStats._readInt(json['purchasesCount']),
      collectedAmount: AdminStats._readInt(json['collectedAmount']),
    );
  }
}

class AdminActivityStats {
  final int activeNowCount;
  final int opensTodayCount;

  const AdminActivityStats({
    required this.activeNowCount,
    required this.opensTodayCount,
  });

  factory AdminActivityStats.fromJson(Map<String, dynamic> json) {
    return AdminActivityStats(
      activeNowCount: AdminStats._readInt(json['activeNowCount']),
      opensTodayCount: AdminStats._readInt(json['opensTodayCount']),
    );
  }
}

class AdminActivityLog {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String action;
  final String label;
  final String details;
  final DateTime? createdAt;

  const AdminActivityLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.action,
    required this.label,
    required this.details,
    required this.createdAt,
  });

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get createdAtLabel {
    if (createdAt == null) {
      return '-';
    }
    final local = createdAt!.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }
}
