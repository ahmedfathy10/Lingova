import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../../core/app_colors.dart';
import '../../data/models/audio_resource.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_storage_service.dart';
import '../../data/services/content_management_api_service.dart';
import '../widgets/audio_embed_widget.dart';

class _InlineAudioData {
  final String title;
  final String subtitle;
  final String url;
  final String fileType;

  const _InlineAudioData({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.fileType,
  });
}

class AudioResourcesPage extends StatefulWidget {
  const AudioResourcesPage({super.key});

  @override
  State<AudioResourcesPage> createState() => _AudioResourcesPageState();
}

class _AudioResourcesPageState extends State<AudioResourcesPage> {
  final _service = ContentManagementApiService();
  late Future<List<AudioResource>> _future;
  AuthUser? _user;
  String? _activeAudioKey;
  // ignore: unused_field
  _InlineAudioData? _activeAudio;

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

  // ignore: unused_element
  void _openResource(AudioResource resource) {
    if (!_canOpen(resource)) {
      _showLockedMessage();
      return;
    }

    if (resource.isFolder && resource.items.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _AudioFolderPage(resource: resource)),
      );
      return;
    }

    if (resource.isFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لم يتم العثور على ملفات صوتية داخل هذا الفولدر',
            textAlign: TextAlign.right,
          ),
        ),
      );
      return;
    }

    final audioUrl = _resolveAudioUrl(resource.url);
    if (audioUrl == null) {
      _showInvalidAudioUrl(context);
      return;
    }
    debugPrint('AUDIO URL = $audioUrl');

    final key = 'resource:${resource.id}';
    setState(() {
      if (_activeAudioKey == key) {
        _activeAudioKey = null;
        _activeAudio = null;
      } else {
        _activeAudioKey = key;
        _activeAudio = _InlineAudioData(
          title: resource.title,
          url: audioUrl,
          fileType: resource.fileType,
          subtitle: '${resource.course} - ${resource.level}',
        );
      }
    });
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'هذا الملف متاح بعد شراء الكورس.',
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  List<AudioResource> _resourcesForEnrollment(
    UserEnrollment enrollment,
    List<AudioResource> resources,
  ) {
    return resources
        .where(
          (resource) =>
              resource.courseLanguage == enrollment.courseLanguage &&
              resource.course == enrollment.courseTitle,
        )
        .toList();
  }

  void _openCourseAudio(
    UserEnrollment enrollment,
    List<AudioResource> resources,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StudentCourseAudioPage(
          enrollment: enrollment,
          resources: _resourcesForEnrollment(enrollment, resources),
        ),
      ),
    );
  }

  // ignore: unused_element
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
        body: SafeArea(
          child: FutureBuilder<List<AudioResource>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final resources = snapshot.data ?? const <AudioResource>[];
              if (resources.isEmpty) {
                return const _AudioEmptyState();
              }

              final user = _user;
              final enrollments = user?.enrollments ?? const <UserEnrollment>[];
              if (user == null || enrollments.isEmpty) {
                return const _PurchasedAudioEmptyState();
              }

              final purchasedResources = resources
                  .where(
                    (resource) => user.hasCourse(
                      resource.courseLanguage,
                      resource.course,
                    ),
                  )
                  .toList();
              final folders = purchasedResources
                  .where((item) => item.isFolder)
                  .length;
              final paid = purchasedResources
                  .where((item) => item.isPaid)
                  .length;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _future = _load());
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const _AudioHeader(),
                    const SizedBox(height: 16),
                    _AudioStatsBar(
                      total: purchasedResources.length,
                      folders: folders,
                      paid: paid,
                    ),
                    const SizedBox(height: 18),
                    _PurchasedAudioCoursesView(
                      enrollments: enrollments,
                      resourcesForEnrollment: (enrollment) =>
                          _resourcesForEnrollment(enrollment, resources),
                      onOpen: (enrollment) =>
                          _openCourseAudio(enrollment, resources),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PurchasedAudioCoursesView extends StatelessWidget {
  final List<UserEnrollment> enrollments;
  final List<AudioResource> Function(UserEnrollment enrollment)
  resourcesForEnrollment;
  final ValueChanged<UserEnrollment> onOpen;

  const _PurchasedAudioCoursesView({
    required this.enrollments,
    required this.resourcesForEnrollment,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: enrollments.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 142,
          ),
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            final resources = resourcesForEnrollment(enrollment);
            final files = resources.fold<int>(
              0,
              (sum, resource) =>
                  sum + (resource.isFolder ? resource.items.length : 1),
            );
            return _PurchasedAudioCourseCard(
              enrollment: enrollment,
              resourcesCount: resources.length,
              filesCount: files,
              onTap: () => onOpen(enrollment),
            );
          },
        );
      },
    );
  }
}

class _PurchasedAudioCourseCard extends StatelessWidget {
  final UserEnrollment enrollment;
  final int resourcesCount;
  final int filesCount;
  final VoidCallback onTap;

  const _PurchasedAudioCourseCard({
    required this.enrollment,
    required this.resourcesCount,
    required this.filesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: AppColors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      enrollment.courseTitle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      enrollment.courseLanguage,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$resourcesCount مجموعة - $filesCount ملف صوتي',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCourseAudioPage extends StatefulWidget {
  final UserEnrollment enrollment;
  final List<AudioResource> resources;

  const _StudentCourseAudioPage({
    required this.enrollment,
    required this.resources,
  });

  @override
  State<_StudentCourseAudioPage> createState() =>
      _StudentCourseAudioPageState();
}

class _StudentCourseAudioPageState extends State<_StudentCourseAudioPage> {
  String? _activeAudioKey;
  _InlineAudioData? _activeAudio;

  Map<String, List<AudioResource>> get _levels {
    final grouped = <String, List<AudioResource>>{};
    for (final resource in widget.resources) {
      final level = resource.level.isEmpty ? 'بدون مستوى' : resource.level;
      grouped.putIfAbsent(level, () => []);
      grouped[level]!.add(resource);
    }
    return grouped;
  }

  void _openResource(AudioResource resource) {
    if (resource.isFolder && resource.items.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _AudioFolderPage(resource: resource)),
      );
      return;
    }

    if (resource.isFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لم يتم العثور على ملفات صوتية داخل هذا الفولدر',
            textAlign: TextAlign.right,
          ),
        ),
      );
      return;
    }

    final audioUrl = _resolveAudioUrl(resource.url);
    if (audioUrl == null) {
      _showInvalidAudioUrl(context);
      return;
    }
    debugPrint('AUDIO URL = $audioUrl');

    final key = 'resource:${resource.id}';
    setState(() {
      if (_activeAudioKey == key) {
        _activeAudioKey = null;
        _activeAudio = null;
      } else {
        _activeAudioKey = key;
        _activeAudio = _InlineAudioData(
          title: resource.title,
          url: audioUrl,
          fileType: resource.fileType,
          subtitle: widget.enrollment.courseTitle,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.enrollment.courseTitle)),
        body: widget.resources.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 68,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'لا توجد صوتيات لهذا الكورس حالياً',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      widget.enrollment.courseTitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.enrollment.courseLanguage,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    ..._levels.entries.map(
                      (entry) => _LevelAudioGroup(
                        level: entry.key,
                        resources: entry.value,
                        canOpen: (_) => true,
                        onOpen: _openResource,
                        activeAudioKey: _activeAudioKey,
                        activeAudio: _activeAudio,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PurchasedAudioEmptyState extends StatelessWidget {
  const _PurchasedAudioEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 66, color: AppColors.orange),
            const SizedBox(height: 14),
            const Text(
              'لا توجد كورسات مشتراة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'بعد شراء كورس ستظهر صوتياته هنا داخل كارت منفصل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioHeader extends StatelessWidget {
  const _AudioHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.orange.withValues(alpha: .22)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.orange.withValues(alpha: .22),
            AppColors.surface,
            AppColors.surfaceHigh.withValues(alpha: .75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -20,
            top: -26,
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 125,
              color: AppColors.orange.withValues(alpha: .08),
            ),
          ),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB15D), AppColors.orange],
                  ),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الملفات الصوتية',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'استمع للدروس والتدريبات داخل التطبيق.',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioStatsBar extends StatelessWidget {
  final int total;
  final int folders;
  final int paid;

  const _AudioStatsBar({
    required this.total,
    required this.folders,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AudioStatPill(
            icon: Icons.library_music_rounded,
            label: 'ملف',
            value: total.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AudioStatPill(
            icon: Icons.folder_rounded,
            label: 'فولدر',
            value: folders.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AudioStatPill(
            icon: Icons.lock_rounded,
            label: 'مدفوع',
            value: paid.toString(),
          ),
        ),
      ],
    );
  }
}

class _AudioStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AudioStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: AppColors.orange),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CourseAudioGroup extends StatelessWidget {
  final String course;
  final Map<String, List<AudioResource>> levels;
  final bool Function(AudioResource resource) canOpen;
  final ValueChanged<AudioResource> onOpen;
  final String? activeAudioKey;
  final _InlineAudioData? activeAudio;

  const _CourseAudioGroup({
    required this.course,
    required this.levels,
    required this.canOpen,
    required this.onOpen,
    required this.activeAudioKey,
    required this.activeAudio,
  });

  int get _count {
    return levels.values.fold(0, (sum, items) => sum + items.length);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.orange),
          ),
          title: Text(
            course,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '$_count ملف صوتي',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted),
          ),
          children: levels.entries.map((levelEntry) {
            return _LevelAudioGroup(
              level: levelEntry.key,
              resources: levelEntry.value,
              canOpen: canOpen,
              onOpen: onOpen,
              activeAudioKey: activeAudioKey,
              activeAudio: activeAudio,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LevelAudioGroup extends StatelessWidget {
  final String level;
  final List<AudioResource> resources;
  final bool Function(AudioResource resource) canOpen;
  final ValueChanged<AudioResource> onOpen;
  final String? activeAudioKey;
  final _InlineAudioData? activeAudio;

  const _LevelAudioGroup({
    required this.level,
    required this.resources,
    required this.canOpen,
    required this.onOpen,
    required this.activeAudioKey,
    required this.activeAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          title: Text(
            level,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${resources.length} عنصر',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          children: resources.map((resource) {
            final locked = !canOpen(resource);
            return _AudioResourceTile(
              resource: resource,
              locked: locked,
              onTap: () => onOpen(resource),
              isPlaying: activeAudioKey == 'resource:${resource.id}',
              activeAudio: activeAudioKey == 'resource:${resource.id}'
                  ? activeAudio
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AudioResourceTile extends StatelessWidget {
  final AudioResource resource;
  final bool locked;
  final VoidCallback onTap;
  final bool isPlaying;
  final _InlineAudioData? activeAudio;

  const _AudioResourceTile({
    required this.resource,
    required this.locked,
    required this.onTap,
    required this.isPlaying,
    required this.activeAudio,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      resource.fileType,
      resource.isPaid ? 'مع شراء الكورس' : 'مجاني',
      if (resource.isFolder) '${resource.items.length} ملفات',
    ].join('  |  ');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            resource.title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: onTap,
                      style: IconButton.styleFrom(
                        fixedSize: const Size(42, 42),
                        backgroundColor: locked
                            ? AppColors.surfaceHigh
                            : AppColors.orange,
                        foregroundColor: locked
                            ? AppColors.textMuted
                            : Colors.white,
                      ),
                      icon: Icon(
                        locked
                            ? Icons.lock_rounded
                            : resource.isFolder
                            ? Icons.arrow_back_ios_new_rounded
                            : isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isPlaying && activeAudio != null
                      ? Padding(
                          key: ValueKey(activeAudio!.url),
                          padding: const EdgeInsets.only(top: 8),
                          child: _EmbeddedAudioPanel(audio: activeAudio!),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioFolderPage extends StatefulWidget {
  final AudioResource resource;

  const _AudioFolderPage({required this.resource});

  @override
  State<_AudioFolderPage> createState() => _AudioFolderPageState();
}

class _AudioFolderPageState extends State<_AudioFolderPage> {
  String? _activeAudioKey;
  _InlineAudioData? _activeAudio;

  void _toggleItem(AudioResourceItem item) {
    final audioUrl = _resolveAudioUrl(item.url);
    if (audioUrl == null) {
      _showInvalidAudioUrl(context);
      return;
    }
    debugPrint('AUDIO URL = $audioUrl');

    final key = 'folder:${widget.resource.id}:${item.id}';
    setState(() {
      if (_activeAudioKey == key) {
        _activeAudioKey = null;
        _activeAudio = null;
      } else {
        _activeAudioKey = key;
        _activeAudio = _InlineAudioData(
          title: item.title,
          url: audioUrl,
          fileType: item.fileType,
          subtitle: widget.resource.title,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.resource.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...widget.resource.items.map((item) {
                final key = 'folder:${widget.resource.id}:${item.id}';
                final isPlaying = _activeAudioKey == key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FolderAudioTile(
                    item: item,
                    isPlaying: isPlaying,
                    activeAudio: isPlaying ? _activeAudio : null,
                    onTap: () => _toggleItem(item),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderAudioTile extends StatelessWidget {
  final AudioResourceItem item;
  final bool isPlaying;
  final _InlineAudioData? activeAudio;
  final VoidCallback onTap;

  const _FolderAudioTile({
    required this.item,
    required this.isPlaying,
    required this.activeAudio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.title,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.fileType,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: onTap,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(42, 42),
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isPlaying && activeAudio != null
                    ? Padding(
                        key: ValueKey(activeAudio!.url),
                        padding: const EdgeInsets.only(top: 8),
                        child: _EmbeddedAudioPanel(audio: activeAudio!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmbeddedAudioPanel extends StatelessWidget {
  final _InlineAudioData audio;

  const _EmbeddedAudioPanel({required this.audio});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 86,
        child: AudioEmbedWidget(html: _playerHtml(audio)),
      ),
    );
  }
}

String _playerHtml(_InlineAudioData audio) {
  final safeSource = _escape(audio.url);

  return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  html, body {
    margin: 0;
    height: 100%;
    background: #0b0d12;
    font-family: Arial, sans-serif;
    color: #fff;
  }
  .wrap {
    height: 100%;
    box-sizing: border-box;
    padding: 10px 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(145deg, #141922, #0b0d12 70%);
  }
  audio {
    width: 100%;
    accent-color: #ff7a00;
  }
</style>
</head>
<body>
  <main class="wrap">
    <audio controls autoplay preload="metadata" controlsList="nodownload" src="$safeSource"></audio>
  </main>
</body>
</html>
''';
}

String? _resolveAudioUrl(String value) {
  final url = value.trim();
  if (url.isEmpty) {
    return null;
  }

  if (url.startsWith('data:')) {
    return url;
  }

  if (_isGoogleDriveUrl(url)) {
    return url.toLowerCase().contains('drive.google.com')
        ? _googleDriveDownloadUrl(url)
        : url;
  }

  if (url.startsWith('/')) {
    if (url == '/api' || url == '/api/') {
      return null;
    }
    return Uri.parse(ApiConfig.baseUrl).resolve(url).toString();
  }

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return null;
  }

  final apiRoot = Uri.parse(ApiConfig.baseUrl);
  final isApiRoot =
      uri.scheme == apiRoot.scheme &&
      uri.host == apiRoot.host &&
      uri.port == apiRoot.port &&
      (uri.path.isEmpty || uri.path == '/');
  if (isApiRoot || uri.path == '/api' || uri.path == '/api/') {
    return null;
  }

  return url;
}

bool _isGoogleDriveUrl(String value) {
  final url = value.toLowerCase();
  return url.contains('drive.google.com') ||
      url.contains('googleapis.com/drive/');
}

String? _googleDriveDownloadUrl(String value) {
  final url = value.trim();
  final fileMatch = RegExp(
    r'drive\.google\.com/file/d/([^/?#]+)',
  ).firstMatch(url);
  final openMatch = RegExp(
    r'drive\.google\.com/(?:open|uc)\?(?:[^#]*&)?id=([^&#]+)',
  ).firstMatch(url);
  final id = fileMatch?.group(1) ?? openMatch?.group(1);
  if (id == null || id.isEmpty) {
    return null;
  }
  return 'https://drive.google.com/uc?export=download&id=$id';
}

void _showInvalidAudioUrl(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('رابط الصوت غير صالح')));
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

class _AudioEmptyState extends StatelessWidget {
  const _AudioEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.headphones_rounded, size: 68, color: AppColors.orange),
            const SizedBox(height: 14),
            const Text(
              'لا توجد صوتيات حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'سيظهر هنا محتوى الكورسات الصوتي بعد إضافته من لوحة التحكم.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
