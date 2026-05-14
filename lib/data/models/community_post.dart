class CommunityPost {
  final String id;
  final String studentId;
  final String authorName;
  final String message;
  final String createdAt;

  const CommunityPost({
    required this.id,
    required this.studentId,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'مستخدم',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
