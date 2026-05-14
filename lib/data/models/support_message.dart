class SupportMessage {
  final String id;
  final String studentId;
  final String studentName;
  final String message;
  final String answer;
  final String status;
  final String createdAt;
  final String answeredAt;
  final String answeredBy;

  const SupportMessage({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.message,
    required this.answer,
    required this.status,
    required this.createdAt,
    required this.answeredAt,
    required this.answeredBy,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
      answeredAt: json['answeredAt']?.toString() ?? '',
      answeredBy: json['answeredBy']?.toString() ?? '',
    );
  }

  bool get isAnswered => status == 'answered' && answer.trim().isNotEmpty;
}
