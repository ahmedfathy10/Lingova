import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';

class NotificationLocalDataSource {
  static var _notifications = <AppNotification>[
    const AppNotification(
      id: 'placement-test',
      title: 'اختبار تحديد المستوى جاهز',
      body: 'ابدأ الاختبار الآن عشان نرشح لك المستوى المناسب في الكورس.',
      timeLabel: 'منذ 10 دقائق',
      icon: Icons.quiz_rounded,
    ),
    const AppNotification(
      id: 'new-lesson',
      title: 'درس جديد في English A1',
      body: 'تم إضافة درس Unit 3 - Daily Routines داخل الكورس.',
      timeLabel: 'اليوم',
      icon: Icons.play_circle_fill_rounded,
    ),
    const AppNotification(
      id: 'homework-reminder',
      title: 'تذكير بالواجب',
      body: 'راجع تدريبات المفردات قبل المحاضرة القادمة.',
      timeLabel: 'أمس',
      icon: Icons.assignment_rounded,
      isRead: true,
    ),
  ];

  List<AppNotification> getNotifications() {
    return List.unmodifiable(_notifications);
  }

  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  void markAsRead(String id) {
    _notifications = [
      for (final notification in _notifications)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
  }

  void markAllAsRead() {
    _notifications = [
      for (final notification in _notifications)
        notification.copyWith(isRead: true),
    ];
  }
}
