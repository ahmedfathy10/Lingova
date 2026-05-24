class RegisterRequest {
  final Map<String, dynamic> values;

  const RegisterRequest(this.values);

  Map<String, dynamic> toJson() {
    return values;
  }
}
