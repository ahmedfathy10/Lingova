import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/datasources/course_api_datasource.dart';
import '../../data/datasources/notification_api_datasource.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/watch_progress_record.dart';
import '../../data/services/auth_api_service.dart';
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
  final _authApiService = AuthApiService();
  final _courseDataSource = CourseApiDataSource();
  final _watchProgressService = WatchProgressApiService();
  late Future<List<Course>> _coursesFuture;
  late Future<List<AppNotification>> _notificationsFuture;
  late Future<_LastVideoSummary?> _lastVideoFuture;
  late Future<AppStreak?> _streakFuture;

  NotificationApiDataSource get _notificationsDataSource =>
      NotificationApiDataSource(user: widget.user);

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseDataSource.getCourses();
    _notificationsFuture = _notificationsDataSource.getNotifications(
      unreadOnly: true,
    );
    _lastVideoFuture = _loadLastVideo();
    _streakFuture = _loadStreak();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.id != widget.user?.id ||
        oldWidget.user?.enrollments.length != widget.user?.enrollments.length) {
      _notificationsFuture = _notificationsDataSource.getNotifications(
        unreadOnly: true,
      );
      _lastVideoFuture = _loadLastVideo();
      _streakFuture = _loadStreak();
    }
  }

  Future<AppStreak?> _loadStreak() async {
    final user = widget.user;
    if (user == null || user.id.isEmpty) {
      return null;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _authApiService.getAppStreak(user.id);
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsScreen(user: widget.user)),
    );

    if (mounted) {
      setState(() {
        _notificationsFuture = _notificationsDataSource.getNotifications(
          unreadOnly: true,
        );
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
            onVideoWatched: (completedPart) =>
                _watchProgressService.completePart(
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
                  const SizedBox(height: 16),
                  FutureBuilder<AppStreak?>(
                    future: _streakFuture,
                    builder: (context, snapshot) {
                      return _StreakCard(
                        streak: snapshot.data?.streak ?? 0,
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                      );
                    },
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

class _StreakCard extends StatefulWidget {
  final int streak;
  final bool isLoading;

  const _StreakCard({required this.streak, required this.isLoading});

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.isLoading
        ? 0.0
        : (widget.streak / 7).clamp(0.06, 1.0).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, introValue, child) {
        return Opacity(
          opacity: introValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - introValue)),
            child: child,
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.orange.withValues(alpha: .24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: .14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.orange.withValues(alpha: .20),
              AppColors.surface,
              AppColors.surfaceHigh.withValues(alpha: .72),
            ],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -24,
              top: -18,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 118,
                color: AppColors.orange.withValues(alpha: .07),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          final scale = 1 + (_pulse.value * .08);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFFFB15D), AppColors.orange],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orange.withValues(
                                      alpha: .22 + (_pulse.value * .18),
                                    ),
                                    blurRadius: 18 + (_pulse.value * 10),
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Streak',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'الأيام المتتالية',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.isLoading
                                  ? 'جاري حساب نشاطك...'
                                  : 'استخدمت التطبيق ${widget.streak} يوم متتالي',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        constraints: const BoxConstraints(minWidth: 62),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: .20),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: widget.isLoading
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : TweenAnimationBuilder<int>(
                                  key: ValueKey(widget.streak),
                                  tween: IntTween(begin: 0, end: widget.streak),
                                  duration: const Duration(milliseconds: 650),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) {
                                    return Text(
                                      value.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontSize: 34,
                                        height: 1,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: AppColors.border.withValues(alpha: .55),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 720),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerRight,
                                widthFactor: value,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFB15D),
                                        AppColors.orange,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: AppColors.orange.withValues(alpha: .9),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.isLoading
                              ? 'بنراجع آخر نشاط ليك'
                              : widget.streak >= 7
                              ? 'أسبوع كامل من الاستمرارية'
                              : 'كمّل 7 أيام وافتح إنجاز جديد',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
