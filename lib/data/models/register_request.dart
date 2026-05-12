class RegisterRequest {
  final String fullName;
  final String phone;
  final String password;
  final String address;
  final String job;
  final String language;
  final String learningReason;
  final String referralReason;

  const RegisterRequest({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.address,
    required this.job,
    required this.language,
    required this.learningReason,
    required this.referralReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'address': address,
      'job': job,
      'language': language,
      'learningReason': learningReason,
      'referralReason': referralReason,
    };
  }
}
