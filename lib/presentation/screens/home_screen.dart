import 'package:flutter/material.dart';

import '../../data/datasources/course_api_datasource.dart';
import '../../data/datasources/notification_api_datasource.dart';
import '../../data/models/auth_user.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/course.dart';
import '../widgets/course_section.dart';
import '../widgets/header_section.dart';
import '../widgets/last_video_card.dart';
import 'course_details_screen.dart';
import 'courses_page.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser? user;
  final String? userName;
  final ValueChanged<CourseFilter>? onViewCourses;

  const HomeScreen({super.key, this.user, this.userName, this.onViewCourses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _notificationsDataSource = NotificationApiDataSource();
  final _courseDataSource = CourseApiDataSource();
  late Future<List<Course>> _coursesFuture;
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseDataSource.getCourses();
    _notificationsFuture = _notificationsDataSource.getNotifications();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));

    if (mounted) {
      setState(() {
        _notificationsFuture = _notificationsDataSource.getNotifications();
      });
    }
  }

  void _openCourse(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailsScreen(course: course, user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, notificationSnapshot) {
          final notifications =
              notificationSnapshot.data ?? const <AppNotification>[];
          final unreadNotificationsCount = notifications
              .where((notification) => !notification.isRead)
              .length;

          return FutureBuilder<List<Course>>(
            future: _coursesFuture,
            builder: (context, courseSnapshot) {
              final courses = courseSnapshot.data ?? const <Course>[];
              final englishCourses = courses
                  .where((course) => course.language == 'الإنجليزية')
                  .toList();
              final germanCourses = courses
                  .where((course) => course.language == 'الألمانية')
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  HeaderSection(
                    userName: widget.userName,
                    unreadNotificationsCount: unreadNotificationsCount,
                    onNotificationsTap: _openNotifications,
                  ),
                  const SizedBox(height: 26),
                  const LastVideoCard(),
                  const SizedBox(height: 30),
                  if (courseSnapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (courseSnapshot.hasError)
                    _HomeCoursesMessage(
                      message: 'تعذر تحميل الكورسات من لوحة التحكم.',
                      onRetry: () => setState(() {
                        _coursesFuture = _courseDataSource.getCourses();
                      }),
                    )
                  else ...[
                    CourseSection(
                      title: 'كورسات اللغة الإنجليزية',
                      courses: englishCourses,
                      user: widget.user,
                      onViewAll: () {
                        widget.onViewCourses?.call(CourseFilter.english);
                      },
                      onCourseTap: _openCourse,
                    ),
                    const SizedBox(height: 30),
                    CourseSection(
                      title: 'كورسات اللغة الألمانية',
                      courses: germanCourses,
                      user: widget.user,
                      onViewAll: () {
                        widget.onViewCourses?.call(CourseFilter.german);
                      },
                      onCourseTap: _openCourse,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeCoursesMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeCoursesMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }
}
