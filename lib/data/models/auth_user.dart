class AuthUser {
  final String id;
  final String fullName;
  final String phone;
  final String language;
  final List<UserEnrollment> enrollments;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.language,
    this.enrollments = const [],
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      enrollments: (json['enrollments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UserEnrollment.fromJson)
          .toList(),
    );
  }

  bool hasCourse(String language, String courseTitle) {
    final key = '$language|$courseTitle';
    return enrollments.any((enrollment) => enrollment.courseKey == key);
  }
}

class UserEnrollment {
  final String courseKey;
  final String courseTitle;
  final String courseLanguage;
  final String paymentMethod;
  final String paymentDate;
  final String paymentPhone;
  final String paidAmount;

  const UserEnrollment({
    required this.courseKey,
    required this.courseTitle,
    required this.courseLanguage,
    required this.paymentMethod,
    required this.paymentDate,
    required this.paymentPhone,
    required this.paidAmount,
  });

  factory UserEnrollment.fromJson(Map<String, dynamic> json) {
    return UserEnrollment(
      courseKey: json['courseKey']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentDate: json['paymentDate']?.toString() ?? '',
      paymentPhone: json['paymentPhone']?.toString() ?? '',
      paidAmount: json['paidAmount']?.toString() ?? '',
    );
  }
}
