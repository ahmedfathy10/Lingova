import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

class AuthStorageService {
  static const _userKey = 'saved_auth_user';
  static const _notificationStartPrefix = 'notification_start_at_';

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
    if (user.id.isNotEmpty) {
      final key = '$_notificationStartPrefix${user.id}';
      final existing = prefs.getString(key);
      if (existing == null || existing.isEmpty) {
        final startAt = user.createdAt ?? DateTime.now();
        await prefs.setString(key, startAt.toIso8601String());
      }
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
