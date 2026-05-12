import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      icon: icon,
      isRead: isRead ?? this.isRead,
    );
  }
}
