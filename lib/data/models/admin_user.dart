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

enum AdminDashboardPeriod { day, month, year }

extension AdminDashboardPeriodApi on AdminDashboardPeriod {
  String get apiValue {
    switch (this) {
      case AdminDashboardPeriod.day:
        return 'day';
      case AdminDashboardPeriod.month:
        return 'month';
      case AdminDashboardPeriod.year:
        return 'year';
    }
  }

  String get label {
    switch (this) {
      case AdminDashboardPeriod.day:
        return 'يومي';
      case AdminDashboardPeriod.month:
        return 'شهري';
      case AdminDashboardPeriod.year:
        return 'سنوي';
    }
  }

  String get rangeDescription {
    switch (this) {
      case AdminDashboardPeriod.day:
        return 'آخر 30 يوم';
      case AdminDashboardPeriod.month:
        return 'آخر 12 شهر';
      case AdminDashboardPeriod.year:
        return 'آخر 5 سنوات';
    }
  }
}

class AdminChartPoint {
  final String label;
  final int value;

  const AdminChartPoint({required this.label, required this.value});

  factory AdminChartPoint.fromJson(Map<String, dynamic> json) {
    return AdminChartPoint(
      label: json['label']?.toString() ?? '',
      value: AdminStats._readInt(json['value']),
    );
  }
}

class AdminDashboardCharts {
  final List<AdminChartPoint> revenue;
  final List<AdminChartPoint> newStudents;
  final List<AdminChartPoint> appOpens;
  final List<AdminChartPoint> enrollments;
  final List<AdminChartPoint> examAttempts;
  final List<AdminChartPoint> subscriptionRequests;
  final List<AdminChartPoint> watchSessions;
  final List<AdminChartPoint> communityPosts;

  const AdminDashboardCharts({
    required this.revenue,
    required this.newStudents,
    required this.appOpens,
    required this.enrollments,
    required this.examAttempts,
    required this.subscriptionRequests,
    required this.watchSessions,
    required this.communityPosts,
  });

  factory AdminDashboardCharts.fromJson(Map<String, dynamic> json) {
    List<AdminChartPoint> readSeries(String key) {
      final raw = json[key] as List? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdminChartPoint.fromJson)
          .toList();
    }

    return AdminDashboardCharts(
      revenue: readSeries('revenue'),
      newStudents: readSeries('newStudents'),
      appOpens: readSeries('appOpens'),
      enrollments: readSeries('enrollments'),
      examAttempts: readSeries('examAttempts'),
      subscriptionRequests: readSeries('subscriptionRequests'),
      watchSessions: readSeries('watchSessions'),
      communityPosts: readSeries('communityPosts'),
    );
  }
}

class AdminDashboardOverview {
  final int pendingSubscriptions;
  final int approvedSubscriptions;
  final int examsCount;
  final int examAttemptsCount;
  final int passedExamAttempts;
  final int communityPostsCount;
  final int booksCount;
  final int vocabularyCount;
  final int watchProgressCount;
  final int supportConversationsCount;
  final int activityLogsCount;

  const AdminDashboardOverview({
    required this.pendingSubscriptions,
    required this.approvedSubscriptions,
    required this.examsCount,
    required this.examAttemptsCount,
    required this.passedExamAttempts,
    required this.communityPostsCount,
    required this.booksCount,
    required this.vocabularyCount,
    required this.watchProgressCount,
    required this.supportConversationsCount,
    required this.activityLogsCount,
  });

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) {
    return AdminDashboardOverview(
      pendingSubscriptions: AdminStats._readInt(json['pendingSubscriptions']),
      approvedSubscriptions: AdminStats._readInt(json['approvedSubscriptions']),
      examsCount: AdminStats._readInt(json['examsCount']),
      examAttemptsCount: AdminStats._readInt(json['examAttemptsCount']),
      passedExamAttempts: AdminStats._readInt(json['passedExamAttempts']),
      communityPostsCount: AdminStats._readInt(json['communityPostsCount']),
      booksCount: AdminStats._readInt(json['booksCount']),
      vocabularyCount: AdminStats._readInt(json['vocabularyCount']),
      watchProgressCount: AdminStats._readInt(json['watchProgressCount']),
      supportConversationsCount: AdminStats._readInt(
        json['supportConversationsCount'],
      ),
      activityLogsCount: AdminStats._readInt(json['activityLogsCount']),
    );
  }
}

class AdminStats {
  final AdminDashboardPeriod period;
  final int studentsCount;
  final int activeUsersCount;
  final int suspendedUsersCount;
  final int courseRegistrationsCount;
  final int coursesCount;
  final Map<String, int> registrationsByLanguage;
  final AdminRevenueStats revenue;
  final AdminActivityStats activity;
  final AdminDashboardOverview overview;
  final AdminDashboardCharts charts;

  const AdminStats({
    required this.period,
    required this.studentsCount,
    required this.activeUsersCount,
    required this.suspendedUsersCount,
    required this.courseRegistrationsCount,
    required this.coursesCount,
    required this.registrationsByLanguage,
    required this.revenue,
    required this.activity,
    required this.overview,
    required this.charts,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final rawLanguages = json['registrationsByLanguage'];
    final revenueJson =
        (json['revenue'] as Map?)?.cast<String, dynamic>() ?? const {};
    final activityJson =
        (json['activity'] as Map?)?.cast<String, dynamic>() ?? const {};
    final overviewJson =
        (json['overview'] as Map?)?.cast<String, dynamic>() ?? const {};
    final chartsJson =
        (json['charts'] as Map?)?.cast<String, dynamic>() ?? const {};
    final periodRaw = json['period']?.toString() ?? 'day';
    final period = switch (periodRaw) {
      'month' => AdminDashboardPeriod.month,
      'year' => AdminDashboardPeriod.year,
      _ => AdminDashboardPeriod.day,
    };
    return AdminStats(
      period: period,
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
      overview: AdminDashboardOverview.fromJson(overviewJson),
      charts: AdminDashboardCharts.fromJson(chartsJson),
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
  final int year;
  final List<AdminCourseRevenue> byCourse;

  const AdminRevenueStats({
    required this.total,
    required this.today,
    required this.month,
    required this.year,
    required this.byCourse,
  });

  factory AdminRevenueStats.fromJson(Map<String, dynamic> json) {
    final rows = json['byCourse'] as List? ?? const [];
    return AdminRevenueStats(
      total: AdminStats._readInt(json['total']),
      today: AdminStats._readInt(json['today']),
      month: AdminStats._readInt(json['month']),
      year: AdminStats._readInt(json['year']),
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
