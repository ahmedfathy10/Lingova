import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_config.dart';
import '../models/auth_user.dart';
import '../../domain/entities/app_notification.dart';
import '../services/auth_http_client.dart';

class NotificationApiDataSource {
  static const _readIdsKey = 'read_notification_ids';
  static const _notificationStartPrefix = 'notification_start_at_';

  final AuthUser? user;
  final Set<String> _readIds = <String>{};
  bool _readIdsLoaded = false;

  NotificationApiDataSource({this.user});

  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
  }) async {
    await _loadReadIds();
    final notificationStartAt = await _notificationStartAt();
    final query = <String, String>{};
    final currentUser = user;
    if (currentUser != null && currentUser.id.isNotEmpty) {
      query['userId'] = currentUser.id;
    }
    if (unreadOnly) {
      query['unreadOnly'] = 'true';
    }
    final response = await getJson(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/notifications',
      ).replace(queryParameters: query.isEmpty ? null : query),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر تحميل التنبيهات');
    }

    final json = _readJson(response.body);
    final items = json['notifications'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_mapNotification)
        .where(
          (notification) =>
              _isVisibleForCurrentUser(notification, notificationStartAt),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).length;
  }

  Future<void> markAsRead(String id) async {
    await _loadReadIds();
    final currentUser = user;
    if (currentUser != null && currentUser.id.isNotEmpty) {
      try {
        await postJson(
          Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/read'),
          {'userId': currentUser.id},
        );
      } catch (_) {}
    }
    _readIds.add(id);
    await _saveReadIds();
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    await _loadReadIds();
    for (final id in ids) {
      await markAsRead(id);
    }
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
      ..addAll(prefs.getStringList(_readIdsStorageKey) ?? const []);
    _readIdsLoaded = true;
  }

  Future<void> _saveReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readIdsStorageKey,
      _readIds.toList(growable: false),
    );
  }

  String get _readIdsStorageKey {
    final userId = user?.id ?? '';
    return userId.isEmpty ? _readIdsKey : '${_readIdsKey}_$userId';
  }

  Future<DateTime?> _notificationStartAt() async {
    final currentUser = user;
    if (currentUser == null || currentUser.id.isEmpty) {
      return null;
    }
    if (currentUser.createdAt != null) {
      return currentUser.createdAt;
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(
      '$_notificationStartPrefix${currentUser.id}',
    );
    return DateTime.tryParse(stored ?? '');
  }

  bool _isVisibleForCurrentUser(
    AppNotification notification,
    DateTime? notificationStartAt,
  ) {
    final currentUser = user;
    if (currentUser == null || currentUser.id.isEmpty) {
      return true;
    }

    final notificationDate = notification.createdAt;
    if (notificationDate == null || notificationStartAt == null) {
      return true;
    }

    return !notificationDate.isBefore(notificationStartAt);
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
      createdAt: createdAt,
      isRead: json['isRead'] == true || _readIds.contains(id),
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
