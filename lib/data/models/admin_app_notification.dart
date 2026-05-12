class AdminAppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String createdAt;
  final String createdBy;

  const AdminAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.createdBy,
  });

  factory AdminAppNotification.fromJson(Map<String, dynamic> json) {
    return AdminAppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      createdAt: json['createdAt']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? 'Admin',
    );
  }
}
