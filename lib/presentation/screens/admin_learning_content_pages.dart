import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:excel/excel.dart' as xlsx;
import 'package:file_picker/file_picker.dart';

import '../../core/app_colors.dart';
import '../../data/models/admin_course_part.dart';
import '../../data/models/audio_resource.dart';
import '../../data/models/vocabulary_word.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/services/audio_folder_picker.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/content_management_api_service.dart';

class AdminAudioResourcesPage extends StatefulWidget {
  final AdminSession session;

  const AdminAudioResourcesPage({super.key, required this.session});

  @override
  State<AdminAudioResourcesPage> createState() =>
      _AdminAudioResourcesPageState();
}

class _AdminAudioResourcesPageState extends State<AdminAudioResourcesPage> {
  final _contentService = ContentManagementApiService();
  final _adminService = AdminApiService();
  late Future<List<AudioResource>> _future;
  late Future<List<AdminCoursePart>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _future = _contentService.getAudioResources(token: widget.session.token);
    _coursesFuture = _adminService.getCourseParts(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _future = _contentService.getAudioResources(token: widget.session.token);
    });
  }

  Future<void> _add({AdminCoursePart? course}) async {
    final parts = await _coursesFuture;
    if (!mounted) return;
    final result = await showDialog<AudioResource>(
      context: context,
      builder: (_) => _AudioResourceDialog(
        parts: parts,
        token: widget.session.token,
        initialCourse: course,
      ),
    );
    if (result == null) return;
    await _contentService.createAudioResource(widget.session.token, result);
    _refresh();
  }

  Future<void> _delete(AudioResource resource) async {
    await _contentService.deleteAudioResource(
      widget.session.token,
      resource.id,
    );
    _refresh();
  }

  // ignore: unused_element
  Future<void> _audit() async {
    try {
      final result = await _contentService.auditAudioResources(
        widget.session.token,
      );
      if (!mounted) return;
      final issues = result['issues'] as List? ?? const [];
      final message = issues.isEmpty
          ? 'كل ملفات الصوتيات مرفوعة أونلاين ومتاحة.'
          : 'يوجد ${issues.length} مشكلة في الصوتيات. الناقص: ${result['missingFiles'] ?? issues.length} ملف.';
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('فحص الصوتيات'),
          content: Text(
            '$message\n\nتم فحص ${result['checkedFiles'] ?? 0} ملف داخل ${result['checkedResources'] ?? 0} مجموعة.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تمام'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString(), textAlign: TextAlign.right)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الصوتيات'),
          actions: [
            IconButton(onPressed: _add, icon: const Icon(Icons.add_rounded)),
          ],
        ),
        body: FutureBuilder<List<AudioResource>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final resources = snapshot.data ?? const <AudioResource>[];
            if (resources.isEmpty) {
              return const Center(child: Text('لا توجد صوتيات بعد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      resource.isFolder
                          ? Icons.folder_rounded
                          : Icons.headphones_rounded,
                      color: AppColors.orange,
                    ),
                    title: Text(resource.title, textAlign: TextAlign.right),
                    subtitle: Text(
                      '${resource.course} • ${resource.level}\n${resource.isPaid ? 'مع شراء الكورس' : 'مجاني'} • ${resource.fileType} • ${resource.linkType}',
                      textAlign: TextAlign.right,
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      onPressed: () => _delete(resource),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AdminCourseAudioManagerPage extends StatefulWidget {
  final AdminSession session;

  const AdminCourseAudioManagerPage({super.key, required this.session});

  @override
  State<AdminCourseAudioManagerPage> createState() =>
      _AdminCourseAudioManagerPageState();
}

class _AdminCourseAudioManagerPageState
    extends State<AdminCourseAudioManagerPage> {
  final _contentService = ContentManagementApiService();
  final _adminService = AdminApiService();
  late Future<List<AudioResource>> _resourcesFuture;
  late Future<List<AdminCoursePart>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _resourcesFuture = _contentService.getAudioResources(
      token: widget.session.token,
    );
    _coursesFuture = _adminService.getCourseParts(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _resourcesFuture = _contentService.getAudioResources(
        token: widget.session.token,
      );
      _coursesFuture = _adminService.getCourseParts(widget.session.token);
    });
  }

  Future<void> _add({AdminCoursePart? course}) async {
    final parts = await _coursesFuture;
    if (!mounted) return;
    final result = await showDialog<AudioResource>(
      context: context,
      builder: (_) => _AudioResourceDialog(
        parts: parts,
        token: widget.session.token,
        initialCourse: course,
      ),
    );
    if (result == null) return;
    await _contentService.createAudioResource(widget.session.token, result);
    _refresh();
  }

  Future<void> _delete(AudioResource resource) async {
    await _contentService.deleteAudioResource(
      widget.session.token,
      resource.id,
    );
    _refresh();
  }

  Future<void> _audit() async {
    try {
      final result = await _contentService.auditAudioResources(
        widget.session.token,
      );
      if (!mounted) return;
      final issues = result['issues'] as List? ?? const [];
      final message = issues.isEmpty
          ? 'كل ملفات الصوتيات مرفوعة أونلاين ومتاحة.'
          : 'يوجد ${issues.length} مشكلة في الصوتيات. الناقص: ${result['missingFiles'] ?? issues.length} ملف.';
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('فحص الصوتيات'),
          content: Text(
            '$message\n\nتم فحص ${result['checkedFiles'] ?? 0} ملف داخل ${result['checkedResources'] ?? 0} مجموعة.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تمام'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString(), textAlign: TextAlign.right)),
      );
    }
  }

  void _openCourse(
    AdminCoursePart course,
    List<AudioResource> resources,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AdminCourseAudioDetailsPage(
          course: course,
          resources: resources
              .where(
                (resource) =>
                    resource.courseLanguage == course.language &&
                    resource.course == course.course,
              )
              .toList(),
          onAdd: () => _add(course: course),
          onDelete: _delete,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<Object>>(
        future: Future.wait([_resourcesFuture, _coursesFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر تحميل الصوتيات.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final data = snapshot.data ?? const <Object>[];
          final resources = data[0] as List<AudioResource>;
          final parts = data[1] as List<AdminCoursePart>;
          return _AdminAudioDashboard(
            parts: parts,
            resources: resources,
            onAddGeneral: () => _add(),
            onAudit: _audit,
            onOpenCourse: (course) => _openCourse(course, resources),
          );
        },
      ),
    );
  }
}

class _AdminAudioDashboard extends StatelessWidget {
  final List<AdminCoursePart> parts;
  final List<AudioResource> resources;
  final VoidCallback onAddGeneral;
  final VoidCallback onAudit;
  final ValueChanged<AdminCoursePart> onOpenCourse;

  const _AdminAudioDashboard({
    required this.parts,
    required this.resources,
    required this.onAddGeneral,
    required this.onAudit,
    required this.onOpenCourse,
  });

  List<AdminCoursePart> get _courses {
    final map = <String, AdminCoursePart>{};
    for (final part in parts) {
      if (part.course.isEmpty || part.language.isEmpty) continue;
      map['${part.language}|${part.course}'] = part;
    }
    final values = map.values.toList();
    values.sort(
      (a, b) =>
          '${a.language}${a.course}'.compareTo('${b.language}${b.course}'),
    );
    return values;
  }

  List<_AdminAudioLanguageGroup> get _groups {
    final courses = _courses;
    final english = courses
        .where((course) => _isEnglish(course.language))
        .toList();
    final german = courses
        .where((course) => _isGerman(course.language))
        .toList();
    final other = courses
        .where(
          (course) =>
              !_isEnglish(course.language) && !_isGerman(course.language),
        )
        .toList();
    return [
      _AdminAudioLanguageGroup(
        title: 'الإنجليزي',
        subtitle: 'كورسات وصوتيات اللغة الإنجليزية',
        icon: Icons.language_rounded,
        color: const Color(0xFF2563EB),
        courses: english,
      ),
      _AdminAudioLanguageGroup(
        title: 'الألماني',
        subtitle: 'كورسات وصوتيات اللغة الألمانية',
        icon: Icons.school_rounded,
        color: AppColors.orange,
        courses: german,
      ),
      if (other.isNotEmpty)
        _AdminAudioLanguageGroup(
          title: 'أخرى',
          subtitle: 'كورسات لم يتم تصنيف لغتها',
          icon: Icons.category_rounded,
          color: const Color(0xFF16A34A),
          courses: other,
        ),
    ];
  }

  int _resourceCount(AdminCoursePart course) {
    return resources
        .where(
          (resource) =>
              resource.courseLanguage == course.language &&
              resource.course == course.course,
        )
        .length;
  }

  int _fileCount(AdminCoursePart course) {
    return resources
        .where(
          (resource) =>
              resource.courseLanguage == course.language &&
              resource.course == course.course,
        )
        .fold<int>(
          0,
          (sum, resource) =>
              sum + (resource.isFolder ? resource.items.length : 1),
        );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onAudit,
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('فحص الملفات'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAddGeneral,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة صوتيات'),
            ),
            const Spacer(),
            const Text(
              'الصوتيات',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.take(2).length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 158,
              ),
              itemBuilder: (context, index) {
                final group = groups[index];
                final audioCount = group.courses.fold<int>(
                  0,
                  (sum, course) => sum + _resourceCount(course),
                );
                return _AdminLanguageSummaryCard(
                  group: group,
                  audioCount: audioCount,
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        ...groups.map(
          (group) => _AdminLanguageCourseSection(
            group: group,
            audioCountFor: _resourceCount,
            fileCountFor: _fileCount,
            onOpenCourse: onOpenCourse,
          ),
        ),
      ],
    );
  }
}

class _AdminAudioLanguageGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<AdminCoursePart> courses;

  const _AdminAudioLanguageGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.courses,
  });
}

class _AdminLanguageSummaryCard extends StatelessWidget {
  final _AdminAudioLanguageGroup group;
  final int audioCount;

  const _AdminLanguageSummaryCard({
    required this.group,
    required this.audioCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(group.icon, color: group.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                group.title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${group.courses.length} كورس - $audioCount مجموعة صوتيات',
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminLanguageCourseSection extends StatelessWidget {
  final _AdminAudioLanguageGroup group;
  final int Function(AdminCoursePart course) audioCountFor;
  final int Function(AdminCoursePart course) fileCountFor;
  final ValueChanged<AdminCoursePart> onOpenCourse;

  const _AdminLanguageCourseSection({
    required this.group,
    required this.audioCountFor,
    required this.fileCountFor,
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
            group.title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            group.subtitle,
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (group.courses.isEmpty)
            Text(
              'لا توجد كورسات لهذه اللغة بعد.',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 980
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.courses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 128,
                  ),
                  itemBuilder: (context, index) {
                    final course = group.courses[index];
                    return _AdminAudioCourseCard(
                      course: course,
                      audioCount: audioCountFor(course),
                      fileCount: fileCountFor(course),
                      color: group.color,
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

class _AdminAudioCourseCard extends StatelessWidget {
  final AdminCoursePart course;
  final int audioCount;
  final int fileCount;
  final Color color;
  final VoidCallback onTap;

  const _AdminAudioCourseCard({
    required this.course,
    required this.audioCount,
    required this.fileCount,
    required this.color,
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
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.course,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$audioCount مجموعة - $fileCount ملف صوتي',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.headphones_rounded, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCourseAudioDetailsPage extends StatelessWidget {
  final AdminCoursePart course;
  final List<AudioResource> resources;
  final VoidCallback onAdd;
  final ValueChanged<AudioResource> onDelete;

  const _AdminCourseAudioDetailsPage({
    required this.course,
    required this.resources,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(course.course),
          actions: [
            IconButton(
              tooltip: 'إضافة صوتيات للكورس',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: resources.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 62,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد صوتيات لهذا الكورس بعد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة صوتيات'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: resources.length,
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        resource.isFolder
                            ? Icons.folder_rounded
                            : Icons.headphones_rounded,
                        color: AppColors.orange,
                      ),
                      title: Text(resource.title, textAlign: TextAlign.right),
                      subtitle: Text(
                        '${resource.level.isEmpty ? 'بدون مستوى' : resource.level}\n${resource.isPaid ? 'مع شراء الكورس' : 'مجاني'} - ${resource.fileType} - ${resource.linkType}${resource.isFolder ? ' - ${resource.items.length} ملف' : ''}',
                        textAlign: TextAlign.right,
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        onPressed: () => onDelete(resource),
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

bool _isEnglish(String value) {
  final text = value.toLowerCase();
  return text.contains('english') ||
      text.contains('انج') ||
      text.contains('إنج') ||
      text == 'en';
}

bool _isGerman(String value) {
  final text = value.toLowerCase();
  return text.contains('german') ||
      text.contains('المان') ||
      text.contains('ألمان') ||
      text == 'de';
}

class VocabularyWordFormDialog extends StatefulWidget {
  final List<AdminCoursePart> parts;
  final AdminCoursePart? initialCourse;
  final String? initialLevel;
  final String? initialLesson;
  final bool lockCourseContext;

  const VocabularyWordFormDialog({
    required this.parts,
    this.initialCourse,
    this.initialLevel,
    this.initialLesson,
    this.lockCourseContext = false,
  });

  @override
  State<VocabularyWordFormDialog> createState() =>
      _VocabularyWordFormDialogState();
}

class _VocabularyWordFormDialogState extends State<VocabularyWordFormDialog> {
  final _word = TextEditingController();
  final _meaning = TextEditingController();
  final _pronunciation = TextEditingController();
  final _example = TextEditingController();
  final _translation = TextEditingController();
  final _lesson = TextEditingController();
  String _languageCode = 'en';
  String? _courseKey;
  String _level = '';

  @override
  void initState() {
    super.initState();
    final course = widget.initialCourse;
    if (course != null) {
      _courseKey = '${course.language}|${course.course}';
      _level = widget.initialLevel?.trim() ?? '';
      _lesson.text = widget.initialLesson?.trim() ?? '';
      _languageCode = _isGerman(course.language) ? 'de' : 'en';
    }
  }

  List<AdminCoursePart> get _courses {
    final map = <String, AdminCoursePart>{};
    for (final part in widget.parts) {
      if (part.course.isEmpty || part.language.isEmpty) continue;
      map['${part.language}|${part.course}'] = part;
    }
    return map.values.toList();
  }

  List<String> get _levels {
    if (_courseKey == null) return const [];
    final values = widget.parts
        .where((part) => '${part.language}|${part.course}' == _courseKey)
        .map((part) => part.level)
        .where((level) => level.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _pronunciation.dispose();
    _example.dispose();
    _translation.dispose();
    _lesson.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    AdminCoursePart? selectedCourse;
    for (final course in courses) {
      if ('${course.language}|${course.course}' == _courseKey) {
        selectedCourse = course;
        break;
      }
    }
    final lockContext = widget.lockCourseContext;
    return AlertDialog(
      title: const Text('إضافة كلمة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _word,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'الكلمة'),
            ),
            TextField(
              controller: _meaning,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'المعنى'),
            ),
            TextField(
              controller: _translation,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'الترجمة'),
            ),
            TextField(
              controller: _pronunciation,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'النطق'),
            ),
            TextField(
              controller: _example,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'مثال'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'de', child: Text('German')),
              ],
              onChanged: lockContext
                  ? null
                  : (value) => setState(() => _languageCode = value ?? 'en'),
            ),
            if (!lockContext)
              DropdownButtonFormField<String>(
                initialValue: _courseKey,
                decoration: const InputDecoration(labelText: 'الكورس'),
                items: courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: '${course.language}|${course.course}',
                        child: Text('${course.language} - ${course.course}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _courseKey = value;
                  _level = '';
                }),
              )
            else if (selectedCourse != null)
              ListTile(
                title: Text(
                  '${selectedCourse.language} - ${selectedCourse.course}',
                  textAlign: TextAlign.right,
                ),
                subtitle: const Text(
                  'الكورس المحدد',
                  textAlign: TextAlign.right,
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: _level.isEmpty ? null : _level,
              decoration: const InputDecoration(labelText: 'الوحدة / المستوى'),
              items: _levels
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: lockContext && widget.initialLevel?.isNotEmpty == true
                  ? null
                  : (value) => setState(() => _level = value ?? ''),
            ),
            TextField(
              controller: _lesson,
              textAlign: TextAlign.right,
              readOnly:
                  lockContext && widget.initialLesson?.trim().isNotEmpty == true,
              decoration: const InputDecoration(labelText: 'الدرس / اليونت'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              VocabularyWord(
                id: '',
                word: _word.text.trim(),
                meaning: _meaning.text.trim(),
                pronunciation: _pronunciation.text.trim(),
                example: _example.text.trim(),
                languageCode: _languageCode,
                course: selectedCourse?.course ?? '',
                courseLanguage: selectedCourse?.language ?? '',
                level: _level,
                lesson: _lesson.text.trim(),
                translation: _translation.text.trim(),
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class VocabularyBulkImportDialog extends StatefulWidget {
  final List<AdminCoursePart> parts;
  final AdminCoursePart? initialCourse;
  final String? initialLevel;
  final String? initialLesson;
  final bool lockCourseContext;

  const VocabularyBulkImportDialog({
    required this.parts,
    this.initialCourse,
    this.initialLevel,
    this.initialLesson,
    this.lockCourseContext = false,
  });

  @override
  State<VocabularyBulkImportDialog> createState() =>
      _VocabularyBulkImportDialogState();
}

class _VocabularyBulkImportDialogState extends State<VocabularyBulkImportDialog> {
  final _lesson = TextEditingController();
  String _languageCode = 'en';
  String? _courseKey;
  String _level = '';
  String _fileName = '';
  List<VocabularyWord> _words = const [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    final course = widget.initialCourse;
    if (course != null) {
      _courseKey = '${course.language}|${course.course}';
      _level = widget.initialLevel?.trim() ?? '';
      _lesson.text = widget.initialLesson?.trim() ?? '';
      _languageCode = _isGerman(course.language) ? 'de' : 'en';
    }
  }

  List<AdminCoursePart> get _courses {
    final map = <String, AdminCoursePart>{};
    for (final part in widget.parts) {
      if (part.course.isEmpty || part.language.isEmpty) continue;
      map['${part.language}|${part.course}'] = part;
    }
    return map.values.toList();
  }

  List<String> get _levels {
    if (_courseKey == null) return const [];
    final values = widget.parts
        .where((part) => '${part.language}|${part.course}' == _courseKey)
        .map((part) => part.level)
        .where((level) => level.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  @override
  void dispose() {
    _lesson.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv', 'tsv', 'txt'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    try {
      final parsedRows = file.extension?.toLowerCase() == 'xlsx'
          ? _readXlsxRows(bytes)
          : _readTextRows(
              utf8.decode(bytes, allowMalformed: true),
              file.extension ?? '',
            );
      final words = _buildWords(parsedRows);
      setState(() {
        _fileName = file.name;
        _words = words;
        _error = words.isEmpty ? 'لم يتم العثور على كلمات صالحة.' : '';
      });
    } catch (_) {
      setState(() {
        _fileName = file.name;
        _words = const [];
        _error = 'تعذر قراءة الملف. استخدم XLSX أو CSV بالأعمدة المطلوبة.';
      });
    }
  }

  List<List<String>> _readXlsxRows(List<int> bytes) {
    final excel = xlsx.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return const [];
    final sheet = excel.tables.values.first;
    return sheet.rows
        .map((row) => row.map((cell) => _cellText(cell?.value)).toList())
        .toList();
  }

  String _cellText(xlsx.CellValue? value) {
    if (value == null) return '';
    if (value is xlsx.TextCellValue) return value.value.text ?? '';
    return value.toString();
  }

  List<List<String>> _readTextRows(String content, String extension) {
    final delimiter = extension.toLowerCase() == 'tsv' ? '\t' : ',';
    return const LineSplitter()
        .convert(content)
        .where((line) => line.trim().isNotEmpty)
        .map((line) => _parseDelimitedLine(line, delimiter))
        .toList();
  }

  List<String> _parseDelimitedLine(String line, String delimiter) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (char == delimiter && !quoted) {
        cells.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString().trim());
    return cells;
  }

  List<VocabularyWord> _buildWords(List<List<String>> rows) {
    final courses = _courses;
    AdminCoursePart? selectedCourse;
    for (final course in courses) {
      if ('${course.language}|${course.course}' == _courseKey) {
        selectedCourse = course;
        break;
      }
    }

    final dataRows = rows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();
    if (dataRows.isEmpty) return const [];

    final startIndex = _looksLikeHeader(dataRows.first) ? 1 : 0;
    return dataRows
        .skip(startIndex)
        .map((row) {
          String cell(int index) => index < row.length ? row[index].trim() : '';
          return VocabularyWord(
            id: '',
            word: cell(0),
            meaning: cell(1),
            translation: cell(2),
            example: cell(3),
            pronunciation: cell(4),
            languageCode: _languageCode,
            course: selectedCourse?.course ?? '',
            courseLanguage: selectedCourse?.language ?? '',
            level: _level,
            lesson: _lesson.text.trim(),
          );
        })
        .where((word) => word.word.isNotEmpty && word.meaning.isNotEmpty)
        .toList();
  }

  bool _looksLikeHeader(List<String> row) {
    final values = row.map((cell) => cell.trim().toLowerCase()).toList();
    return values.contains('word') ||
        values.contains('meaning') ||
        values.contains('translation') ||
        values.contains('example');
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    final lockContext = widget.lockCourseContext;
    AdminCoursePart? selectedCourse;
    for (final course in courses) {
      if ('${course.language}|${course.course}' == _courseKey) {
        selectedCourse = course;
        break;
      }
    }
    return AlertDialog(
      title: const Text('استيراد كلمات'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _languageCode,
                decoration: const InputDecoration(labelText: 'لغة الكلمات'),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'de', child: Text('German')),
                ],
                onChanged: lockContext
                    ? null
                    : (value) => setState(() {
                        _languageCode = value ?? 'en';
                        if (_fileName.isNotEmpty) {
                          _words = _buildWords(_wordsToRows(_words));
                        }
                      }),
              ),
              if (!lockContext)
                DropdownButtonFormField<String>(
                  initialValue: _courseKey,
                  decoration: const InputDecoration(labelText: 'الكورس'),
                  items: courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: '${course.language}|${course.course}',
                          child: Text('${course.language} - ${course.course}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _courseKey = value;
                    _level = '';
                    if (_fileName.isNotEmpty) {
                      _words = _buildWords(_wordsToRows(_words));
                    }
                  }),
                )
              else if (selectedCourse != null)
                ListTile(
                  title: Text(
                    '${selectedCourse.language} - ${selectedCourse.course}',
                    textAlign: TextAlign.right,
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _level.isEmpty ? null : _level,
                decoration: const InputDecoration(labelText: 'الوحدة / المستوى'),
                items: _levels
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
                onChanged: lockContext && widget.initialLevel?.isNotEmpty == true
                    ? null
                    : (value) => setState(() {
                        _level = value ?? '';
                        if (_fileName.isNotEmpty) {
                          _words = _buildWords(_wordsToRows(_words));
                        }
                      }),
              ),
              TextField(
                controller: _lesson,
                textAlign: TextAlign.right,
                readOnly:
                    lockContext && widget.initialLesson?.trim().isNotEmpty == true,
                decoration: const InputDecoration(labelText: 'الدرس / اليونت'),
                onChanged: (_) {
                  if (_fileName.isNotEmpty) {
                    setState(() => _words = _buildWords(_wordsToRows(_words)));
                  }
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  _fileName.isEmpty ? 'اختيار ملف XLSX / CSV' : _fileName,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ترتيب الأعمدة: word, meaning, translation, example, pronunciation',
                textAlign: TextAlign.center,
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_error, style: const TextStyle(color: Colors.red)),
              ],
              if (_words.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('جاهز لإضافة ${_words.length} كلمة'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _words.isEmpty
              ? null
              : () => Navigator.pop(context, _words),
          child: const Text('استيراد'),
        ),
      ],
    );
  }

  List<List<String>> _wordsToRows(List<VocabularyWord> words) {
    return words
        .map(
          (word) => [
            word.word,
            word.meaning,
            word.translation,
            word.example,
            word.pronunciation,
          ],
        )
        .toList();
  }
}

class _AudioResourceDialog extends StatefulWidget {
  final List<AdminCoursePart> parts;
  final String token;
  final AdminCoursePart? initialCourse;

  const _AudioResourceDialog({
    required this.parts,
    required this.token,
    this.initialCourse,
  });

  @override
  State<_AudioResourceDialog> createState() => _AudioResourceDialogState();
}

class _AudioResourceDialogState extends State<_AudioResourceDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  final _items = TextEditingController();
  String? _courseKey;
  String _level = '';
  String _accessType = 'free';
  String _fileType = 'audio';
  String _linkType = 'clip';
  List<AudioResourceItem> _detectedAudioItems = const [];
  String _audioFolderError = '';
  bool _isImportingDriveFolder = false;
  bool _isUploadingAudioFolder = false;
  int _uploadTotal = 0;
  int _uploadDone = 0;
  int _uploadSuccess = 0;
  int _uploadFailed = 0;

  @override
  void initState() {
    super.initState();
    final initialCourse = widget.initialCourse;
    if (initialCourse != null) {
      _courseKey = '${initialCourse.language}|${initialCourse.course}';
      _accessType = initialCourse.isPaid ? 'paid' : 'free';
    }
  }

  List<AdminCoursePart> get _courses {
    final map = <String, AdminCoursePart>{};
    for (final part in widget.parts) {
      if (part.course.isEmpty || part.language.isEmpty) continue;
      map['${part.language}|${part.course}'] = part;
    }
    return map.values.toList();
  }

  List<String> get _levels {
    if (_courseKey == null) return const [];
    final values = widget.parts
        .where((part) => '${part.language}|${part.course}' == _courseKey)
        .map((part) => part.level)
        .where((level) => level.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    _items.dispose();
    super.dispose();
  }

  List<AudioResourceItem> _parseItems() {
    if (_detectedAudioItems.isNotEmpty) {
      return _detectedAudioItems;
    }
    return _items.text
        .split('\n')
        .map((line) {
          final parts = line.split('|');
          if (parts.length < 2) return null;
          return AudioResourceItem(
            id: '',
            title: parts[0].trim(),
            url: parts[1].trim(),
            fileType: parts.length > 2 ? parts[2].trim() : _fileType,
            relativePath: parts.length > 3 ? parts[3].trim() : '',
          );
        })
        .whereType<AudioResourceItem>()
        .toList();
  }

  Future<void> _pickAudioFolder(AdminCoursePart? selectedCourse) async {
    if (selectedCourse == null) {
      setState(() {
        _audioFolderError = 'اختر الكورس قبل رفع فولدر الصوتيات.';
      });
      return;
    }

    final files = await pickAudioFolderFiles();
    if (files == null) return;
    if (files.isEmpty) {
      setState(() {
        _detectedAudioItems = const [];
        _audioFolderError = 'لم يتم العثور على ملفات mp3 داخل هذا الفولدر.';
      });
      return;
    }

    final folderTitle = _title.text.trim().isEmpty
        ? _folderTitleFromFiles(files)
        : _title.text.trim();
    setState(() {
      _linkType = 'folder';
      _fileType = 'audio';
      _audioFolderError = '';
      _detectedAudioItems = const [];
      _isUploadingAudioFolder = true;
      _uploadTotal = files.length;
      _uploadDone = 0;
      _uploadSuccess = 0;
      _uploadFailed = 0;
      if (_title.text.trim().isEmpty) {
        _title.text = folderTitle;
      }
      if (_url.text.trim().isEmpty) {
        _url.text =
            'local-audio-folder:${DateTime.now().millisecondsSinceEpoch}';
      }
    });

    final service = ContentManagementApiService();
    final uploadedItems = <AudioResourceItem>[];
    final failed = <String>[];
    for (final file in files) {
      try {
        final item = await service.uploadAudioFolderFile(
          token: widget.token,
          file: file,
          course: selectedCourse.course,
          courseLanguage: selectedCourse.language,
          level: _level,
          folderTitle: folderTitle,
        );
        uploadedItems.add(item);
        if (!mounted) return;
        setState(() {
          _uploadSuccess += 1;
          _uploadDone += 1;
        });
      } catch (_) {
        failed.add(file.relativePath);
        if (!mounted) return;
        setState(() {
          _uploadFailed += 1;
          _uploadDone += 1;
        });
      }
    }

    if (!mounted) return;
    uploadedItems.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    setState(() {
      _isUploadingAudioFolder = false;
      _audioFolderError = failed.isEmpty
          ? ''
          : 'فشل رفع ${failed.length} ملف. تم حفظ الملفات التي نجحت فقط.';
    });
    if (uploadedItems.isEmpty) {
      setState(() {
        _detectedAudioItems = const [];
        _items.clear();
        _audioFolderError = 'فشل رفع كل الملفات. حاول مرة أخرى.';
      });
      return;
    }
    _applyDetectedAudioItems(uploadedItems);
    if (failed.isNotEmpty && mounted) {
      setState(() {
        _audioFolderError =
            'فشل رفع ${failed.length} ملف. تم حفظ الملفات التي نجحت فقط.';
      });
    }
  }

  Future<void> _importGoogleDriveFolder() async {
    final folderUrl = _url.text.trim();
    if (folderUrl.isEmpty) {
      setState(() {
        _audioFolderError = 'اكتب رابط فولدر Google Drive أولاً';
      });
      return;
    }

    setState(() {
      _isImportingDriveFolder = true;
      _audioFolderError = '';
    });
    try {
      final items = await ContentManagementApiService()
          .importGoogleDriveAudioFolder(widget.token, folderUrl);
      if (!mounted) return;
      if (items.isEmpty) {
        setState(() {
          _detectedAudioItems = const [];
          _audioFolderError = 'لم يتم العثور على ملفات صوتية داخل هذا الفولدر';
        });
        return;
      }
      _applyDetectedAudioItems(items);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() => _audioFolderError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audioFolderError =
            'تعذر قراءة فولدر Google Drive. تأكد أن الفولدر متاح للمشاركة.';
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingDriveFolder = false);
      }
    }
  }

  void _applyDetectedAudioItems(List<AudioResourceItem> items) {
    setState(() {
      _linkType = 'folder';
      _fileType = 'audio';
      _audioFolderError = '';
      _detectedAudioItems = items;
      _items.text = items
          .map((item) {
            final path = item.relativePath.isEmpty
                ? item.url
                : item.relativePath;
            return '${item.title} | ${item.url} | audio | $path';
          })
          .join('\n');
      if (_title.text.trim().isEmpty) {
        final firstPath = items.first.relativePath;
        final slash = firstPath.lastIndexOf('/');
        _title.text = slash > 0
            ? firstPath.substring(0, slash)
            : 'فولدر صوتيات';
      }
      if (_url.text.trim().isEmpty) {
        _url.text =
            'local-audio-folder:${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  String _folderTitleFromFiles(List<PickedAudioFolderFile> files) {
    final path = files.first.relativePath.replaceAll('\\', '/');
    final slash = path.indexOf('/');
    if (slash > 0) return path.substring(0, slash);
    return 'فولدر صوتيات';
  }

  void _submit(AdminCoursePart? selectedCourse) {
    final items = _parseItems();
    if (_linkType == 'folder' && items.isEmpty) {
      setState(() {
        _audioFolderError = 'لم يتم العثور على ملفات صوتية داخل هذا الفولدر';
      });
      return;
    }

    Navigator.pop(
      context,
      AudioResource(
        id: '',
        title: _title.text.trim(),
        description: _description.text.trim(),
        course: selectedCourse?.course ?? '',
        courseLanguage: selectedCourse?.language ?? '',
        level: _level,
        accessType: _accessType,
        fileType: _fileType,
        linkType: _linkType,
        url: _url.text.trim().isEmpty && _linkType == 'folder'
            ? 'local-audio-folder:${DateTime.now().millisecondsSinceEpoch}'
            : _url.text.trim(),
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    AdminCoursePart? selectedCourse;
    for (final course in courses) {
      if ('${course.language}|${course.course}' == _courseKey) {
        selectedCourse = course;
        break;
      }
    }
    return AlertDialog(
      title: const Text('إضافة صوتيات'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _courseKey,
                decoration: const InputDecoration(labelText: 'الكورس'),
                items: courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: '${course.language}|${course.course}',
                        child: Text('${course.language} - ${course.course}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _courseKey = value;
                  _level = '';
                }),
              ),
              DropdownButtonFormField<String>(
                initialValue: _level.isEmpty ? null : _level,
                decoration: const InputDecoration(labelText: 'الليفيل'),
                items: _levels
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _level = value ?? ''),
              ),
              DropdownButtonFormField<String>(
                initialValue: _accessType,
                decoration: const InputDecoration(labelText: 'الإتاحة'),
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('مجاني')),
                  DropdownMenuItem(
                    value: 'paid',
                    child: Text('مع شراء الكورس'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _accessType = value ?? 'free'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _fileType,
                decoration: const InputDecoration(labelText: 'نوع الملف'),
                items: const [
                  DropdownMenuItem(value: 'audio', child: Text('Audio')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'link', child: Text('Link')),
                ],
                onChanged: (value) =>
                    setState(() => _fileType = value ?? 'audio'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _linkType,
                decoration: const InputDecoration(labelText: 'نوع الرابط'),
                items: const [
                  DropdownMenuItem(value: 'clip', child: Text('مقطع')),
                  DropdownMenuItem(value: 'folder', child: Text('فولدر')),
                ],
                onChanged: (value) => setState(() {
                  _linkType = value ?? 'clip';
                  if (_linkType != 'folder') {
                    _detectedAudioItems = const [];
                    _audioFolderError = '';
                    _items.clear();
                  }
                }),
              ),
              TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: 'رابط المقطع أو الفولدر',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isImportingDriveFolder
                        ? null
                        : _importGoogleDriveFolder,
                    icon: _isImportingDriveFolder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_rounded),
                    label: Text(
                      _isImportingDriveFolder
                          ? 'جاري قراءة Google Drive...'
                          : 'استيراد من Google Drive',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isUploadingAudioFolder
                        ? null
                        : () => _pickAudioFolder(selectedCourse),
                    icon: _isUploadingAudioFolder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_rounded),
                    label: Text(
                      _isUploadingAudioFolder
                          ? 'جاري رفع الفولدر...'
                          : 'رفع فولدر صوتيات',
                    ),
                  ),
                ],
              ),
              if (_isUploadingAudioFolder || _uploadTotal > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: _uploadTotal == 0
                            ? null
                            : _uploadDone / _uploadTotal,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تم رفع $_uploadDone / $_uploadTotal - ناجح: $_uploadSuccess - فشل: $_uploadFailed',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _uploadFailed == 0
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_detectedAudioItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'تم العثور على ${_detectedAudioItems.length} ملف صوتي داخل الفولدر',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (_audioFolderError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _audioFolderError,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (_linkType == 'folder')
                TextField(
                  controller: _items,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'ملفات الفولدر',
                    hintText: 'Title | URL | audio | relative/path.mp3',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isUploadingAudioFolder
              ? null
              : () => _submit(selectedCourse),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
