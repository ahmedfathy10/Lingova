// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/exam.dart';
import '../../data/services/auth_storage_service.dart';
import '../../data/services/exam_api_service.dart';
import 'certificate_page.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  late Future<StudentExamBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
  }

  Future<StudentExamBundle> _loadBundle() async {
    final user = await AuthStorageService.loadUser();
    if (user == null) {
      return const StudentExamBundle(exams: [], results: []);
    }
    return ExamApiService().getStudentExams(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الشهادات')),
        body: SafeArea(
          child: FutureBuilder<StudentExamBundle>(
            future: _bundleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _Notice(
                  text: 'تعذر تحميل الشهادات. حاول مرة أخرى لاحقاً.',
                );
              }

              final bundle =
                  snapshot.data ??
                  const StudentExamBundle(exams: [], results: []);
              final results = bundle.results
                  .where((result) => result.type == 'level_final')
                  .toList();

              if (results.isEmpty) {
                return _Notice(
                  text:
                      'لا توجد شهادات نهائية متاحة حالياً. أكمل امتحان نهاية المستوى للحصول على شهادة.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(22),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _CertificateCard(
                    result: result,
                    onOpen: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CertificatePage(result: result),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final ExamResult result;
  final VoidCallback onOpen;

  const _CertificateCard({required this.result, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final statusColor = result.passed ? Colors.green : Colors.redAccent;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          result.courseTitle,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${result.levelTitle} • ${result.typeLabel}',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      result.passed ? 'ناجح' : 'لم ينجح',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.score_rounded, size: 18, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${result.score}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(result.submittedAtLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
