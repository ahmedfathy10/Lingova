import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../data/models/audio_resource.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_storage_service.dart';
import '../../data/services/content_management_api_service.dart';

class AudioResourcesPage extends StatefulWidget {
  const AudioResourcesPage({super.key});

  @override
  State<AudioResourcesPage> createState() => _AudioResourcesPageState();
}

class _AudioResourcesPageState extends State<AudioResourcesPage> {
  final _service = ContentManagementApiService();
  late Future<List<AudioResource>> _future;
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AudioResource>> _load() async {
    _user = await AuthStorageService.loadUser();
    return _service.getAudioResources();
  }

  bool _canOpen(AudioResource resource) {
    if (!resource.isPaid) return true;
    final user = _user;
    if (user == null) return false;
    return user.hasCourse(resource.courseLanguage, resource.course);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openResource(AudioResource resource) {
    if (!_canOpen(resource)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا الملف متاح بعد شراء الكورس.', textAlign: TextAlign.right),
        ),
      );
      return;
    }
    if (resource.isFolder && resource.items.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _AudioFolderPage(resource: resource)),
      );
      return;
    }
    _openUrl(resource.url);
  }

  Map<String, Map<String, List<AudioResource>>> _group(
    List<AudioResource> resources,
  ) {
    final grouped = <String, Map<String, List<AudioResource>>>{};
    for (final resource in resources) {
      final course = resource.course.isEmpty ? 'عام' : resource.course;
      final level = resource.level.isEmpty ? 'بدون مستوى' : resource.level;
      grouped.putIfAbsent(course, () => {});
      grouped[course]!.putIfAbsent(level, () => []);
      grouped[course]![level]!.add(resource);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الملفات الصوتية')),
        body: FutureBuilder<List<AudioResource>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final resources = snapshot.data ?? const <AudioResource>[];
            if (resources.isEmpty) {
              return const Center(child: Text('لا توجد صوتيات حالياً.'));
            }
            final grouped = _group(resources);
            return ListView(
              padding: const EdgeInsets.all(18),
              children: grouped.entries.map((courseEntry) {
                return _CourseAudioGroup(
                  course: courseEntry.key,
                  levels: courseEntry.value,
                  canOpen: _canOpen,
                  onOpen: _openResource,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _CourseAudioGroup extends StatelessWidget {
  final String course;
  final Map<String, List<AudioResource>> levels;
  final bool Function(AudioResource resource) canOpen;
  final ValueChanged<AudioResource> onOpen;

  const _CourseAudioGroup({
    required this.course,
    required this.levels,
    required this.canOpen,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(course, style: const TextStyle(fontWeight: FontWeight.w900)),
        children: levels.entries.map((levelEntry) {
          return ExpansionTile(
            title: Text(levelEntry.key),
            children: levelEntry.value.map((resource) {
              final locked = !canOpen(resource);
              return ListTile(
                leading: Icon(
                  resource.isFolder
                      ? Icons.folder_rounded
                      : Icons.headphones_rounded,
                  color: locked ? AppColors.textMuted : AppColors.orange,
                ),
                title: Text(resource.title, textAlign: TextAlign.right),
                subtitle: Text(
                  '${resource.fileType} • ${resource.isPaid ? 'مع شراء الكورس' : 'مجاني'}',
                  textAlign: TextAlign.right,
                ),
                trailing: Icon(
                  locked ? Icons.lock_rounded : Icons.play_circle_rounded,
                ),
                onTap: () => onOpen(resource),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _AudioFolderPage extends StatelessWidget {
  final AudioResource resource;

  const _AudioFolderPage({required this.resource});

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(resource.title)),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: resource.items.map((item) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_rounded),
                title: Text(item.title, textAlign: TextAlign.right),
                subtitle: Text(item.fileType, textAlign: TextAlign.right),
                onTap: () => _openUrl(item.url),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
