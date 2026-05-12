import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/datasources/notification_api_datasource.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _dataSource = NotificationApiDataSource();
  late Future<List<AppNotification>> _future;
  List<AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _future = _loadNotifications();
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final notifications = await _dataSource.getNotifications();
    _notifications = notifications;
    return notifications;
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _future = _loadNotifications();
    });
    await _future;
  }

  void _markAsRead(AppNotification notification) {
    if (notification.isRead) {
      return;
    }

    _dataSource.markAsRead(notification.id);
    setState(() {
      _notifications = [
        for (final current in _notifications)
          if (current.id == notification.id)
            current.copyWith(isRead: true)
          else
            current,
      ];
    });
  }

  void _markAllAsRead() {
    _dataSource.markAllAsRead(_notifications.map((notification) => notification.id));
    setState(() {
      _notifications = [
        for (final notification in _notifications)
          notification.copyWith(isRead: true),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التنبيهات',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            TextButton.icon(
              onPressed: _notifications.where((item) => !item.isRead).isEmpty
                  ? null
                  : _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('قراءة الكل'),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<AppNotification>>(
            future: _future,
            builder: (context, snapshot) {
              final notifications = snapshot.connectionState == ConnectionState.done
                  ? _notifications
                  : (snapshot.data ?? _notifications);
              final unreadCount = notifications
                  .where((notification) => !notification.isRead)
                  .length;

              if (snapshot.connectionState == ConnectionState.waiting &&
                  notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && notifications.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_off_rounded,
                          size: 72,
                          color: AppColors.orange,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'تعذر تحميل التنبيهات',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'جرّب التحديث مرة أخرى.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _refreshNotifications,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: notifications.isEmpty
                    ? const _EmptyNotifications()
                    : ListView(
                        padding: const EdgeInsets.all(22),
                        children: [
                          _UnreadSummary(unreadCount: unreadCount),
                          const SizedBox(height: 18),
                          ...notifications.map(
                            (notification) => _NotificationTile(
                              notification: notification,
                              onTap: () => _markAsRead(notification),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UnreadSummary extends StatelessWidget {
  final int unreadCount;

  const _UnreadSummary({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.orange.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unreadCount == 0
                  ? 'كل التنبيهات مقروءة'
                  : 'لديك $unreadCount تنبيهات غير مقروءة',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isUnread ? AppColors.surfaceHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnread
                    ? AppColors.orange.withValues(alpha: .45)
                    : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(notification.icon, color: AppColors.orange),
                    ),
                    if (isUnread)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            notification.timeLabel,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              notification.title,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.body,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.notifications_off_rounded,
          size: 76,
          color: AppColors.orange,
        ),
        const SizedBox(height: 14),
        const Text(
          'لا توجد تنبيهات حالياً',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'أي تحديثات مهمة عن الدروس أو الكورسات أو الاختبارات هتظهر هنا.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
      ],
    );
  }
}
