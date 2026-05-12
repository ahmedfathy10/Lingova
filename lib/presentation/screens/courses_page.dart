import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/datasources/course_api_datasource.dart';
import '../../data/models/auth_user.dart';
import '../../domain/entities/course.dart';
import 'course_details_screen.dart';

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

enum CourseFilter { all, english, german }

class CoursesPage extends StatefulWidget {
  final CourseFilter initialFilter;
  final AuthUser? user;

  const CoursesPage({
    super.key,
    this.initialFilter = CourseFilter.all,
    this.user,
  });

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _searchController = TextEditingController();
  final _dataSource = CourseApiDataSource();
  late Future<List<Course>> _coursesFuture;

  CourseFilter _selectedFilter = CourseFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _coursesFuture = _dataSource.getCourses();
  }

  @override
  void didUpdateWidget(covariant CoursesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() => _selectedFilter = widget.initialFilter);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filteredCourses(List<Course> allCourses) {
    return allCourses.where((course) {
      final matchesFilter = switch (_selectedFilter) {
        CourseFilter.all => true,
        CourseFilter.english => course.language == 'الإنجليزية',
        CourseFilter.german => course.language == 'الألمانية',
      };

      final searchText =
          '${course.title} ${course.language} ${course.level} ${course.levelBadge}'
              .toLowerCase();
      final matchesSearch = searchText.contains(_query.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          final courses = _filteredCourses(snapshot.data ?? const <Course>[]);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Text(
                  'الكورسات',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'اختار الكورس المناسب لمستواك وابدأ رحلتك التعليمية.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
                SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'ابحث عن كورس',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _selectedFilter == CourseFilter.all,
                      onSelected: () {
                        setState(() => _selectedFilter = CourseFilter.all);
                      },
                    ),
                    _FilterChip(
                      label: 'إنجليزي',
                      selected: _selectedFilter == CourseFilter.english,
                      onSelected: () {
                        setState(() => _selectedFilter = CourseFilter.english);
                      },
                    ),
                    _FilterChip(
                      label: 'ألماني',
                      selected: _selectedFilter == CourseFilter.german,
                      onSelected: () {
                        setState(() => _selectedFilter = CourseFilter.german);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  _CoursesError(
                    onRetry: () => setState(() {
                      _coursesFuture = _dataSource.getCourses();
                    }),
                  )
                else if (courses.isEmpty)
                  const _EmptyCourses()
                else
                  ...courses.map(
                    (course) => _CourseListTile(
                      course: course,
                      isPurchased:
                          widget.user?.hasCourse(
                            course.language,
                            course.title,
                          ) ??
                          false,
                      onTap: () => _openCourse(course),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoursesError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CoursesError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 42),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 66, color: AppColors.orange),
          SizedBox(height: 12),
          Text(
            'تعذر تحميل الكورسات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'تأكد أن السيرفر شغال ثم حاول مرة أخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.orange,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textMuted,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: selected ? AppColors.orange : AppColors.border),
    );
  }
}

class _CourseListTile extends StatelessWidget {
  final Course course;
  final bool isPurchased;
  final VoidCallback onTap;

  const _CourseListTile({
    required this.course,
    required this.isPurchased,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = course.price == 'مجانا';
    final imageProvider = _courseImageProvider(course.imageDataUrl);
    final hasImage = imageProvider != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  child: AspectRatio(
                    aspectRatio: 5 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
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
                      child: hasImage
                          ? null
                          : Icon(course.icon, color: Colors.white, size: 34),
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        course.title,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${course.language} • ${course.level} • ${course.lessonsCount}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      SizedBox(height: 8),
                      Row(
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
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                            ],
                            Text(
                              course.price,
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orangeSoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              course.levelBadge,
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 42),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 66, color: AppColors.orange),
          SizedBox(height: 12),
          Text(
            'لا توجد كورسات مطابقة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'جرّب تغيير البحث أو الفلتر.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
