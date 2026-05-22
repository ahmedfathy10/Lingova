import 'package:flutter/material.dart';

import '../../data/datasources/course_api_datasource.dart';
import '../../data/datasources/notification_api_datasource.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/watch_progress_record.dart';
import '../../data/services/watch_progress_api_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_content.dart';
import '../widgets/course_section.dart';
import '../widgets/header_section.dart';
import '../widgets/last_video_card.dart';
import 'course_details_screen.dart';
import 'course_learning_screen.dart';
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
  final _courseDataSource = CourseApiDataSource();
  final _watchProgressService = WatchProgressApiService();
  late Future<List<Course>> _coursesFuture;
  late Future<List<AppNotification>> _notificationsFuture;
  late Future<_LastVideoSummary?> _lastVideoFuture;

  NotificationApiDataSource get _notificationsDataSource =>
      NotificationApiDataSource(user: widget.user);

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseDataSource.getCourses();
    _notificationsFuture = _notificationsDataSource.getNotifications();
    _lastVideoFuture = _loadLastVideo();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.id != widget.user?.id ||
        oldWidget.user?.enrollments.length != widget.user?.enrollments.length) {
      _notificationsFuture = _notificationsDataSource.getNotifications();
      _lastVideoFuture = _loadLastVideo();
    }
  }

  Future<_LastVideoSummary?> _loadLastVideo() async {
    final user = widget.user;
    if (user == null || user.id.isEmpty || user.enrollments.isEmpty) {
      return null;
    }
    final record = await _watchProgressService.getLatestProgressForUser(user);
    if (record == null) {
      return null;
    }

    try {
      final content = await _courseDataSource.getCourseContentByTitle(
        studentId: user.id,
        courseTitle: record.courseTitle,
        courseLanguage: record.courseLanguage,
      );
      final progressRecords = await _watchProgressService.getCourseProgress(
        studentId: user.id,
        courseTitle: record.courseTitle,
        courseLanguage: record.courseLanguage,
      );
      final coursePartUrls = content.levels
          .expand((level) => level.lectures)
          .expand((lecture) => lecture.parts)
          .map((part) => part.vimeoUrl)
          .where((url) => url.isNotEmpty)
          .toSet();
      final completedUrls = progressRecords
          .map((progress) => progress.vimeoUrl)
          .where(coursePartUrls.contains)
          .toSet();

      return _LastVideoSummary(
        record: record,
        completedParts: completedUrls.length,
        totalParts: coursePartUrls.length,
      );
    } catch (_) {
      return _LastVideoSummary(record: record);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(builder: (_) => NotificationsScreen(user: widget.user)),
    );

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

  Future<void> _openLastVideo(WatchProgressRecord record) async {
    final user = widget.user;
    if (user == null || user.id.isEmpty) {
      return;
    }

    try {
      final content = await _courseDataSource.getCourseContentByTitle(
        studentId: user.id,
        courseTitle: record.courseTitle,
        courseLanguage: record.courseLanguage,
      );
      final location = _findPartLocation(content, record);
      if (location == null || !mounted) {
        _showMessage('تعذر العثور على الفيديو داخل الكورس.');
        return;
      }

      final progressRecords = await _watchProgressService.getCourseProgress(
        studentId: user.id,
        courseTitle: record.courseTitle,
        courseLanguage: record.courseLanguage,
      );
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VimeoPlayerScreen(
            title: location.part.title,
            url: location.part.vimeoUrl,
            content: content,
            user: user,
            level: location.level,
            lecture: location.lecture,
            parts: location.lecture.parts,
            completedUrls: progressRecords
                .map((progress) => progress.vimeoUrl)
                .toSet(),
            onVideoWatched: (completedPart) => _watchProgressService.completePart(
              studentId: user.id,
              content: content,
              level: location.level,
              lecture: location.lecture,
              part: completedPart,
            ),
          ),
        ),
      );

      if (mounted) {
        setState(() => _lastVideoFuture = _loadLastVideo());
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر تشغيل آخر فيديو. حاول مرة أخرى.');
    }
  }

  _PartLocation? _findPartLocation(
    CourseContent content,
    WatchProgressRecord record,
  ) {
    for (final level in content.levels) {
      for (final lecture in level.lectures) {
        for (final part in lecture.parts) {
          if (part.vimeoUrl == record.vimeoUrl ||
              (part.title == record.partTitle &&
                  lecture.title == record.lectureTitle &&
                  level.title == record.levelTitle)) {
            return _PartLocation(level: level, lecture: lecture, part: part);
          }
        }
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
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
                  FutureBuilder<_LastVideoSummary?>(
                    future: _lastVideoFuture,
                    builder: (context, lastVideoSnapshot) {
                      final summary = lastVideoSnapshot.data;
                      final record = summary?.record;
                      return LastVideoCard(
                        record: record,
                        completedParts: summary?.completedParts ?? 0,
                        totalParts: summary?.totalParts ?? 0,
                        isLoading:
                            lastVideoSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            record == null,
                        onTap: record == null
                            ? null
                            : () => _openLastVideo(record),
                      );
                    },
                  ),
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

class _PartLocation {
  final CourseLevelContent level;
  final CourseLectureContent lecture;
  final CoursePartContent part;

  const _PartLocation({
    required this.level,
    required this.lecture,
    required this.part,
  });
}

class _LastVideoSummary {
  final WatchProgressRecord record;
  final int completedParts;
  final int totalParts;

  const _LastVideoSummary({
    required this.record,
    this.completedParts = 0,
    this.totalParts = 0,
  });
}
