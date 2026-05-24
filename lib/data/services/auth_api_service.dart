import 'dart:convert';

import '../../core/api_config.dart';
import '../models/auth_user.dart';
import '../models/login_request.dart';
import '../models/registration_form_config.dart';
import '../models/register_request.dart';
import 'auth_http_client.dart';

class AuthApiException implements Exception {
  final String message;

  const AuthApiException(this.message);

  @override
  String toString() => message;
}

class AppStreak {
  final int streak;
  final int activeDaysCount;
  final String today;

  const AppStreak({
    required this.streak,
    required this.activeDaysCount,
    required this.today,
  });

  factory AppStreak.fromJson(Map<String, dynamic> json) {
    return AppStreak(
      streak: int.tryParse(json['streak']?.toString() ?? '') ?? 0,
      activeDaysCount:
          int.tryParse(json['activeDaysCount']?.toString() ?? '') ?? 0,
      today: json['today']?.toString() ?? '',
    );
  }
}

class AuthApiService {
  Future<RegistrationFormConfig> getRegistrationFormConfig() async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/registration-form'),
    );
    if (response.statusCode == 200) {
      final json = _readJson(response.body);
      final formJson = (json['form'] as Map?)?.cast<String, dynamic>() ?? json;
      return RegistrationFormConfig.fromJson(formJson);
    }
    return RegistrationFormConfig.defaultConfig;
  }

  Future<AuthUser> register(RegisterRequest request) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/register'),
      request.toJson(),
    );

    if (response.statusCode == 201) {
      final json = _readJson(response.body);
      return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    }

    final message = _readMessage(response.body);
    throw AuthApiException(message);
  }

  Future<AuthUser> login(LoginRequest request) async {
    final response = await postJson(
      Uri.parse('${ApiConfig.baseUrl}/api/login'),
      request.toJson(),
    );

    if (response.statusCode == 200) {
      final json = _readJson(response.body);
      return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    }

    if (response.statusCode == 404) {
      throw const AuthApiException('انت مش مشترك، أنشئ حساب جديد.');
    }

    if (response.statusCode == 401) {
      throw const AuthApiException('حاول تكتب كلمة السر من جديد.');
    }

    final message = _readMessage(response.body);
    throw AuthApiException(message);
  }

  Future<AuthUser> getUser(String userId) async {
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    }
    throw AuthApiException(_readMessage(response.body));
  }

  Future<void> recordActivity({
    required String userId,
    required String sessionId,
    required String action,
    required String label,
    String details = '',
  }) async {
    final response =
        await postJson(Uri.parse('${ApiConfig.baseUrl}/api/app/activity'), {
          'userId': userId,
          'sessionId': sessionId,
          'action': action,
          'label': label,
          'details': details,
        });
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw AuthApiException(_readMessage(response.body));
  }

  Future<AppStreak> getAppStreak(String userId) async {
    final response = await getJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/app/streak',
      ).replace(queryParameters: {'userId': userId}),
    );
    final json = _readJson(response.body);
    if (response.statusCode == 200) {
      return AppStreak.fromJson(json);
    }
    throw AuthApiException(_readMessage(response.body));
  }

  String _readMessage(String body) {
    try {
      final json = _readJson(body);
      return json['message']?.toString() ?? 'Unable to create account.';
    } catch (_) {
      return 'Unable to create account.';
    }
  }

  Map<String, dynamic> _readJson(String body) {
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
