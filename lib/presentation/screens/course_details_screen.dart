import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/datasources/course_api_datasource.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/subscription_api_service.dart';
import '../../domain/entities/course.dart';
import 'course_learning_screen.dart';

ImageProvider<Object>? _courseImageProvider(String imageDataUrl) {
  if (imageDataUrl.isEmpty) {
    return null;
  }
  if (imageDataUrl.startsWith('data:')) {
    try {
      final data = Uri.parse(imageDataUrl).data;
      return data == null ? null : MemoryImage(data.contentAsBytes());
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(imageDataUrl);
}

class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  final AuthUser? user;

  const CourseDetailsScreen({super.key, required this.course, this.user});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final _subscriptionService = SubscriptionApiService();
  final _courseDataSource = CourseApiDataSource();
  final _authApiService = AuthApiService();
  AuthUser? _freshUser;
  bool _isSubmitting = false;
  bool _isOpeningContent = false;

  Course get course => widget.course;
  AuthUser? get _currentUser => _freshUser ?? widget.user;
  bool get _isEnrolled =>
      _currentUser?.hasCourse(course.language, course.title) ?? false;

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    final user = widget.user;
    if (user == null || user.id.isEmpty) {
      return;
    }
    try {
      final freshUser = await _authApiService.getUser(user.id);
      if (!mounted) return;
      setState(() => _freshUser = freshUser);
    } catch (_) {}
  }

  Future<void> _openLearning() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isOpeningContent = true);
    try {
      final content = await _courseDataSource.getCourseContent(
        studentId: user.id,
        course: course,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CourseLearningScreen(content: content, user: user),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر تحميل محتوى الكورس.');
    } finally {
      if (mounted) {
        setState(() => _isOpeningContent = false);
      }
    }
  }

  Future<void> _requestSubscription() async {
    final user = _currentUser;
    if (user == null || user.id.isEmpty) {
      _showMessage('سجل الدخول بحساب طالب قبل إرسال طلب الاشتراك.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _subscriptionService.createRequest(user: user, course: course);
      if (!mounted) return;
      _showMessage('تم إرسال طلب الاشتراك في ${course.title}.');
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر إرسال طلب الاشتراك. تأكد أن السيرفر يعمل.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(message, textAlign: TextAlign.right),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFree = course.price == 'مجانا';
    final showPrice = !_isEnrolled;
    final imageProvider = _courseImageProvider(course.imageDataUrl);
    final hasImage = imageProvider != null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(course.title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: 5 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [AppColors.orange, AppColors.surfaceHigh],
                        ),
                        image: hasImage
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (!hasImage)
                            Center(
                              child: Icon(
                                course.icon,
                                size: 86,
                                color: Colors.white,
                              ),
                            ),
                          PositionedDirectional(
                            start: 18,
                            bottom: 18,
                            child: _Badge(text: course.levelBadge),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 22),
              Text(
                course.title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                course.description,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.translate_rounded,
                      label: 'اللغة',
                      value: course.language,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'المستوى',
                      value: course.level,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.play_lesson_rounded,
                      label: 'الدروس',
                      value: course.lessonsCount,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'المدة',
                      value: course.duration,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    if (showPrice && !isFree) ...[
                      Text(
                        'جنيه',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                    if (showPrice)
                      Text(
                        course.price,
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    else
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'تم الشراء',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _isSubmitting || _isOpeningContent
                          ? null
                          : _isEnrolled
                          ? _openLearning
                          : _requestSubscription,
                      icon: _isSubmitting || _isOpeningContent
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isEnrolled
                                  ? Icons.play_arrow_rounded
                                  : Icons.check_circle_rounded,
                            ),
                      label: Text(
                        _isOpeningContent
                            ? 'جاري الفتح...'
                            : _isSubmitting
                            ? 'جاري الإرسال...'
                            : _isEnrolled
                            ? 'ابدأ التعلم'
                            : 'اشترك الآن',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
