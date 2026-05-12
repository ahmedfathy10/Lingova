class AdminSubscriptionRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentAddress;
  final String studentJob;
  final String studentLanguage;
  final String courseTitle;
  final String courseLanguage;
  final String courseLevel;
  final String coursePrice;
  final String status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final String approvedBy;
  final String paymentMethod;
  final String paymentDate;
  final String paymentPhone;
  final String paidAmount;

  const AdminSubscriptionRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentAddress,
    required this.studentJob,
    required this.studentLanguage,
    required this.courseTitle,
    required this.courseLanguage,
    required this.courseLevel,
    required this.coursePrice,
    required this.status,
    required this.requestedAt,
    required this.approvedAt,
    required this.approvedBy,
    required this.paymentMethod,
    required this.paymentDate,
    required this.paymentPhone,
    required this.paidAmount,
  });

  factory AdminSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionRequest(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      studentPhone: json['studentPhone']?.toString() ?? '',
      studentAddress: json['studentAddress']?.toString() ?? '',
      studentJob: json['studentJob']?.toString() ?? '',
      studentLanguage: json['studentLanguage']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      courseLanguage: json['courseLanguage']?.toString() ?? '',
      courseLevel: json['courseLevel']?.toString() ?? '',
      coursePrice: json['coursePrice']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? ''),
      approvedAt: DateTime.tryParse(json['approvedAt']?.toString() ?? ''),
      approvedBy: json['approvedBy']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentDate: json['paymentDate']?.toString() ?? '',
      paymentPhone: json['paymentPhone']?.toString() ?? '',
      paidAmount: json['paidAmount']?.toString() ?? '',
    );
  }

  bool get isApproved => status == 'approved';
  String get statusLabel => isApproved ? 'مدفوع' : 'قيد الانتظار';
  String get priceLabel => coursePrice.isEmpty ? '-' : coursePrice;

  String get requestedAtLabel => _formatDateTime(requestedAt);
  String get approvedAtLabel => _formatDateTime(approvedAt);

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }
}
