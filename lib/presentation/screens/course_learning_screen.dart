import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/vimeo_iframe_widget.dart';
import '../../core/app_colors.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/course_question.dart';
import '../../data/models/exam.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/exam_api_service.dart';
import '../../data/services/question_api_service.dart';
import '../../data/services/watch_progress_api_service.dart';
import '../../domain/entities/course_content.dart';
import 'exams_page.dart';

class CourseLearningScreen extends StatefulWidget {
  final CourseContent content;
  final AuthUser user;

  const CourseLearningScreen({
    super.key,
    required this.content,
    required this.user,
  });

  @override
  State<CourseLearningScreen> createState() => _CourseLearningScreenState();
}

class _CourseLearningScreenState extends State<CourseLearningScreen> {
  final _watchProgressService = WatchProgressApiService();
  final _examService = ExamApiService();
  final Set<String> _watchedParts = {};
  List<CourseExam> _exams = [];
  List<ExamResult> _examResults = [];
  bool _isLoadingProgress = true;

  int get _levelsCount => widget.content.levels.length;

  int get _lecturesCount => widget.content.levels.fold(
    0,
    (sum, level) => sum + level.lectures.length,
  );

  int get _partsCount => widget.content.levels.fold(
    0,
    (sum, level) =>
        sum +
        level.lectures.fold(
          0,
          (total, lecture) => total + lecture.parts.length,
        ),
  );

  double get _overallProgress {
    if (_partsCount == 0) {
      return 0;
    }
    return (_watchedParts.length / _partsCount).clamp(0, 1);
  }

  @override
  void initState() {
    super.initState();
    _loadWatchProgress();
    _loadExamState();
  }

  Future<void> _loadWatchProgress() async {
    try {
      final records = await _watchProgressService.getCourseProgress(
        studentId: widget.user.id,
        courseTitle: widget.content.title,
        courseLanguage: widget.content.language,
      );
      if (!mounted) return;
      setState(() {
        _watchedParts
          ..clear()
          ..addAll(records.map((record) => record.vimeoUrl));
        _isLoadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProgress = false);
    }
  }

  Future<void> _markPartCompleted(
    CoursePartContent part,
    CourseLectureContent lecture,
    CourseLevelContent level,
  ) async {
    if (_watchedParts.contains(part.vimeoUrl)) {
      return;
    }

    try {
      await _watchProgressService.completePart(
        studentId: widget.user.id,
        content: widget.content,
        level: level,
        lecture: lecture,
        part: part,
      );
      if (!mounted) return;
      setState(() => _watchedParts.add(part.vimeoUrl));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تسجيل مشاهدة الجزء.', textAlign: TextAlign.right),
        ),
      );
    }
  }

  Future<void> _loadExamState() async {
    try {
      final bundle = await _examService.getStudentExams(widget.user.id);
      if (!mounted) return;
      setState(() {
        _exams = bundle.exams
            .where(
              (exam) =>
                  exam.courseTitle == widget.content.title &&
                  exam.courseLanguage == widget.content.language,
            )
            .toList();
        _examResults = bundle.results;
      });
    } catch (_) {}
  }

  bool _isExamPassed(CourseExam exam) {
    return _examResults.any(
      (result) => result.examId == exam.id && result.passed,
    );
  }

  CourseExam? _quizAfter(CourseLevelContent level, int lectureNumber) {
    for (final exam in _exams) {
      if (exam.type == 'lecture_quiz' &&
          exam.levelTitle == level.title &&
          exam.afterLectureIndex == lectureNumber) {
        return exam;
      }
    }
    return null;
  }

  CourseExam? _levelFinal(CourseLevelContent level) {
    for (final exam in _exams) {
      if (exam.type == 'level_final' && exam.levelTitle == level.title) {
        return exam;
      }
    }
    return null;
  }

  bool _isLectureCompleted(CourseLectureContent lecture) {
    return lecture.parts.isNotEmpty &&
        lecture.parts.every((part) => _watchedParts.contains(part.vimeoUrl));
  }

  bool _isLevelUnlocked(int levelIndex) {
    if (levelIndex == 0) {
      return true;
    }
    final previousLevel = widget.content.levels[levelIndex - 1];
    final finalExam = _levelFinal(previousLevel);
    return finalExam != null && _isExamPassed(finalExam);
  }

  bool _isLectureUnlocked(
    CourseLevelContent level,
    int levelIndex,
    int lectureIndex,
  ) {
    if (!_isLevelUnlocked(levelIndex)) {
      return false;
    }
    if (lectureIndex == 0) {
      return true;
    }

    final previousLecture = level.lectures[lectureIndex - 1];
    if (!_isLectureCompleted(previousLecture)) {
      return false;
    }

    final gateExam = _quizAfter(level, lectureIndex);
    return gateExam == null || _isExamPassed(gateExam);
  }

  Future<void> _openExam(CourseExam exam) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamTakeScreen(exam: exam, studentId: widget.user.id),
      ),
    );
    await _loadExamState();
  }

  void _openPart(
    CoursePartContent part,
    CourseLectureContent lecture,
    CourseLevelContent level,
  ) {
    final uri = Uri.tryParse(part.vimeoUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرابط غير صالح لعرض الفيديو.',
            textAlign: TextAlign.right,
          ),
        ),
      );
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => VimeoPlayerScreen(
              title: part.title,
              url: part.vimeoUrl,
              content: widget.content,
              user: widget.user,
              level: level,
              lecture: lecture,
              parts: lecture.parts,
              completedUrls: _watchedParts,
              onVideoWatched: (completedPart) =>
                  _markPartCompleted(completedPart, lecture, level),
            ),
          ),
        )
        .then((_) => _loadWatchProgress());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.content.title), elevation: 0),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            children: [
              _LearningHero(
                title: widget.content.title,
                language: widget.content.language,
                levelsCount: _levelsCount,
                lecturesCount: _lecturesCount,
                partsCount: _partsCount,
                progress: _overallProgress,
              ),
              if (_isLoadingProgress) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppColors.surfaceHigh,
                ),
              ],
              const SizedBox(height: 18),
              if (widget.content.levels.isEmpty)
                _LearningPanel(
                  child: Text(
                    'لا يوجد محتوى داخل هذا الكورس حتى الآن.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ...widget.content.levels.asMap().entries.map((entry) {
                  final levelIndex = entry.key;
                  final level = entry.value;
                  return _buildLevelSection(level, levelIndex);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSection(CourseLevelContent level, int levelIndex) {
    final lectureCount = level.lectures.length;
    final partCount = _levelPartsCount(level);
    final watchedCount = _watchedPartsForLevel(level);
    final progress = partCount == 0 ? 0.0 : watchedCount / partCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: levelIndex == 0,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: _LevelNumberBadge(number: levelIndex + 1),
            title: Text(
              level.title,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$lectureCount محاضرات • $partCount أجزاء',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: progress,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: _buildLevelChildren(level, levelIndex),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLevelChildren(CourseLevelContent level, int levelIndex) {
    if (level.lectures.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'لا توجد محاضرات داخل هذا المستوى.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ];
    }

    final children = <Widget>[];
    for (final entry in level.lectures.asMap().entries) {
      final lectureIndex = entry.key;
      final lecture = entry.value;
      children.add(
        _buildLectureTile(
          lecture: lecture,
          lectureIndex: lectureIndex,
          levelIndex: levelIndex,
          level: level,
        ),
      );

      final quiz = _quizAfter(level, lectureIndex + 1);
      if (quiz != null) {
        children.add(
          _ExamGateCard(
            exam: quiz,
            isPassed: _isExamPassed(quiz),
            isUnlocked: _isLectureCompleted(lecture),
            onTap: () => _openExam(quiz),
          ),
        );
      }
    }

    final finalExam = _levelFinal(level);
    if (finalExam != null) {
      children.add(
        _ExamGateCard(
          exam: finalExam,
          isPassed: _isExamPassed(finalExam),
          isUnlocked: level.lectures.every(_isLectureCompleted),
          onTap: () => _openExam(finalExam),
        ),
      );
    }

    return children;
  }

  int _levelPartsCount(CourseLevelContent level) {
    return level.lectures.fold(
      0,
      (total, lecture) => total + lecture.parts.length,
    );
  }

  int _watchedPartsForLevel(CourseLevelContent level) {
    return level.lectures.fold(
      0,
      (total, lecture) =>
          total +
          lecture.parts
              .where((part) => _watchedParts.contains(part.vimeoUrl))
              .length,
    );
  }

  Widget _buildLectureTile({
    required CourseLectureContent lecture,
    required int lectureIndex,
    required int levelIndex,
    required CourseLevelContent level,
  }) {
    final watchedCount = lecture.parts
        .where((part) => _watchedParts.contains(part.vimeoUrl))
        .length;
    final isCompleted =
        lecture.parts.isNotEmpty && watchedCount == lecture.parts.length;
    final isUnlocked = _isLectureUnlocked(level, levelIndex, lectureIndex);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: AppColors.surfaceHigh.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: lecture.parts.isEmpty || !isUnlocked
              ? null
              : () => _openPart(lecture.parts[0], lecture, level),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_rounded
                        : isUnlocked
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                    color: isCompleted
                        ? Colors.white
                        : isUnlocked
                        ? AppColors.orange
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lecture.title,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${lecture.parts.length} أجزاء • $watchedCount تمت مشاهدتها',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${lectureIndex + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w900,
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

class _LearningHero extends StatelessWidget {
  final String title;
  final String language;
  final int levelsCount;
  final int lecturesCount;
  final int partsCount;
  final double progress;

  const _LearningHero({
    required this.title,
    required this.language,
    required this.levelsCount,
    required this.lecturesCount,
    required this.partsCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.orange.withValues(alpha: .95),
            const Color(0xFF2A1D4A),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ابدأ من المستوى الأول وكمل تقدمك خطوة بخطوة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _HeroChip(icon: Icons.translate_rounded, label: language),
              _HeroChip(
                icon: Icons.layers_rounded,
                label: '$levelsCount مستويات',
              ),
              _HeroChip(
                icon: Icons.menu_book_rounded,
                label: '$lecturesCount محاضرات',
              ),
              _HeroChip(
                icon: Icons.play_circle_rounded,
                label: '$partsCount أجزاء',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تقدمك',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNumberBadge extends StatelessWidget {
  final int number;

  const _LevelNumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: .35)),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExamGateCard extends StatelessWidget {
  final CourseExam exam;
  final bool isPassed;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _ExamGateCard({
    required this.exam,
    required this.isPassed,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPassed
        ? Colors.green
        : isUnlocked
        ? AppColors.orange
        : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isUnlocked ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  isPassed
                      ? Icons.check_circle_rounded
                      : isUnlocked
                      ? Icons.quiz_rounded
                      : Icons.lock_rounded,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        exam.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPassed
                            ? 'تم النجاح'
                            : isUnlocked
                            ? 'اضغط لفتح الامتحان'
                            : 'مغلق حتى تكمل المطلوب قبله',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: AppColors.textMuted),
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

class VimeoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final CourseContent content;
  final AuthUser user;
  final CourseLevelContent level;
  final CourseLectureContent lecture;
  final List<CoursePartContent> parts;
  final Set<String> completedUrls;
  final Future<void> Function(CoursePartContent part) onVideoWatched;

  const VimeoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.content,
    required this.user,
    required this.level,
    required this.lecture,
    required this.parts,
    required this.completedUrls,
    required this.onVideoWatched,
  });

  @override
  State<VimeoPlayerScreen> createState() => _VimeoPlayerScreenState();
}

class _VimeoPlayerScreenState extends State<VimeoPlayerScreen> {
  final _questionService = QuestionApiService();
  final Set<String> _completedUrls = {};
  Timer? _completionTimer;
  late String _currentVideoUrl;
  late Future<List<CourseQuestion>> _questionsFuture;
  bool _isSendingQuestion = false;

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.url;
    _completedUrls.addAll(widget.completedUrls);
    _questionsFuture = _loadQuestions();
    _startCompletionTimer();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  Future<List<CourseQuestion>> _loadQuestions() {
    return _questionService.getStudentQuestions(
      studentId: widget.user.id,
      courseTitle: widget.content.title,
      courseLanguage: widget.content.language,
    );
  }

  CoursePartContent get _currentPart {
    return widget.parts.firstWhere(
      (part) => part.vimeoUrl == _currentVideoUrl,
      orElse: () => widget.parts.first,
    );
  }

  void _refreshQuestions() {
    setState(() => _questionsFuture = _loadQuestions());
  }

  void _startCompletionTimer() {
    _completionTimer?.cancel();
    final part = _currentPart;
    if (_completedUrls.contains(part.vimeoUrl)) {
      return;
    }

    final seconds = _parseDurationToSeconds(part.duration);
    final waitSeconds = seconds <= 0 ? 5 : seconds;
    _completionTimer = Timer(Duration(seconds: waitSeconds), () async {
      await widget.onVideoWatched(part);
      if (!mounted) return;
      setState(() => _completedUrls.add(part.vimeoUrl));
      _showMessage('تم تسجيل مشاهدة الجزء بالكامل.');
    });
  }

  int _parseDurationToSeconds(String duration) {
    final parts = duration.trim().split(':');
    if (parts.length != 3) {
      return 0;
    }
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  void _selectPart(CoursePartContent part) {
    setState(() {
      _currentVideoUrl = part.vimeoUrl;
    });
    _startCompletionTimer();
  }

  Future<void> _askQuestion() async {
    final controller = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اسأل سؤالاً'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'اكتب سؤالك عن هذا الجزء',
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    final text = question?.trim() ?? '';
    if (text.isEmpty) {
      return;
    }

    setState(() => _isSendingQuestion = true);
    try {
      final part = _currentPart;
      await _questionService.createQuestion({
        'studentId': widget.user.id,
        'courseTitle': widget.content.title,
        'courseLanguage': widget.content.language,
        'levelTitle': widget.level.title,
        'lectureTitle': widget.lecture.title,
        'partTitle': part.title,
        'vimeoUrl': part.vimeoUrl,
        'question': text,
      });
      if (!mounted) return;
      _showMessage('تم إرسال السؤال. سيظهر الرد هنا بعد مراجعة الأدمن.');
      _refreshQuestions();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر إرسال السؤال.');
    } finally {
      if (mounted) {
        setState(() => _isSendingQuestion = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lecture.title), elevation: 0),
        body: _buildPlayerLayout(),
      ),
    );
  }

  Widget _buildPlayerLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Level and Lecture Info
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.level.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lecture.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Video Player
          Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: VimeoIframeWidget(url: _currentVideoUrl),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parts Icons
                _buildPartsIcons(),
                const SizedBox(height: 24),

                // Questions and Answers Section
                _buildCourseQuestionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsIcons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أجزاء الدرس',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...widget.parts.asMap().entries.map((entry) {
                final index = entry.key;
                final part = entry.value;
                final isCurrentVideo = part.vimeoUrl == _currentVideoUrl;
                final isCompleted = _completedUrls.contains(part.vimeoUrl);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => _selectPart(part),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : isCurrentVideo
                                ? AppColors.orange
                                : AppColors.surface,
                            border: Border.all(
                              color: isCurrentVideo
                                  ? AppColors.orange
                                  : AppColors.border,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.play_circle_fill,
                                color: isCurrentVideo || isCompleted
                                    ? Colors.white
                                    : AppColors.textMuted,
                                size: 32,
                              ),
                              if (isCompleted)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'الجزء ${index + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrentVideo
                                  ? AppColors.orange
                                  : AppColors.textMuted,
                              fontWeight: isCurrentVideo
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseQuestionsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أسئلة الطلاب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<CourseQuestion>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final questions = (snapshot.data ?? const <CourseQuestion>[])
                  .where((question) => question.vimeoUrl == _currentVideoUrl)
                  .toList();

              if (snapshot.hasError) {
                return const _QuestionNotice(
                  text: 'تعذر تحميل الأسئلة. حاول التحديث بعد قليل.',
                );
              }

              if (questions.isEmpty) {
                return const _QuestionNotice(
                  text: 'لا توجد أسئلة حتى الآن. كن أول من يسأل!',
                );
              }

              return Column(
                children: [
                  ...questions.map(
                    (question) => _QuestionTile(question: question),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSendingQuestion ? null : _askQuestion,
              icon: _isSendingQuestion
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                _isSendingQuestion ? 'جاري الإرسال...' : 'اسأل سؤالاً',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildQuestionsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أسئلة الطلاب',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'لا توجد أسئلة حتى الآن. كن أول من يسأل!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to question creation screen
              },
              icon: const Icon(Icons.add),
              label: const Text('اسأل سؤالاً'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionNotice extends StatelessWidget {
  final String text;

  const _QuestionNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final CourseQuestion question;

  const _QuestionTile({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.question,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (question.isAnswered)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.answer,
                textAlign: TextAlign.right,
                style: const TextStyle(height: 1.4),
              ),
            )
          else
            Text(
              'بانتظار رد الأدمن',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _LearningPanel extends StatelessWidget {
  final Widget child;

  const _LearningPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
