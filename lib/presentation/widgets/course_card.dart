import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../domain/entities/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final bool isPurchased;
  final VoidCallback? onTap;
  static const double imageAspectRatio = 5 / 4;

  const CourseCard({
    super.key,
    required this.course,
    this.isPurchased = false,
    this.onTap,
  });

  Widget _buildImage() {
    final imageUrl = course.imageDataUrl;
    if (imageUrl.isEmpty) {
      return Center(child: Icon(course.icon, size: 52, color: Colors.white));
    }

    // Handle Base64 data URIs
    if (imageUrl.startsWith('data:')) {
      try {
        final uriData = Uri.parse(imageUrl).data;
        if (uriData != null) {
          final bytes = uriData.contentAsBytes();
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        }
      } catch (_) {
        // Fallback to icon if parsing fails
        return Center(child: Icon(course.icon, size: 52, color: Colors.white));
      }
    }

    // Handle network URLs
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) =>
            Center(child: Icon(course.icon, size: 52, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFree = course.price == 'مجانا';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 168,
            height: 270,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: AspectRatio(
                      aspectRatio: imageAspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [AppColors.orange, AppColors.surfaceHigh],
                          ),
                        ),
                        child: Stack(
                          children: [
                            _buildImage(),
                            PositionedDirectional(
                              start: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .42),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  course.levelBadge,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      course.title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'المستوى: ${course.level}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${course.lessonsCount} • ${course.duration}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (isPurchased)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: .35),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'تم الشراء',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (!isFree) ...[
                            Text(
                              'جنيه',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            course.price,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
