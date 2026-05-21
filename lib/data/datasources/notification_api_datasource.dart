import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_config.dart';
import '../../domain/entities/app_notification.dart';
import '../services/auth_http_client.dart';

class NotificationApiDataSource {
  static final Set<String> _readIds = <String>{};
  static const _readIdsKey = 'read_notification_ids';
  static bool _readIdsLoaded = false;

  Future<List<AppNotification>> getNotifications() async {
    await _loadReadIds();
    final response = await getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر تحميل التنبيهات');
    }

    final json = _readJson(response.body);
    final items = json['notifications'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_mapNotification)
        .toList();
  }

  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).length;
  }

  Future<void> markAsRead(String id) async {
    await _loadReadIds();
    _readIds.add(id);
    await _saveReadIds();
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    await _loadReadIds();
    _readIds.addAll(ids);
    await _saveReadIds();
  }

  Future<void> _loadReadIds() async {
    if (_readIdsLoaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _readIds
      ..clear()
      ..addAll(prefs.getStringList(_readIdsKey) ?? const []);
    _readIdsLoaded = true;
  }

  Future<void> _saveReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, _readIds.toList(growable: false));
  }

  AppNotification _mapNotification(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');

    return AppNotification(
      id: id,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      timeLabel: _buildTimeLabel(createdAt),
      icon: _iconForType(json['type']?.toString() ?? 'general'),
      isRead: _readIds.contains(id),
    );
  }

  Map<String, dynamic> _readJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  String _buildTimeLabel(DateTime? createdAt) {
    if (createdAt == null) {
      return 'الآن';
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt.toLocal());

    if (difference.inMinutes < 1) {
      return 'الآن';
    }
    if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    }
    if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    }
    if (difference.inDays == 1) {
      return 'أمس';
    }
    if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'course':
        return Icons.menu_book_rounded;
      case 'lesson':
        return Icons.play_circle_fill_rounded;
      case 'exam':
        return Icons.quiz_rounded;
      case 'payment':
        return Icons.payments_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
