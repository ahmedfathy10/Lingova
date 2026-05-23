import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/admin_course_part.dart';
import '../../data/models/audio_resource.dart';
import '../../data/models/vocabulary_word.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/services/content_management_api_service.dart';

class AdminVocabularyPage extends StatefulWidget {
  final AdminSession session;

  const AdminVocabularyPage({super.key, required this.session});

  @override
  State<AdminVocabularyPage> createState() => _AdminVocabularyPageState();
}

class _AdminVocabularyPageState extends State<AdminVocabularyPage> {
  final _service = ContentManagementApiService();
  late Future<List<VocabularyWord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getVocabulary(token: widget.session.token);
  }

  void _refresh() {
    setState(() => _future = _service.getVocabulary(token: widget.session.token));
  }

  Future<void> _add() async {
    final result = await showDialog<VocabularyWord>(
      context: context,
      builder: (_) => const _VocabularyWordDialog(),
    );
    if (result == null) return;
    await _service.createVocabularyWord(widget.session.token, result);
    _refresh();
  }

  Future<void> _delete(VocabularyWord word) async {
    await _service.deleteVocabularyWord(widget.session.token, word.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vocabulary'),
          actions: [
            IconButton(onPressed: _add, icon: const Icon(Icons.add_rounded)),
          ],
        ),
        body: FutureBuilder<List<VocabularyWord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final words = snapshot.data ?? const <VocabularyWord>[];
            if (words.isEmpty) {
              return const Center(child: Text('لا توجد كلمات بعد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                return Card(
                  child: ListTile(
                    title: Text(word.word, textAlign: TextAlign.right),
                    subtitle: Text(
                      '${word.meaning}\n${word.example}',
                      textAlign: TextAlign.right,
                    ),
                    isThreeLine: word.example.isNotEmpty,
                    trailing: IconButton(
                      onPressed: () => _delete(word),
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

  Future<void> _add() async {
    final parts = await _coursesFuture;
    if (!mounted) return;
    final result = await showDialog<AudioResource>(
      context: context,
      builder: (_) => _AudioResourceDialog(parts: parts),
    );
    if (result == null) return;
    await _contentService.createAudioResource(widget.session.token, result);
    _refresh();
  }

  Future<void> _delete(AudioResource resource) async {
    await _contentService.deleteAudioResource(widget.session.token, resource.id);
    _refresh();
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

class _VocabularyWordDialog extends StatefulWidget {
  const _VocabularyWordDialog();

  @override
  State<_VocabularyWordDialog> createState() => _VocabularyWordDialogState();
}

class _VocabularyWordDialogState extends State<_VocabularyWordDialog> {
  final _word = TextEditingController();
  final _meaning = TextEditingController();
  final _pronunciation = TextEditingController();
  final _example = TextEditingController();
  String _languageCode = 'en';

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _pronunciation.dispose();
    _example.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة كلمة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _word, decoration: const InputDecoration(labelText: 'Word')),
            TextField(controller: _meaning, decoration: const InputDecoration(labelText: 'Meaning')),
            TextField(controller: _pronunciation, decoration: const InputDecoration(labelText: 'Pronunciation')),
            TextField(controller: _example, decoration: const InputDecoration(labelText: 'Example')),
            DropdownButtonFormField<String>(
              initialValue: _languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'de', child: Text('German')),
              ],
              onChanged: (value) => setState(() => _languageCode = value ?? 'en'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
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
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _AudioResourceDialog extends StatefulWidget {
  final List<AdminCoursePart> parts;

  const _AudioResourceDialog({required this.parts});

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
          );
        })
        .whereType<AudioResourceItem>()
        .toList();
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
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(controller: _description, decoration: const InputDecoration(labelText: 'الوصف')),
              DropdownButtonFormField<String>(
                initialValue: _courseKey,
                decoration: const InputDecoration(labelText: 'الكورس'),
                items: courses
                    .map((course) => DropdownMenuItem(
                          value: '${course.language}|${course.course}',
                          child: Text('${course.language} - ${course.course}'),
                        ))
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
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() => _level = value ?? ''),
              ),
              DropdownButtonFormField<String>(
                initialValue: _accessType,
                decoration: const InputDecoration(labelText: 'الإتاحة'),
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('مجاني')),
                  DropdownMenuItem(value: 'paid', child: Text('مع شراء الكورس')),
                ],
                onChanged: (value) => setState(() => _accessType = value ?? 'free'),
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
                onChanged: (value) => setState(() => _fileType = value ?? 'audio'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _linkType,
                decoration: const InputDecoration(labelText: 'نوع الرابط'),
                items: const [
                  DropdownMenuItem(value: 'clip', child: Text('مقطع')),
                  DropdownMenuItem(value: 'folder', child: Text('فولدر')),
                ],
                onChanged: (value) => setState(() => _linkType = value ?? 'clip'),
              ),
              TextField(controller: _url, decoration: const InputDecoration(labelText: 'رابط المقطع أو الفولدر')),
              if (_linkType == 'folder')
                TextField(
                  controller: _items,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'ملفات الفولدر',
                    hintText: 'Title | URL | audio',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
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
                url: _url.text.trim(),
                items: _parseItems(),
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

