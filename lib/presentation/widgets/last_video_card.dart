import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/watch_progress_record.dart';

class LastVideoCard extends StatelessWidget {
  final WatchProgressRecord? record;
  final int completedParts;
  final int totalParts;
  final bool isLoading;
  final VoidCallback? onTap;

  const LastVideoCard({
    super.key,
    this.record,
    this.completedParts = 0,
    this.totalParts = 0,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: record == null || isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .32),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: isLoading
                ? const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        textDirection: TextDirection.ltr,
                        children: [
                          Container(
                            width: 118,
                            height: 92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  AppColors.surfaceHigh,
                                  const Color(0xFF0E1118),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'آخر فيديو شاهدته',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _courseTitle,
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          _partTitle,
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: _courseProgress,
                        minHeight: 7,
                        color: AppColors.orange,
                        backgroundColor: Colors.white12,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          _progressLabel,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String get _courseTitle {
    final current = record;
    if (current == null) {
      return 'لا يوجد فيديو بعد';
    }
    return '${current.courseLanguage} - ${current.courseTitle}';
  }

  String get _partTitle {
    final current = record;
    if (current == null) {
      return 'شاهد أي درس وسيظهر آخر فيديو هنا';
    }
    final prefix = current.lectureTitle.trim().isEmpty
        ? ''
        : '${current.lectureTitle.trim()} - ';
    return '$prefix${current.partTitle.trim()}';
  }

  double get _courseProgress {
    if (record == null || totalParts <= 0) {
      return 0;
    }
    return (completedParts / totalParts).clamp(0, 1).toDouble();
  }

  String get _progressLabel {
    if (record == null) {
      return 'ابدأ مشاهدة أول فيديو ليظهر هنا';
    }
    if (totalParts <= 0) {
      return 'اضغط للتشغيل';
    }
    final percent = (_courseProgress * 100).round();
    return '$percent% من الكورس مكتمل ($completedParts / $totalParts أجزاء)';
  }
}
