class SupportMessage {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;

  final String sender;
  final String message;

  final bool readByAdmin;
  final bool readByStudent;

  final String createdAt;

  const SupportMessage({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.sender,
    required this.message,
    required this.readByAdmin,
    required this.readByStudent,
    required this.createdAt,
  });

  bool get isFromAdmin => sender == 'admin';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      studentPhone: json['studentPhone']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'student',
      message: json['message']?.toString() ?? '',
      readByAdmin: json['readByAdmin'] == true,
      readByStudent: json['readByStudent'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'sender': sender,
      'message': message,
      'readByAdmin': readByAdmin,
      'readByStudent': readByStudent,
      'createdAt': createdAt,
    };
  }
}