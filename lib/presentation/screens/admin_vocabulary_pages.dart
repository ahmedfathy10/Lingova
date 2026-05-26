import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/vocabulary_hierarchy.dart';
import '../../data/models/admin_course_part.dart';
import '../../data/models/vocabulary_word.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/services/content_management_api_service.dart';
import 'admin_learning_content_pages.dart';

class AdminVocabularyPage extends StatefulWidget {
  final AdminSession session;

  const AdminVocabularyPage({super.key, required this.session});

  @override
  State<AdminVocabularyPage> createState() => _AdminVocabularyPageState();
}

class _AdminVocabularyPageState extends State<AdminVocabularyPage> {
  final _contentService = ContentManagementApiService();
  final _adminService = AdminApiService();
  late Future<_VocabularyData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_VocabularyData> _loadData() async {
    final results = await Future.wait([
      _contentService.getVocabulary(token: widget.session.token),
      _adminService.getCourseParts(widget.session.token),
    ]);
    return _VocabularyData(
      words: results[0] as List<VocabularyWord>,
      parts: results[1] as List<AdminCoursePart>,
    );
  }

  void _refresh() {
    setState(() => _dataFuture = _loadData());
  }

  AdminCoursePart _partForCourse(VocabularyCourseRef course, List<AdminCoursePart> parts) {
    return parts.firstWhere(
      (part) =>
          part.language.trim() == course.language &&
          part.course.trim() == course.course,
      orElse: () => AdminCoursePart(
        id: '',
        type: 'course',
        language: course.language,
        course: course.course,
        level: '',
        lecture: '',
        part: '',
        vimeoUrl: '',
        courseType: 'free',
        price: '',
        courseLevel: '',
        duration: '',
        imageDataUrl: '',
        learningOutcomes: const [],
        createdAt: null,
        createdBy: '',
      ),
    );
  }

  void _openCourse(VocabularyCourseRef course, _VocabularyData data) {
    final part = _partForCourse(course, data.parts);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => _AdminVocabularyCoursePage(
              session: widget.session,
              course: course,
              coursePart: part,
              words: data.words,
              parts: data.parts,
            ),
          ),
        )
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<_VocabularyData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'تعذر تحميل الكلمات.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final courses = VocabularyHierarchy.coursesFromData(
            parts: data.parts,
            words: data.words,
          );

          return Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    const Spacer(),
                    const Text(
                      'المفردات',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر الكورس ثم الوحدة ثم الدرس لإدارة الكلمات ورفعها.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                if (courses.isEmpty)
                  Text(
                    'لا توجد كورسات بعد. أضف كورسات من قسم الكورسات أولاً.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textMuted),
                  )
                else
                  ..._groupCourses(courses, data.words).map(
                    (group) => _VocabularyLanguageSection(
                      title: group.title,
                      courses: group.courses,
                      wordCountFor: (course) =>
                          VocabularyHierarchy.wordCountForCourse(data.words, course),
                      onOpenCourse: (course) => _openCourse(course, data),
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

class _VocabularyData {
  final List<VocabularyWord> words;
  final List<AdminCoursePart> parts;

  const _VocabularyData({required this.words, required this.parts});
}

class _VocabularyLanguageGroup {
  final String title;
  final List<VocabularyCourseRef> courses;

  const _VocabularyLanguageGroup({required this.title, required this.courses});
}

List<_VocabularyLanguageGroup> _groupCourses(
  List<VocabularyCourseRef> courses,
  List<VocabularyWord> words,
) {
  final english = <VocabularyCourseRef>[];
  final german = <VocabularyCourseRef>[];
  final other = <VocabularyCourseRef>[];
  for (final course in courses) {
  final lang = course.language.toLowerCase();
    if (lang.contains('انج') || lang.contains('إنج') || lang.contains('english')) {
      english.add(course);
    } else if (lang.contains('المان') || lang.contains('ألمان') || lang.contains('german')) {
      german.add(course);
    } else {
      other.add(course);
    }
  }
  return [
    if (english.isNotEmpty)
      _VocabularyLanguageGroup(title: 'الإنجليزية', courses: english),
    if (german.isNotEmpty)
      _VocabularyLanguageGroup(title: 'الألمانية', courses: german),
    if (other.isNotEmpty) _VocabularyLanguageGroup(title: 'أخرى', courses: other),
  ];
}

class _VocabularyLanguageSection extends StatelessWidget {
  final String title;
  final List<VocabularyCourseRef> courses;
  final int Function(VocabularyCourseRef course) wordCountFor;
  final ValueChanged<VocabularyCourseRef> onOpenCourse;

  const _VocabularyLanguageSection({
    required this.title,
    required this.courses,
    required this.wordCountFor,
    required this.onOpenCourse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 620 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 118,
                ),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _VocabularyCourseCard(
                    course: course,
                    wordCount: wordCountFor(course),
                    onTap: () => onOpenCourse(course),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VocabularyCourseCard extends StatelessWidget {
  final VocabularyCourseRef course;
  final int wordCount;
  final VoidCallback onTap;

  const _VocabularyCourseCard({
    required this.course,
    required this.wordCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.label,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$wordCount كلمة',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.menu_book_rounded, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminVocabularyCoursePage extends StatelessWidget {
  final AdminSession session;
  final VocabularyCourseRef course;
  final AdminCoursePart coursePart;
  final List<VocabularyWord> words;
  final List<AdminCoursePart> parts;

  const _AdminVocabularyCoursePage({
    required this.session,
    required this.course,
    required this.coursePart,
    required this.words,
    required this.parts,
  });

  void _openLevel(BuildContext context, String level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AdminVocabularyLevelPage(
          session: session,
          course: course,
          coursePart: coursePart,
          level: level,
          words: words,
          parts: parts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = VocabularyHierarchy.levelsForCourse(
      parts: parts,
      words: words,
      course: course,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(course.label)),
        body: levels.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    'لا توجد وحدات/مستويات لهذا الكورس بعد.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final count = VocabularyHierarchy.wordCountForLevel(words, course, level);
                  return Card(
                    child: ListTile(
                      onTap: () => _openLevel(context, level),
                      title: Text(level, textAlign: TextAlign.right),
                      subtitle: Text(
                        '$count كلمة',
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AdminVocabularyLevelPage extends StatelessWidget {
  final AdminSession session;
  final VocabularyCourseRef course;
  final AdminCoursePart coursePart;
  final String level;
  final List<VocabularyWord> words;
  final List<AdminCoursePart> parts;

  const _AdminVocabularyLevelPage({
    required this.session,
    required this.course,
    required this.coursePart,
    required this.level,
    required this.words,
    required this.parts,
  });

  void _openLesson(BuildContext context, String lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AdminVocabularyLessonPage(
          session: session,
          course: course,
          coursePart: coursePart,
          level: level,
          lesson: lesson,
          words: words,
          parts: parts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = VocabularyHierarchy.lessonsForLevel(
      parts: parts,
      words: words,
      course: course,
      level: level,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('$level • ${course.label}')),
        body: lessons.isEmpty
            ? Center(
                child: Text(
                  'لا توجد دروس/يونتات في هذا المستوى.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  final count = VocabularyHierarchy.wordCountForLesson(
                    words,
                    course,
                    level,
                    lesson,
                  );
                  return Card(
                    child: ListTile(
                      onTap: () => _openLesson(context, lesson),
                      title: Text(lesson, textAlign: TextAlign.right),
                      subtitle: Text('$count كلمة', textAlign: TextAlign.right),
                      trailing: const Icon(Icons.chevron_left_rounded),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AdminVocabularyLessonPage extends StatefulWidget {
  final AdminSession session;
  final VocabularyCourseRef course;
  final AdminCoursePart coursePart;
  final String level;
  final String lesson;
  final List<VocabularyWord> words;
  final List<AdminCoursePart> parts;

  const _AdminVocabularyLessonPage({
    required this.session,
    required this.course,
    required this.coursePart,
    required this.level,
    required this.lesson,
    required this.words,
    required this.parts,
  });

  @override
  State<_AdminVocabularyLessonPage> createState() =>
      _AdminVocabularyLessonPageState();
}

class _AdminVocabularyLessonPageState extends State<_AdminVocabularyLessonPage> {
  final _contentService = ContentManagementApiService();
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  late List<VocabularyWord> _lessonWords;

  @override
  void initState() {
    super.initState();
    _lessonWords = VocabularyHierarchy.wordsForLesson(
      words: widget.words,
      course: widget.course,
      level: widget.level,
      lesson: widget.lesson,
    );
  }

  Future<void> _reloadParentWords() async {
    final words = await _contentService.getVocabulary(token: widget.session.token);
    if (!mounted) return;
    setState(() {
      _lessonWords = VocabularyHierarchy.wordsForLesson(
        words: words,
        course: widget.course,
        level: widget.level,
        lesson: widget.lesson,
      );
      _selectedIds.removeWhere(
        (id) => !_lessonWords.any((word) => word.id == id),
      );
    });
  }

  Future<void> _addWord() async {
    final result = await showDialog<VocabularyWord>(
      context: context,
      builder: (_) => VocabularyWordFormDialog(
        parts: widget.parts,
        initialCourse: widget.coursePart,
        initialLevel: widget.level,
        initialLesson: widget.lesson,
        lockCourseContext: true,
      ),
    );
    if (result == null) return;
    await _contentService.createVocabularyWord(widget.session.token, result);
    await _reloadParentWords();
  }

  Future<void> _bulkImport() async {
    final result = await showDialog<List<VocabularyWord>>(
      context: context,
      builder: (_) => VocabularyBulkImportDialog(
        parts: widget.parts,
        initialCourse: widget.coursePart,
        initialLevel: widget.level,
        initialLesson: widget.lesson,
        lockCourseContext: true,
      ),
    );
    if (result == null || result.isEmpty) return;
    final count = await _contentService.createVocabularyWords(
      widget.session.token,
      result,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة $count كلمة.', textAlign: TextAlign.right)),
    );
    await _reloadParentWords();
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الكلمات المحددة'),
        content: Text(
          'هل تريد حذف ${_selectedIds.length} كلمة؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await _contentService.deleteVocabularyWords(
      widget.session.token,
      _selectedIds.toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف $deleted كلمة.', textAlign: TextAlign.right)),
    );
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
    await _reloadParentWords();
  }

  Future<void> _deleteOne(VocabularyWord word) async {
    await _contentService.deleteVocabularyWord(widget.session.token, word.id);
    await _reloadParentWords();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _lessonWords.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_lessonWords.map((word) => word.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _lessonWords.isNotEmpty && _selectedIds.length == _lessonWords.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson),
          actions: [
            if (_lessonWords.isNotEmpty)
              IconButton(
                tooltip: allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                onPressed: _toggleSelectAll,
                icon: Icon(
                  allSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
              ),
            if (_selectedIds.isNotEmpty)
              IconButton(
                tooltip: 'حذف المحدد',
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_forever_rounded),
              ),
            IconButton(
              onPressed: _bulkImport,
              tooltip: 'استيراد ملف',
              icon: const Icon(Icons.upload_file_rounded),
            ),
            IconButton(
              onPressed: _addWord,
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              tooltip: _selectionMode ? 'إنهاء التحديد' : 'تحديد متعدد',
              onPressed: () => setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) {
                  _selectedIds.clear();
                }
              }),
              icon: Icon(
                _selectionMode
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
              ),
            ),
          ],
        ),
        body: _lessonWords.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate_rounded, size: 56, color: AppColors.orange),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد كلمات في هذا الدرس بعد.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _addWord,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة كلمة'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _bulkImport,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('استيراد ملف'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                itemCount: _lessonWords.length,
                itemBuilder: (context, index) {
                  final word = _lessonWords[index];
                  final selected = _selectedIds.contains(word.id);
                  return Card(
                    color: selected
                        ? AppColors.orange.withValues(alpha: 0.12)
                        : AppColors.surface,
                    child: ListTile(
                      onTap: _selectionMode
                          ? () => setState(() {
                              if (selected) {
                                _selectedIds.remove(word.id);
                              } else {
                                _selectedIds.add(word.id);
                              }
                            })
                          : null,
                      onLongPress: () => setState(() {
                        _selectionMode = true;
                        _selectedIds.add(word.id);
                      }),
                      leading: _selectionMode
                          ? Checkbox(
                              value: selected,
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  _selectedIds.add(word.id);
                                } else {
                                  _selectedIds.remove(word.id);
                                }
                              }),
                            )
                          : null,
                      title: Text(word.word, textAlign: TextAlign.right),
                      subtitle: Text(
                        [
                          word.meaning,
                          if (word.translation.isNotEmpty) word.translation,
                          if (word.example.isNotEmpty) word.example,
                        ].join('\n'),
                        textAlign: TextAlign.right,
                      ),
                      isThreeLine: true,
                      trailing: _selectionMode
                          ? null
                          : IconButton(
                              onPressed: () => _deleteOne(word),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
