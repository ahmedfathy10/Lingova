import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

class AuthStorageService {
  static const _userKey = 'saved_auth_user';

  static Future<AuthUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AuthUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
