import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/exam.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/exam_api_service.dart';
import 'certificate_page.dart';

class ExamsPage extends StatefulWidget {
  final AuthUser? user;

  const ExamsPage({super.key, this.user});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final _service = ExamApiService();
  late Future<StudentExamBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudentExamBundle> _load() {
    final user = widget.user;
    if (user == null) {
      return Future.value(const StudentExamBundle(exams: [], results: []));
    }
    return _service.getStudentExams(user.id);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _openExam(CourseExam exam) async {
    final user = widget.user;
    if (user == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamTakeScreen(exam: exam, studentId: user.id),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final enrolledKeys =
        widget.user?.enrollments.map((item) => item.courseKey).toSet() ??
        const <String>{};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: FutureBuilder<StudentExamBundle>(
          future: _future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final bundle = snapshot.data;
            final exams = (bundle?.exams ?? const <CourseExam>[])
                .where(
                  (exam) =>
                      enrolledKeys.contains(
                        '${exam.courseLanguage}|${exam.courseTitle}',
                      ) ||
                      enrolledKeys.isEmpty,
                )
                .toList();
            final resultsByExam = <String, ExamResult>{};
            for (final result in bundle?.results ?? const <ExamResult>[]) {
              final current = resultsByExam[result.examId];
              final currentDate = DateTime.tryParse(current?.submittedAt ?? '');
              final resultDate = DateTime.tryParse(result.submittedAt);
              if (current == null ||
                  (resultDate != null &&
                      (currentDate == null ||
                          resultDate.isAfter(currentDate)))) {
                resultsByExam[result.examId] = result;
              }
            }

            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: isLoading ? null : _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    const Spacer(),
                    const Text(
                      'الامتحانات',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'الكويزات وامتحانات نهاية المستوى المطلوبة لفتح الدروس التالية.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  _Notice(text: 'تعذر تحميل الامتحانات.')
                else if (exams.isEmpty)
                  _Notice(text: 'لا توجد امتحانات متاحة لك حتى الآن.')
                else
                  ...exams.map(
                    (exam) => _ExamCard(
                      exam: exam,
                      result: resultsByExam[exam.id],
                      onStart: () => _openExam(exam),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final CourseExam exam;
  final ExamResult? result;
  final VoidCallback onStart;

  const _ExamCard({
    required this.exam,
    required this.result,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = result != null;
    final isPassed = result?.passed ?? false;
    final stateColor = isPassed
        ? Colors.green
        : isCompleted
        ? Colors.redAccent
        : AppColors.orange;
    final placement = exam.type == 'level_final'
        ? 'امتحان نهاية المستوى'
        : 'كويز بعد المحاضرة ${exam.afterLectureIndex}';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  isPassed
                      ? Icons.check_circle_rounded
                      : isCompleted
                      ? Icons.cancel_rounded
                      : Icons.quiz_rounded,
                  color: stateColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      exam.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${exam.courseTitle} • ${exam.levelTitle} • $placement',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: _ResultBadge(result: result!, color: stateColor),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              if (result != null) ...[
                _Meta(
                  icon: Icons.fact_check_rounded,
                  text: '${result!.correctAnswers}/${result!.totalQuestions}',
                ),
                const SizedBox(width: 10),
              ],
              _Meta(
                icon: Icons.quiz_rounded,
                text: '${exam.questions.length} سؤال',
              ),
              const SizedBox(width: 10),
              _Meta(
                icon: Icons.timer_rounded,
                text: '${exam.durationMinutes} دقيقة',
              ),
              const Spacer(),
              if (result != null && exam.type == 'level_final')
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CertificatePage(result: result!),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.orange,
                  ),
                  label: const Text('الشهادة'),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onStart,
                icon: Icon(
                  isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(isCompleted ? 'إعادة' : 'ابدأ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final ExamResult result;
  final Color color;

  const _ResultBadge({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        'نتيجتك ${result.score}% - ${result.statusLabel}',
        textAlign: TextAlign.right,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class ExamTakeScreen extends StatefulWidget {
  final CourseExam exam;
  final String studentId;

  const ExamTakeScreen({
    super.key,
    required this.exam,
    required this.studentId,
  });

  @override
  State<ExamTakeScreen> createState() => _ExamTakeScreenState();
}

class _ExamTakeScreenState extends State<ExamTakeScreen> {
  final _service = ExamApiService();
  final Map<String, dynamic> _answers = {};
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await _service.submitExam(
        studentId: widget.studentId,
        examId: widget.exam.id,
        answers: _answers,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(result.passed ? 'ناجح' : 'انتهى الاختبار'),
          content: Text(
            'درجتك ${result.score}% - ${result.correctAnswers}/${result.totalQuestions}',
            textAlign: TextAlign.right,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تمام'),
            ),
          ],
        ),
      );
      if (mounted) {
        if (widget.exam.type == 'level_final') {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CertificatePage(result: result)),
          );
        } else {
          _showMessage('هذا الكويز لا يصدر له شهادة رسمية. تم حفظ نتيجتك.');
        }
        if (mounted) Navigator.of(context).pop();
      }
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
        appBar: AppBar(title: Text(widget.exam.title)),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'درجة النجاح ${widget.exam.passScore}%',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            ...widget.exam.questions.map(_buildQuestion),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('إرسال الامتحان'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(ExamQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            question.prompt,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (question.type == 'complete' ||
              question.type == 'audio' ||
              question.type == 'video')
            TextField(
              textAlign: TextAlign.right,
              onChanged: (value) => _answers[question.id] = value,
              decoration: const InputDecoration(labelText: 'الإجابة'),
            )
          else
            ..._optionsFor(question).map((option) {
              return RadioListTile<String>(
                value: option,
                groupValue: _answers[question.id]?.toString(),
                onChanged: (value) {
                  setState(() => _answers[question.id] = value);
                },
                title: Text(
                  _optionLabel(question, option),
                  textAlign: TextAlign.right,
                ),
              );
            }),
        ],
      ),
    );
  }

  List<String> _optionsFor(ExamQuestion question) {
    if (question.type == 'true_false') {
      return const ['صح', 'خطأ'];
    }
    return question.options;
  }

  String _optionLabel(ExamQuestion question, String option) {
    if (question.type != 'true_false') {
      return option;
    }

    final normalized = option.trim().toLowerCase();
    final isTrueAnswer =
        normalized == 'صح' || normalized == 'true' || normalized == 'richtig';
    final isGermanCourse = _isGerman(widget.exam.courseLanguage);

    if (isGermanCourse) {
      return isTrueAnswer ? 'Richtig' : 'Falsch';
    }
    return isTrueAnswer ? 'True' : 'False';
  }

  bool _isGerman(String language) {
    final normalized = language.trim().toLowerCase();
    return normalized.contains('german') ||
        normalized.contains('deutsch') ||
        normalized.contains('ألماني') ||
        normalized.contains('الماني') ||
        normalized.contains('الألمانية') ||
        normalized.contains('الالمانية');
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}
