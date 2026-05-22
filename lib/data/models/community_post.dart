class CommunityComment {
  final String id;
  final String studentId;
  final String authorName;
  final String message;
  final String createdAt;

  const CommunityComment({
    required this.id,
    required this.studentId,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'مستخدم',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class CommunityPost {
  final String id;
  final String studentId;
  final String authorName;
  final String message;
  final String createdAt;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final int sharesCount;
  final String userReaction;
  final List<CommunityComment> comments;

  const CommunityPost({
    required this.id,
    required this.studentId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    required this.likesCount,
    required this.dislikesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.userReaction,
    required this.comments,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final comments = json['comments'] as List? ?? const [];
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'مستخدم',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      likesCount: _readInt(json['likesCount']),
      dislikesCount: _readInt(json['dislikesCount']),
      commentsCount: _readInt(json['commentsCount']),
      sharesCount: _readInt(json['sharesCount']),
      userReaction: json['userReaction']?.toString() ?? '',
      comments: comments
          .whereType<Map<String, dynamic>>()
          .map(CommunityComment.fromJson)
          .toList(),
    );
  }

  static int _readInt(Object? value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
