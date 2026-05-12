import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/auth_user.dart';
import '../../domain/entities/course.dart';
import 'course_card.dart';

class CourseSection extends StatelessWidget {
  final String title;
  final List<Course> courses;
  final AuthUser? user;
  final VoidCallback? onViewAll;
  final ValueChanged<Course>? onCourseTap;

  const CourseSection({
    super.key,
    required this.title,
    required this.courses,
    this.user,
    this.onViewAll,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              physics: const BouncingScrollPhysics(),
              itemCount: courses.length,
              separatorBuilder: (_, _) => SizedBox(width: 14),
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  course: course,
                  isPurchased:
                      user?.hasCourse(course.language, course.title) ?? false,
                  onTap: () => onCourseTap?.call(course),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
