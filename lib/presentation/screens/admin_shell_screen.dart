// ignore_for_file: deprecated_member_use, unnecessary_underscores, unused_element

import 'dart:convert';
import 'dart:ui';

import 'admin_dashboard_page.dart';
import 'admin_support_chat_page.dart';
import 'admin_community_page.dart';
import 'admin_learning_content_pages.dart';
import 'admin_registration_form_settings_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/admin_app_notification.dart';
import '../../data/models/admin_book.dart';
import '../../data/models/admin_course_part.dart';
import '../../data/models/admin_subscription_request.dart';
import '../../data/models/admin_user.dart';
import '../../data/models/course_question.dart';
import '../../data/models/exam.dart';
import '../../data/models/watch_progress_record.dart';
import '../../domain/entities/book.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/course_image_picker.dart';
import '../../data/services/exam_api_service.dart';
import '../../data/services/text_file_downloader.dart';
import '../../data/services/watch_progress_api_service.dart';
import 'certificate_page.dart';
import 'book_viewer_screen.dart';
part 'admin_notifications_widgets.dart';

class AdminShellScreen extends StatefulWidget {
  final AdminSession session;

  const AdminShellScreen({super.key, required this.session});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late final List<_AdminSection> _sections;
  late final List<Widget?> _pages;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _sections = [
      _AdminSection(
        label: 'لوحة التحكم',
        icon: Icons.dashboard_rounded,
        builder: () => AdminDashboardPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الطلاب',
        icon: Icons.groups_rounded,
        builder: () => AdminUsersPage(session: widget.session),
      ),
      _AdminSection(
        label: 'طلبات الاشتراك',
        icon: Icons.verified_user_rounded,
        builder: () => AdminSubscriptionsPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الكورسات',
        icon: Icons.menu_book_rounded,
        builder: () => AdminCoursesPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الكتب',
        icon: Icons.library_books_rounded,
        builder: () => AdminBooksPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الامتحانات',
        icon: Icons.quiz_rounded,
        builder: () => AdminExamsPage(session: widget.session),
      ),
      _AdminSection(
        label: 'تقارير الامتحانات',
        icon: Icons.insights_rounded,
        builder: () => AdminExamReportsPage(session: widget.session),
      ),
      _AdminSection(
        label: 'بنك الأسئلة',
        icon: Icons.help_center_rounded,
        builder: () => AdminQuestionsPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الشهادات',
        icon: Icons.workspace_premium_rounded,
        builder: () => AdminCertificatesPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الإشعارات',
        icon: Icons.notifications_active_rounded,
        builder: () => AdminNotificationsPage(session: widget.session),
      ),
      _AdminSection(
        label: 'سجل النشاط',
        icon: Icons.history_rounded,
        builder: () => AdminActivityLogsPage(session: widget.session),
      ),
      _AdminSection(
        label: 'تقرير المشاهدة',
        icon: Icons.play_circle_fill_rounded,
        builder: () => AdminWatchReportPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الكلمات',
        icon: Icons.translate_rounded,
        builder: () => AdminVocabularyPage(session: widget.session),
      ),
      _AdminSection(
        label: 'الصوتيات',
        icon: Icons.headphones_rounded,
        builder: () => AdminCourseAudioManagerPage(session: widget.session),
      ),
      _AdminSection(
        label: 'المجتمع',
        icon: Icons.forum_rounded,
        builder: () => AdminCommunityPage(token: widget.session.token),
      ),
      _AdminSection(
        label: 'الدعم',
        icon: Icons.support_agent_rounded,
        builder: () => AdminSupportChatPage(token: widget.session.token),
      ),
      _AdminSection(
        label: 'نموذج التسجيل',
        icon: Icons.dynamic_form_rounded,
        builder: () =>
            AdminRegistrationFormSettingsPage(session: widget.session),
      ),
    ];
    _pages = List<Widget?>.filled(_sections.length, null);
  }

  void _selectSection(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _pageFor(int index) {
    return _pages[index] ??= _sections[index].builder();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final selectedSection = _sections[_selectedIndex];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: isWide
              ? null
              : AppBar(
                  title: Text(
                    selectedSection.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
          drawer: isWide
              ? null
              : _AdminDrawer(
                  sections: _sections,
                  selectedIndex: _selectedIndex,
                  session: widget.session,
                  onSelected: (index) {
                    Navigator.of(context).pop();
                    _selectSection(index);
                  },
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide)
                  _AdminSidebar(
                    sections: _sections,
                    selectedIndex: _selectedIndex,
                    session: widget.session,
                    onSelected: _selectSection,
                  ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      isWide ? 0 : 10,
                      isWide ? 14 : 8,
                      isWide ? 14 : 10,
                      10,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(isWide ? 16 : 10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        for (var index = 0; index < _sections.length; index++)
                          KeyedSubtree(
                            key: PageStorageKey(_sections[index].label),
                            child:
                                index == _selectedIndex || _pages[index] != null
                                ? _pageFor(index)
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminSection {
  final String label;
  final IconData icon;
  final Widget Function() builder;

  const _AdminSection({
    required this.label,
    required this.icon,
    required this.builder,
  });
}

class _AdminSidebar extends StatelessWidget {
  final List<_AdminSection> sections;
  final int selectedIndex;
  final AdminSession session;
  final ValueChanged<int> onSelected;

  const _AdminSidebar({
    required this.sections,
    required this.selectedIndex,
    required this.session,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _AdminShellHeader(session: session),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final section = sections[index];
                final selected = selectedIndex == index;
                return _AdminSidebarItem(
                  label: section.label,
                  icon: section.icon,
                  selected: selected,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final List<_AdminSection> sections;
  final int selectedIndex;
  final AdminSession session;
  final ValueChanged<int> onSelected;

  const _AdminDrawer({
    required this.sections,
    required this.selectedIndex,
    required this.session,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _AdminShellHeader(session: session),
            Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _AdminSidebarItem(
                    label: section.label,
                    icon: section.icon,
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminShellHeader extends StatelessWidget {
  final AdminSession session;

  const _AdminShellHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final title = session.name.trim().isEmpty ? 'Lingova Admin' : session.name;
    final subtitle = session.email.trim().isEmpty
        ? 'لوحة الإدارة'
        : session.email;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: .55),
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AdminSidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orangeSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: selected ? AppColors.orange : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

String _money(num value) => '${value.toStringAsFixed(0)} EGP';

int _dashboardColumns(double width, int maxColumns) {
  if (maxColumns == 5) {
    if (width >= 1180) return 5;
    if (width >= 860) return 3;
    if (width >= 620) return 2;
    return 1;
  }

  if (width >= 1040) return maxColumns;
  if (width >= 620) return 2;
  return 1;
}

class _ReadersDialog extends StatelessWidget {
  final List<NotificationReader> readers;

  const _ReadersDialog({required this.readers});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff07101a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      'قرّاء الإشعار',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: readers.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final r = readers[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade800,
                      child: Text(
                        (r.fullName.isNotEmpty ? r.fullName : r.id)
                            .split(RegExp(r'\s+'))
                            .map((s) => s.isEmpty ? '' : s[0].toUpperCase())
                            .take(2)
                            .join(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(
                      r.fullName.isNotEmpty ? r.fullName : r.id,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      r.phone.isNotEmpty ? r.phone : '',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: Text(
                      r.readAt.isNotEmpty ? _readableTime(r.readAt) : '',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _readableTime(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      final local = dt.toLocal();
      final y = local.year.toString().padLeft(4, '0');
      final m = local.month.toString().padLeft(2, '0');
      final d = local.day.toString().padLeft(2, '0');
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $hh:$mm';
    } catch (_) {
      return iso;
    }
  }
}

class AdminActivityLogsPage extends StatefulWidget {
  final AdminSession session;

  const AdminActivityLogsPage({super.key, required this.session});

  @override
  State<AdminActivityLogsPage> createState() => _AdminActivityLogsPageState();
}

class _AdminActivityLogsPageState extends State<AdminActivityLogsPage> {
  final _service = AdminApiService();
  late Future<List<AdminActivityLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _service.getActivityLogs(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _logsFuture = _service.getActivityLogs(widget.session.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminActivityLog>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final logs = snapshot.data ?? const <AdminActivityLog>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'سجل نشاط المستخدمين',
              subtitle:
                  'كل فتح للتطبيق وتنقل وشراء ومشاهدة وامتحان يظهر هنا بالوقت والتاريخ.',
              action: _ToolbarButton(
                onPressed: isLoading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: 'تحديث',
                filled: true,
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const _ErrorState(message: 'تعذر تحميل سجل النشاط.')
            else if (logs.isEmpty)
              _Panel(
                child: Text(
                  'لا توجد أنشطة مسجلة حتى الآن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...logs.map((log) => _ActivityLogCard(log: log)),
          ],
        );
      },
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  final AdminActivityLog log;

  const _ActivityLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatusPill(text: log.createdAtLabel, color: AppColors.orange),
                Text(
                  log.userName.isEmpty ? 'مستخدم' : log.userName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              log.userPhone,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Text(
              log.label.isEmpty ? log.action : log.label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            if (log.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.details,
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  final AdminSession session;

  const AdminUsersPage({super.key, required this.session});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _service = AdminApiService();
  final _searchController = TextEditingController();
  late Future<List<AdminUser>> _usersFuture;
  String _pendingQuery = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _service.getUsers(widget.session.token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } on AuthApiException catch (error) {
      _showMessage(error.message);
      return;
    } catch (_) {
      _showMessage('حدث خطأ أثناء تنفيذ العملية.');
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _usersFuture = _service.getUsers(widget.session.token);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ التغيير بنجاح.')));
    });
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(() => _usersFuture = _service.getUsers(widget.session.token));
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  void _searchUsers() {
    setState(() => _query = _pendingQuery.trim());
  }

  Future<void> _exportUsers(List<AdminUser> users) async {
    if (users.isEmpty) {
      _showMessage('لا توجد بيانات لتصديرها.');
      return;
    }

    try {
      final exportedAt = DateTime.now();
      final fileName =
          'lingova-users-${exportedAt.year}-${exportedAt.month.toString().padLeft(2, '0')}-${exportedAt.day.toString().padLeft(2, '0')}.csv';
      await downloadTextFile(
        fileName: fileName,
        content: _usersToCsv(users),
        mimeType: 'text/csv;charset=utf-8',
      );
      _showMessage('تم تجهيز ملف المستخدمين.');
    } catch (_) {
      _showMessage('تعذر تصدير المستخدمين.');
    }
  }

  String _usersToCsv(List<AdminUser> users) {
    final rows = <List<String>>[
      [
        'الاسم',
        'رقم الهاتف',
        'الصلاحية',
        'الحالة',
        'المحافظة',
        'الوظيفة',
        'اللغة',
        'سبب التعلم',
        'سبب اختيار المنصة',
        'تاريخ الإضافة',
        'أضيف بواسطة',
      ],
      ...users.map(
        (user) => [
          user.fullName,
          user.phone,
          user.roleLabel,
          user.isSuspended ? 'معلق' : 'نشط',
          user.address,
          user.job,
          user.language,
          user.learningReason,
          user.referralReason,
          user.createdAtLabel,
          user.createdBy,
        ],
      ),
    ];

    return '\ufeff${rows.map((row) => row.map(_csvCell).join(',')).join('\n')}';
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  List<AdminUser> _filterUsers(List<AdminUser> users) {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      final searchText =
          '${user.fullName} ${user.phone} ${user.language} ${user.job} ${user.roleLabel}'
              .toLowerCase();
      return searchText.contains(query);
    }).toList();
  }

  Future<void> _openUserDialog({AdminUser? user}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _UserFormDialog(user: user),
    );
    if (result == null) {
      return;
    }

    if (user == null) {
      await _runAction(() => _service.createUser(widget.session.token, result));
    } else {
      final updates = _changedUserFields(user, result);
      if (updates.isEmpty) {
        return;
      }
      await _runAction(
        () => _service.updateUser(widget.session.token, user.id, updates),
      );
    }
  }

  Map<String, dynamic> _changedUserFields(
    AdminUser user,
    Map<String, dynamic> formData,
  ) {
    final updates = <String, dynamic>{};
    final currentValues = <String, String>{
      'fullName': user.fullName,
      'phone': user.phone,
      'address': user.address,
      'job': user.job,
      'language': user.language,
      'learningReason': user.learningReason,
      'referralReason': user.referralReason,
      'role': user.role,
    };

    for (final entry in currentValues.entries) {
      final nextValue = formData[entry.key]?.toString().trim() ?? '';
      if (nextValue != entry.value) {
        updates[entry.key] = nextValue;
      }
    }

    final password = formData['password']?.toString() ?? '';
    if (password.isNotEmpty) {
      updates['password'] = password;
    }

    return updates;
  }

  Future<void> _changePassword(AdminUser user) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(),
    );
    if (password == null) {
      return;
    }
    await _runAction(
      () => _service.changePassword(widget.session.token, user.id, password),
    );
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل تريد حذف ${user.fullName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _runAction(() => _service.deleteUser(widget.session.token, user.id));
  }

  Future<void> _toggleSuspension(AdminUser user) async {
    await _runAction(
      () => _service.updateUser(widget.session.token, user.id, {
        'status': user.isSuspended ? 'active' : 'suspended',
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminUser>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final users = _filterUsers(snapshot.data ?? const []);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'المستخدمين',
              subtitle:
                  'إدارة حسابات الطلاب والأدمن وتحديد نوع الصلاحية لكل حساب.',
              action: Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbarButton(
                    onPressed: isLoading ? null : () => _exportUsers(users),
                    icon: const Icon(Icons.file_download_rounded),
                    label: 'تصدير',
                  ),
                  _ToolbarButton(
                    onPressed: () => _openUserDialog(),
                    icon: const Icon(Icons.person_add_rounded),
                    label: 'إضافة مستخدم',
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) => _pendingQuery = value,
                      onSubmitted: (_) => _searchUsers(),
                      decoration: const InputDecoration(
                        labelText:
                            'بحث باسم المستخدم أو رقم الهاتف أو اللغة أو الصلاحية',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(104, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _searchUsers,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('بحث'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              _ErrorState(message: 'تعذر تحميل قائمة المستخدمين.')
            else if (users.isEmpty)
              const _EmptyState()
            else
              ...users.map(
                (user) => _UserTile(
                  user: user,
                  onEdit: () => _openUserDialog(user: user),
                  onPassword: () => _changePassword(user),
                  onSuspend: () => _toggleSuspension(user),
                  onDelete: () => _deleteUser(user),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminSubscriptionsPage extends StatefulWidget {
  final AdminSession session;

  const AdminSubscriptionsPage({super.key, required this.session});

  @override
  State<AdminSubscriptionsPage> createState() => _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends State<AdminSubscriptionsPage> {
  final _service = AdminApiService();
  final _searchController = TextEditingController();
  late Future<List<AdminSubscriptionRequest>> _requestsFuture;
  final Set<String> _approvingIds = {};
  String _pendingQuery = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _requestsFuture = _service.getSubscriptionRequests(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _requestsFuture = _service.getSubscriptionRequests(widget.session.token);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchRequests() {
    setState(() => _query = _pendingQuery.trim());
  }

  List<AdminSubscriptionRequest> _filterRequests(
    List<AdminSubscriptionRequest> requests,
  ) {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return requests;
    }
    return requests.where((request) {
      final searchText =
          '${request.studentName} ${request.studentPhone} ${request.courseTitle} ${request.courseLanguage} ${request.statusLabel} ${request.paymentMethod}'
              .toLowerCase();
      return searchText.contains(query);
    }).toList();
  }

  Future<void> _exportRequests(List<AdminSubscriptionRequest> requests) async {
    if (requests.isEmpty) {
      _showMessage('لا توجد طلبات لتصديرها.');
      return;
    }

    try {
      final exportedAt = DateTime.now();
      final fileName =
          'lingova-subscriptions-${exportedAt.year}-${exportedAt.month.toString().padLeft(2, '0')}-${exportedAt.day.toString().padLeft(2, '0')}.csv';
      await downloadTextFile(
        fileName: fileName,
        content: _requestsToCsv(requests),
        mimeType: 'text/csv;charset=utf-8',
      );
      _showMessage('تم تجهيز ملف طلبات الاشتراك.');
    } catch (_) {
      _showMessage('تعذر تصدير طلبات الاشتراك.');
    }
  }

  String _requestsToCsv(List<AdminSubscriptionRequest> requests) {
    final rows = <List<String>>[
      [
        'وقت الطلب',
        'الطالب',
        'رقم الهاتف',
        'الكورس',
        'لغة الكورس',
        'المستوى',
        'السعر',
        'الحالة',
        'طريقة الدفع',
        'تاريخ الدفع',
        'الرقم المحول منه',
        'المبلغ المدفوع',
      ],
      ...requests.map(
        (request) => [
          request.requestedAtLabel,
          request.studentName,
          request.studentPhone,
          request.courseTitle,
          request.courseLanguage,
          request.courseLevel,
          request.priceLabel,
          request.statusLabel,
          request.paymentMethod,
          request.paymentDate,
          request.paymentPhone,
          request.paidAmount,
        ],
      ),
    ];

    return '\ufeff${rows.map((row) => row.map(_subscriptionCsvCell).join(',')).join('\n')}';
  }

  String _subscriptionCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _approve(AdminSubscriptionRequest request) async {
    final paymentData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PaymentDialog(request: request),
    );
    if (paymentData == null) {
      return;
    }

    setState(() => _approvingIds.add(request.id));
    try {
      await _service.approveSubscriptionRequest(
        widget.session.token,
        request.id,
        paymentData,
      );
      if (!mounted) return;
      _showMessage('تم فتح الكورس للطالب.');
      _refresh();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر اعتماد طلب الاشتراك.');
    } finally {
      if (mounted) {
        setState(() => _approvingIds.remove(request.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminSubscriptionRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final requests = _filterRequests(
          snapshot.data ?? const <AdminSubscriptionRequest>[],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'طلبات الاشتراك',
              subtitle:
                  'كل طلب اشتراك يظهر هنا بوقت الطلب وبيانات الطالب والكورس، ويمكن اعتماد الدفع لفتح الكورس.',
              action: Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbarButton(
                    onPressed: isLoading
                        ? null
                        : () => _exportRequests(requests),
                    icon: const Icon(Icons.file_download_rounded),
                    label: 'تصدير',
                  ),
                  _ToolbarButton(
                    onPressed: isLoading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: 'تحديث',
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) => _pendingQuery = value,
                      onSubmitted: (_) => _searchRequests(),
                      decoration: const InputDecoration(
                        labelText:
                            'بحث باسم الطالب أو رقم الهاتف أو الكورس أو الحالة',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(104, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _searchRequests,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('بحث'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              _ErrorState(message: 'تعذر تحميل طلبات الاشتراك.')
            else if (requests.isEmpty)
              _Panel(
                child: Text(
                  'لا توجد طلبات اشتراك حتى الآن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...requests.map(
                (request) => _SubscriptionRequestCard(
                  request: request,
                  isApproving: _approvingIds.contains(request.id),
                  onApprove: request.isApproved
                      ? null
                      : () => _approve(request),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubscriptionRequestCard extends StatelessWidget {
  final AdminSubscriptionRequest request;
  final bool isApproving;
  final VoidCallback? onApprove;

  const _SubscriptionRequestCard({
    required this.request,
    required this.isApproving,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  request.isApproved
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        request.courseTitle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.studentName} - ${request.requestedAtLabel}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SubscriptionStatusChip(request: request),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                textDirection: TextDirection.rtl,
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 6,
                children: [
                  _InfoText(
                    icon: Icons.phone_rounded,
                    text: request.studentPhone,
                  ),
                  _InfoText(
                    icon: Icons.translate_rounded,
                    text: request.courseLanguage,
                  ),
                  _InfoText(
                    icon: Icons.signal_cellular_alt_rounded,
                    text: request.courseLevel,
                  ),
                  _InfoText(
                    icon: Icons.payments_rounded,
                    text: request.priceLabel,
                  ),
                  _InfoText(
                    icon: Icons.location_on_rounded,
                    text: request.studentAddress,
                  ),
                  _InfoText(icon: Icons.work_rounded, text: request.studentJob),
                ],
              ),
            ),
            if (request.isApproved) ...[
              const SizedBox(height: 12),
              _PaymentSummary(request: request),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: isApproving ? null : onApprove,
                icon: isApproving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_rounded),
                label: Text(
                  request.isApproved
                      ? 'تم فتح الكورس'
                      : isApproving
                      ? 'جاري الاعتماد...'
                      : 'إضافة مدفوعات وفتح الكورس',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final AdminSubscriptionRequest request;

  const _PaymentSummary({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        textDirection: TextDirection.rtl,
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 8,
        children: [
          _RequestInfo(label: 'طريقة الدفع', value: request.paymentMethod),
          _RequestInfo(label: 'تاريخ الدفع', value: request.paymentDate),
          _RequestInfo(label: 'الرقم المحول منه', value: request.paymentPhone),
          _RequestInfo(label: 'المبلغ المدفوع', value: request.paidAmount),
        ],
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final AdminSubscriptionRequest request;

  const _PaymentDialog({required this.request});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  String? _method;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _amount.text = widget.request.coursePrice == 'مجانا'
        ? ''
        : widget.request.coursePrice;
  }

  @override
  void dispose() {
    _date.dispose();
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop({
      'paymentMethod': _method ?? '',
      'paymentDate': _date.text.trim(),
      'paymentPhone': _phone.text.trim(),
      'paidAmount': _amount.text.trim(),
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _date.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة المدفوعات'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الدفع',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'محفظة إلكترونية',
                      child: Text('محفظة إلكترونية'),
                    ),
                    DropdownMenuItem(
                      value: 'انستا باي',
                      child: Text('انستا باي'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _date,
                  label: 'تاريخ الدفع',
                  validator: _required,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(Icons.calendar_month_rounded),
                ),
                _DialogField(
                  controller: _phone,
                  label: 'الرقم المحول منه',
                  validator: _required,
                  keyboardType: TextInputType.phone,
                ),
                _DialogField(
                  controller: _amount,
                  label: 'المبلغ المدفوع',
                  validator: _required,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _submit, child: const Text('فتح الكورس')),
        ],
      ),
    );
  }
}

class _RequestInfo extends StatelessWidget {
  final String label;
  final String value;

  const _RequestInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionStatusChip extends StatelessWidget {
  final AdminSubscriptionRequest request;

  const _SubscriptionStatusChip({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: request.isApproved
            ? Colors.green.withValues(alpha: .16)
            : AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: request.isApproved ? Colors.green : AppColors.orange,
        ),
      ),
      child: Text(
        request.statusLabel,
        style: TextStyle(
          color: request.isApproved ? Colors.green : AppColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AdminWatchReportPage extends StatefulWidget {
  final AdminSession session;

  const AdminWatchReportPage({super.key, required this.session});

  @override
  State<AdminWatchReportPage> createState() => _AdminWatchReportPageState();
}

class AdminExamsPage extends StatefulWidget {
  final AdminSession session;

  const AdminExamsPage({super.key, required this.session});

  @override
  State<AdminExamsPage> createState() => _AdminExamsPageState();
}

class _AdminExamsPageState extends State<AdminExamsPage> {
  final _service = ExamApiService();
  late Future<List<CourseExam>> _examsFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _examsFuture = _service.getAdminExams(widget.session.token);
  }

  void _refresh() {
    setState(() => _examsFuture = _service.getAdminExams(widget.session.token));
  }

  Future<void> _createExam() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ExamFormDialog(token: widget.session.token),
    );
    if (result == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _service.createExam(widget.session.token, result);
      if (!mounted) return;
      _showMessage('تم حفظ الامتحان.');
      _refresh();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر حفظ الامتحان.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openExamQuestions(CourseExam exam) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminExamQuestionsPage(session: widget.session, exam: exam),
      ),
    );
    _refresh();
  }

  Future<void> _deleteExam(CourseExam exam) async {
    await _service.deleteExam(widget.session.token, exam.id);
    _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseExam>>(
      future: _examsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final exams = snapshot.data ?? const <CourseExam>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'الامتحانات',
              subtitle:
                  'أضف كويز بعد محاضرة معينة أو امتحان نهاية مستوى، وحدد نوع الأسئلة والإجابات الصحيحة.',
              action: Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                children: [
                  _ToolbarButton(
                    onPressed: isLoading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: 'تحديث',
                  ),
                  _ToolbarButton(
                    onPressed: _isSaving ? null : _createExam,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    label: 'إضافة امتحان',
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const _ErrorState(message: 'تعذر تحميل الامتحانات.')
            else if (exams.isEmpty)
              _Panel(
                child: Text(
                  'لا توجد امتحانات حتى الآن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...exams.map(
                (exam) => _AdminExamCard(
                  exam: exam,
                  onOpen: () => _openExamQuestions(exam),
                  onDelete: () => _deleteExam(exam),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminExamReportsPage extends StatefulWidget {
  final AdminSession session;

  const AdminExamReportsPage({super.key, required this.session});

  @override
  State<AdminExamReportsPage> createState() => _AdminExamReportsPageState();
}

class _AdminExamReportsPageState extends State<AdminExamReportsPage> {
  final _service = ExamApiService();
  late Future<ExamReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _service.getAdminExamReport(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _reportFuture = _service.getAdminExamReport(widget.session.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExamReport>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final report = snapshot.data;
        final summary = report?.summary;
        final results = report?.results ?? const <ExamResult>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'تقارير الامتحانات',
              subtitle:
                  'متابعة نتائج الكويزات وامتحانات نهاية المستوى لكل الطلاب.',
              action: _ToolbarButton(
                onPressed: isLoading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: 'تحديث',
                filled: true,
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const _ErrorState(message: 'تعذر تحميل تقارير الامتحانات.')
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 4 ? 1.45 : 1.2,
                    children: [
                      _MetricCard(
                        title: 'عدد المحاولات',
                        value: (summary?.attemptsCount ?? 0).toString(),
                        icon: Icons.assignment_rounded,
                      ),
                      _MetricCard(
                        title: 'ناجح',
                        value: (summary?.passedCount ?? 0).toString(),
                        icon: Icons.check_circle_rounded,
                      ),
                      _MetricCard(
                        title: 'لم ينجح',
                        value: (summary?.failedCount ?? 0).toString(),
                        icon: Icons.cancel_rounded,
                      ),
                      _MetricCard(
                        title: 'متوسط النتيجة',
                        value: '${summary?.averageScore ?? 0}%',
                        icon: Icons.trending_up_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              if (results.isEmpty)
                _Panel(
                  child: Text(
                    'لا توجد نتائج امتحانات حتى الآن.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ...results.map((result) => _ExamResultCard(result: result)),
            ],
          ],
        );
      },
    );
  }
}

class _ExamResultCard extends StatelessWidget {
  final ExamResult result;

  const _ExamResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final statusColor = result.passed ? Colors.green : Colors.redAccent;
    final studentName = result.studentName.isEmpty
        ? 'طالب'
        : result.studentName;
    final courseTitle = result.courseTitle.isEmpty ? '-' : result.courseTitle;
    final levelTitle = result.levelTitle.isEmpty ? '-' : result.levelTitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatusPill(text: result.statusLabel, color: statusColor),
                Text(
                  studentName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$courseTitle • $levelTitle • ${result.typeLabel}',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Wrap(
              textDirection: TextDirection.rtl,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  text: 'النتيجة ${result.score}%',
                  color: statusColor,
                ),
                _StatusPill(
                  text:
                      'الصحيح ${result.correctAnswers}/${result.totalQuestions}',
                  color: AppColors.orange,
                ),
                if (result.submittedAtLabel.isNotEmpty)
                  _StatusPill(
                    text: result.submittedAtLabel,
                    color: AppColors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCertificatesPage extends StatefulWidget {
  final AdminSession session;

  const AdminCertificatesPage({super.key, required this.session});

  @override
  State<AdminCertificatesPage> createState() => _AdminCertificatesPageState();
}

class _AdminCertificatesPageState extends State<AdminCertificatesPage> {
  final _service = ExamApiService();
  late Future<ExamReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _service.getAdminExamReport(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _reportFuture = _service.getAdminExamReport(widget.session.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExamReport>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final report = snapshot.data;
        final finalResults =
            report?.results
                .where((result) => result.type == 'level_final')
                .toList() ??
            const <ExamResult>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'الشهادات',
              subtitle: 'عرض وتحميل شهادات امتحانات نهاية المستوى.',
              action: _ToolbarButton(
                onPressed: isLoading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: 'تحديث',
                filled: true,
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const _ErrorState(message: 'تعذر تحميل بيانات الشهادات.')
            else if (finalResults.isEmpty)
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'لا توجد نتائج امتحانات نهاية المستوى للشهادات حتى الآن.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك تحميل شهادة كل طالب عن طريق الضغط على زر التحميل في أي نتيجة مؤهلة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              ...finalResults.map(
                (result) => _AdminCertificateCard(result: result),
              ),
          ],
        );
      },
    );
  }
}

class _AdminCertificateCard extends StatelessWidget {
  final ExamResult result;

  const _AdminCertificateCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final statusColor = result.passed ? Colors.green : Colors.redAccent;
    final studentName = result.studentName.isEmpty
        ? 'طالب'
        : result.studentName;
    final courseTitle = result.courseTitle.isEmpty ? '-' : result.courseTitle;
    final levelTitle = result.levelTitle.isEmpty ? '-' : result.levelTitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatusPill(text: result.statusLabel, color: statusColor),
                Text(
                  studentName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$courseTitle • $levelTitle • ${result.typeLabel}',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Wrap(
              textDirection: TextDirection.rtl,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  text: 'النتيجة ${result.score}%',
                  color: statusColor,
                ),
                _StatusPill(
                  text:
                      'الصحيح ${result.correctAnswers}/${result.totalQuestions}',
                  color: AppColors.orange,
                ),
                if (result.submittedAtLabel.isNotEmpty)
                  _StatusPill(
                    text: result.submittedAtLabel,
                    color: AppColors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CertificatePage(result: result),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('تحميل الشهادة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminExamCard extends StatelessWidget {
  final CourseExam exam;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _AdminExamCard({
    required this.exam,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final placement = exam.type == 'level_final'
        ? 'نهاية المستوى'
        : 'بعد المحاضرة ${exam.afterLectureIndex}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _StatusPill(text: exam.typeLabel, color: AppColors.orange),
                    Text(
                      exam.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${exam.courseLanguage} • ${exam.courseTitle} • ${exam.levelTitle} • $placement',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  textDirection: TextDirection.rtl,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      text: '${exam.questions.length} سؤال',
                      color: Colors.green,
                    ),
                    _StatusPill(
                      text: 'النجاح ${exam.passScore}%',
                      color: Colors.green,
                    ),
                    _StatusPill(
                      text: '${exam.durationMinutes} دقيقة',
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('الأسئلة'),
                      ),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('حذف'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminWatchReportPageState extends State<AdminWatchReportPage> {
  final _service = WatchProgressApiService();
  late Future<WatchReport> _reportFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  Future<WatchReport> _loadReport() {
    return _service.getAdminWatchReport(
      token: widget.session.token,
      date: _selectedDate,
    );
  }

  void _refresh() {
    setState(() => _reportFuture = _loadReport());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked;
      _reportFuture = _loadReport();
    });
  }

  String get _selectedDateLabel {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WatchReport>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final report = snapshot.data;
        final summary = report?.summary;
        final records = report?.records ?? const <WatchProgressRecord>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'تقرير المشاهدة اليومي',
              subtitle:
                  'تفاصيل الأجزاء التي شاهدها الطلاب بالكامل خلال اليوم المحدد.',
              action: Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbarButton(
                    onPressed: isLoading ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: _selectedDateLabel,
                  ),
                  _ToolbarButton(
                    onPressed: isLoading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: 'تحديث',
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const _ErrorState(message: 'تعذر تحميل تقرير المشاهدة.')
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 4 ? 1.45 : 1.2,
                    children: [
                      _MetricCard(
                        title: 'الأجزاء المكتملة',
                        value: (summary?.completedPartsCount ?? 0).toString(),
                        icon: Icons.check_circle_rounded,
                      ),
                      _MetricCard(
                        title: 'الطلاب النشطين',
                        value: (summary?.studentsCount ?? 0).toString(),
                        icon: Icons.people_alt_rounded,
                      ),
                      _MetricCard(
                        title: 'الكورسات',
                        value: (summary?.coursesCount ?? 0).toString(),
                        icon: Icons.menu_book_rounded,
                      ),
                      _MetricCard(
                        title: 'مرات المشاهدة',
                        value: (summary?.totalWatchCount ?? 0).toString(),
                        icon: Icons.visibility_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              if (records.isEmpty)
                _Panel(
                  child: Text(
                    'لا توجد مشاهدات كاملة في هذا اليوم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ...records.map((record) => _WatchReportCard(record: record)),
            ],
          ],
        );
      },
    );
  }
}

class _WatchReportCard extends StatelessWidget {
  final WatchProgressRecord record;

  const _WatchReportCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatusPill(text: record.completedAtLabel, color: Colors.green),
                Text(
                  record.studentName.isEmpty ? 'طالب' : record.studentName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.studentPhone,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              '${record.courseTitle} • ${record.courseLanguage}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${record.levelTitle} • ${record.lectureTitle} • ${record.partTitle}',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            Wrap(
              textDirection: TextDirection.rtl,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  text:
                      'المدة ${record.duration.isEmpty ? '-' : record.duration}',
                  color: AppColors.orange,
                ),
                _StatusPill(
                  text: 'عدد المرات ${record.watchCount}',
                  color: AppColors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamFormDialog extends StatefulWidget {
  final String token;

  const _ExamFormDialog({required this.token});

  @override
  State<_ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends State<_ExamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminApiService();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _passScore = TextEditingController(text: '60');
  final _duration = TextEditingController(text: '10');
  late Future<List<AdminCoursePart>> _coursePartsFuture;
  String _type = 'lecture_quiz';
  String? _selectedCourseKey;
  String? _selectedLevel;
  String? _selectedLecture;

  @override
  void initState() {
    super.initState();
    _coursePartsFuture = _adminService.getCourseParts(widget.token);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _passScore.dispose();
    _duration.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب';
    }
    return null;
  }

  List<_ExamCourseOption> _courseOptions(List<AdminCoursePart> parts) {
    final map = <String, _ExamCourseOption>{};
    for (final part in parts) {
      if (part.language.trim().isEmpty || part.course.trim().isEmpty) {
        continue;
      }
      final key = '${part.language}|${part.course}';
      map.putIfAbsent(
        key,
        () => _ExamCourseOption(
          key: key,
          language: part.language,
          course: part.course,
        ),
      );
    }
    return map.values.toList()..sort((a, b) => a.label.compareTo(b.label));
  }

  _ExamCourseOption? _selectedCourse(List<AdminCoursePart> parts) {
    final key = _selectedCourseKey;
    if (key == null) {
      return null;
    }
    for (final option in _courseOptions(parts)) {
      if (option.key == key) {
        return option;
      }
    }
    return null;
  }

  List<String> _levelsFor(List<AdminCoursePart> parts) {
    final course = _selectedCourse(parts);
    if (course == null) {
      return const [];
    }
    final levels = <String>{};
    for (final part in parts) {
      if (part.language == course.language &&
          part.course == course.course &&
          part.level.trim().isNotEmpty) {
        levels.add(part.level);
      }
    }
    return levels.toList()..sort();
  }

  List<String> _lecturesFor(List<AdminCoursePart> parts) {
    final course = _selectedCourse(parts);
    final level = _selectedLevel;
    if (course == null || level == null) {
      return const [];
    }
    final lectures = <String>[];
    for (final part in parts) {
      if (part.language == course.language &&
          part.course == course.course &&
          part.level == level &&
          part.lecture.trim().isNotEmpty &&
          !lectures.contains(part.lecture)) {
        lectures.add(part.lecture);
      }
    }
    return lectures;
  }

  void _submit(List<AdminCoursePart> parts) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final course = _selectedCourse(parts);
    final level = _selectedLevel;
    final lecture = _selectedLecture;
    final lectures = _lecturesFor(parts);
    if (course == null || level == null) {
      return;
    }
    if (_type == 'lecture_quiz' && lecture == null) {
      return;
    }

    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'type': _type,
      'courseTitle': course.course,
      'courseLanguage': course.language,
      'levelTitle': level,
      'afterLectureIndex': _type == 'lecture_quiz'
          ? lectures.indexOf(lecture!) + 1
          : 0,
      'passScore': int.tryParse(_passScore.text.trim()) ?? 60,
      'durationMinutes': int.tryParse(_duration.text.trim()) ?? 10,
      'questions': const [],
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminCoursePart>>(
      future: _coursePartsFuture,
      builder: (context, snapshot) {
        return AlertDialog(
          title: const Text('إضافة امتحان', textAlign: TextAlign.right),
          content: SizedBox(
            width: 680,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildContent(snapshot),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: snapshot.hasData
                  ? () => _submit(snapshot.data!)
                  : null,
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(AsyncSnapshot<List<AdminCoursePart>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'تعذر تحميل الكورسات.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final parts = snapshot.data ?? const <AdminCoursePart>[];
    final courses = _courseOptions(parts);
    final levels = _levelsFor(parts);
    final lectures = _lecturesFor(parts);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'lecture_quiz',
                  label: Text('كويز بعد محاضرة'),
                  icon: Icon(Icons.quiz_rounded),
                ),
                ButtonSegment(
                  value: 'level_final',
                  label: Text('نهاية مستوى'),
                  icon: Icon(Icons.workspace_premium_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.first;
                  if (_type == 'level_final') {
                    _selectedLecture = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            _DialogField(
              controller: _title,
              label: 'عنوان الامتحان',
              validator: _required,
            ),
            _DialogField(controller: _description, label: 'وصف مختصر'),
            _DialogDropdown(
              value: _selectedCourseKey,
              label: 'اسم الكورس',
              icon: Icons.menu_book_rounded,
              items: courses.map((course) => course.key).toList(),
              itemLabels: {
                for (final course in courses) course.key: course.label,
              },
              onChanged: (value) {
                setState(() {
                  _selectedCourseKey = value;
                  _selectedLevel = null;
                  _selectedLecture = null;
                });
              },
              validator: _required,
            ),
            _DialogDropdown(
              value: levels.contains(_selectedLevel) ? _selectedLevel : null,
              label: 'اسم الليفيل',
              icon: Icons.layers_rounded,
              items: levels,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value;
                  _selectedLecture = null;
                });
              },
              validator: _required,
            ),
            if (_type == 'lecture_quiz')
              _DialogDropdown(
                value: lectures.contains(_selectedLecture)
                    ? _selectedLecture
                    : null,
                label: 'الكويز يظهر بعد محاضرة',
                icon: Icons.play_lesson_rounded,
                items: lectures,
                onChanged: (value) {
                  setState(() => _selectedLecture = value);
                },
                validator: _required,
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'مكان الامتحان',
                    prefixIcon: Icon(Icons.workspace_premium_rounded),
                  ),
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Text('بعد نهاية المستوى فقط'),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _DialogField(
                    controller: _passScore,
                    label: 'درجة النجاح %',
                    validator: _required,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogField(
                    controller: _duration,
                    label: 'المدة بالدقائق',
                    validator: _required,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCourseOption {
  final String key;
  final String language;
  final String course;

  const _ExamCourseOption({
    required this.key,
    required this.language,
    required this.course,
  });

  String get label => '$language - $course';
}

class AdminExamQuestionsPage extends StatefulWidget {
  final AdminSession session;
  final CourseExam exam;

  const AdminExamQuestionsPage({
    super.key,
    required this.session,
    required this.exam,
  });

  @override
  State<AdminExamQuestionsPage> createState() => _AdminExamQuestionsPageState();
}

class _AdminExamQuestionsPageState extends State<AdminExamQuestionsPage> {
  final _service = ExamApiService();
  late final List<ExamQuestion> _savedQuestions;
  _QuestionDraft? _activeDraft;
  int? _editingIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _savedQuestions = widget.exam.questions.toList(growable: true);
    if (_savedQuestions.isEmpty) {
      _activeDraft = _QuestionDraft();
    }
  }

  @override
  void dispose() {
    _activeDraft?.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion(_QuestionDraft draft) async {
    if (!draft.isValid) {
      _showMessage('راجع نص السؤال والإجابة الصحيحة والاختيارات.');
      return;
    }

    final nextQuestion = draft.toExamQuestion();
    final questions = _savedQuestions.toList(growable: true);
    final editingIndex = _editingIndex;
    if (editingIndex == null) {
      questions.add(nextQuestion);
    } else {
      questions[editingIndex] = nextQuestion;
    }
    final hasInvalid = questions.any(
      (question) =>
          question.prompt.trim().isEmpty || question.correctAnswers.isEmpty,
    );
    if (hasInvalid) {
      _showMessage('راجع نص السؤال والإجابة الصحيحة.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.updateExamQuestions(
        widget.session.token,
        widget.exam.id,
        questions,
      );
      if (!mounted) return;
      setState(() {
        _savedQuestions
          ..clear()
          ..addAll(questions);
        _activeDraft?.dispose();
        _activeDraft = null;
        _editingIndex = null;
      });
      _showMessage('تم حفظ السؤال.');
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر حفظ الأسئلة.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  void _addQuestion() {
    setState(() {
      _activeDraft?.dispose();
      _activeDraft = _QuestionDraft();
      _editingIndex = null;
    });
  }

  void _editQuestion(int index) {
    setState(() {
      _activeDraft?.dispose();
      _activeDraft = _QuestionDraft.fromQuestion(_savedQuestions[index]);
      _editingIndex = index;
    });
  }

  Future<void> _deleteQuestion(int index) async {
    final questions = _savedQuestions.toList(growable: true)..removeAt(index);
    setState(() => _isSaving = true);
    try {
      await _service.updateExamQuestions(
        widget.session.token,
        widget.exam.id,
        questions,
      );
      if (!mounted) return;
      setState(() {
        _savedQuestions
          ..clear()
          ..addAll(questions);
      });
      _showMessage('تم حذف السؤال.');
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('أسئلة ${widget.exam.title}')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'أسئلة الامتحان',
              subtitle:
                  '${widget.exam.courseTitle} • ${widget.exam.levelTitle} • ${widget.exam.typeLabel}',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbarButton(
                    onPressed: _activeDraft == null ? _addQuestion : null,
                    icon: const Icon(Icons.add_rounded),
                    label: 'إضافة سؤال جديد',
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ..._savedQuestions.asMap().entries.map((entry) {
              return _SavedQuestionCard(
                index: entry.key,
                question: entry.value,
                onEdit: () => _editQuestion(entry.key),
                onDelete: () => _deleteQuestion(entry.key),
              );
            }),
            if (_activeDraft != null)
              _QuestionDraftEditor(
                index: (_editingIndex ?? _savedQuestions.length) + 1,
                draft: _activeDraft!,
                isSaving: _isSaving,
                onSave: () => _saveQuestion(_activeDraft!),
                onCancel: () {
                  setState(() {
                    _activeDraft?.dispose();
                    _activeDraft = null;
                    _editingIndex = null;
                  });
                },
              ),
            if (_savedQuestions.isEmpty && _activeDraft == null)
              _Panel(
                child: Text(
                  'لا توجد أسئلة محفوظة. اضغط إضافة سؤال جديد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  final String id;
  final prompt = TextEditingController();
  final option1 = TextEditingController();
  final option2 = TextEditingController();
  final option3 = TextEditingController();
  final correctAnswers = TextEditingController();
  String type = 'mcq';

  _QuestionDraft({this.id = ''});

  factory _QuestionDraft.fromQuestion(ExamQuestion question) {
    return _QuestionDraft(id: question.id)
      ..type = question.type
      ..prompt.text = question.prompt
      ..option1.text = question.options.isNotEmpty ? question.options[0] : ''
      ..option2.text = question.options.length > 1 ? question.options[1] : ''
      ..option3.text = question.options.length > 2 ? question.options[2] : ''
      ..correctAnswers.text = question.correctAnswers.join('\n');
  }

  void dispose() {
    prompt.dispose();
    option1.dispose();
    option2.dispose();
    option3.dispose();
    correctAnswers.dispose();
  }

  bool get usesOptions => type == 'mcq';

  bool get hasContent {
    return prompt.text.trim().isNotEmpty ||
        correctAnswers.text.trim().isNotEmpty ||
        option1.text.trim().isNotEmpty ||
        option2.text.trim().isNotEmpty ||
        option3.text.trim().isNotEmpty;
  }

  bool get isValid {
    if (prompt.text.trim().isEmpty || correctAnswers.text.trim().isEmpty) {
      return false;
    }
    if (!usesOptions) {
      return true;
    }
    return _optionList.length == 3;
  }

  List<String> get _optionList {
    return [
      option1.text,
      option2.text,
      option3.text,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  Map<String, dynamic> toJson() {
    final answerList = correctAnswers.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return {
      'id': id,
      'type': type,
      'prompt': prompt.text.trim(),
      'options': type == 'true_false'
          ? ['صح', 'خطأ']
          : usesOptions
          ? _optionList
          : const <String>[],
      'correctAnswers': answerList,
    };
  }

  ExamQuestion toExamQuestion() {
    final json = toJson();
    return ExamQuestion.fromJson(json);
  }
}

class _QuestionDraftEditor extends StatefulWidget {
  final int index;
  final _QuestionDraft draft;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _QuestionDraftEditor({
    required this.index,
    required this.draft,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_QuestionDraftEditor> createState() => _QuestionDraftEditorState();
}

class _QuestionDraftEditorState extends State<_QuestionDraftEditor> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'سؤال ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.type,
            decoration: const InputDecoration(labelText: 'نوع السؤال'),
            items: const [
              DropdownMenuItem(
                value: 'mcq',
                child: Text('اختيارات متعددة MCQ'),
              ),
              DropdownMenuItem(value: 'true_false', child: Text('صح أو خطأ')),
              DropdownMenuItem(value: 'complete', child: Text('Complete')),
              DropdownMenuItem(value: 'audio', child: Text('Audio')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => draft.type = value);
            },
          ),
          const SizedBox(height: 12),
          _DialogField(
            controller: draft.prompt,
            label: 'نص السؤال',
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'مطلوب' : null,
          ),
          if (draft.usesOptions) ...[
            _DialogField(
              controller: draft.option1,
              label: 'الاختيار الأول',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'مطلوب' : null,
            ),
            _DialogField(
              controller: draft.option2,
              label: 'الاختيار الثاني',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'مطلوب' : null,
            ),
            _DialogField(
              controller: draft.option3,
              label: 'الاختيار الثالث',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'مطلوب' : null,
            ),
          ],
          _DialogField(
            controller: draft.correctAnswers,
            label: draft.type == 'true_false'
                ? 'الإجابة الصحيحة: صح أو خطأ'
                : 'الإجابة الصحيحة',
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'مطلوب' : null,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: widget.isSaving ? null : widget.onSave,
              icon: widget.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('حفظ السؤال'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedQuestionCard extends StatelessWidget {
  final int index;
  final ExamQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavedQuestionCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                _StatusPill(
                  text: _questionTypeLabel(question.type),
                  color: AppColors.orange,
                ),
                Text(
                  'سؤال ${index + 1}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.prompt,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
            ),
            if (question.options.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                runSpacing: 8,
                children: question.options
                    .map(
                      (option) =>
                          _StatusPill(text: option, color: Colors.green),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('تعديل'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('حذف'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _questionTypeLabel(String type) {
  return switch (type) {
    'mcq' => 'اختيارات متعددة MCQ',
    'true_false' => 'True Or False',
    'complete' => 'Complete',
    'audio' => 'Audio',
    'video' => 'Video',
    _ => type,
  };
}

class AdminQuestionsPage extends StatefulWidget {
  final AdminSession session;

  const AdminQuestionsPage({super.key, required this.session});

  @override
  State<AdminQuestionsPage> createState() => _AdminQuestionsPageState();
}

class _AdminQuestionsPageState extends State<AdminQuestionsPage> {
  final _service = AdminApiService();
  final _searchController = TextEditingController();
  late Future<List<CourseQuestion>> _questionsFuture;
  String _pendingQuery = '';
  String _query = '';
  final Set<String> _answeringIds = {};

  @override
  void initState() {
    super.initState();
    _questionsFuture = _service.getQuestions(widget.session.token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(
      () => _questionsFuture = _service.getQuestions(widget.session.token),
    );
  }

  void _searchQuestions() {
    setState(() => _query = _pendingQuery.trim());
  }

  List<CourseQuestion> _filterQuestions(List<CourseQuestion> questions) {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return questions;
    }

    return questions.where((question) {
      final searchText =
          '${question.studentName} ${question.courseTitle} ${question.courseLanguage} ${question.lectureTitle} ${question.partTitle} ${question.question} ${question.answer}'
              .toLowerCase();
      return searchText.contains(query);
    }).toList();
  }

  Future<void> _answerQuestion(CourseQuestion question) async {
    final controller = TextEditingController(text: question.answer);
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('الرد على السؤال'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.question,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'اكتب الرد',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('حفظ الرد'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    final text = answer?.trim() ?? '';
    if (text.isEmpty) {
      return;
    }

    setState(() => _answeringIds.add(question.id));
    try {
      await _service.answerQuestion(widget.session.token, question.id, text);
      if (!mounted) return;
      _showMessage('تم حفظ الرد.');
      _refresh();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر حفظ الرد.');
    } finally {
      if (mounted) {
        setState(() => _answeringIds.remove(question.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseQuestion>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final questions = _filterQuestions(
          snapshot.data ?? const <CourseQuestion>[],
        );
        final pendingCount = questions.where((item) => !item.isAnswered).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: 'أسئلة الطلاب',
              subtitle:
                  'راجع أسئلة الطلاب على أجزاء الدروس واكتب الردود التي ستظهر لهم داخل صفحة الفيديو.',
              action: Wrap(
                textDirection: TextDirection.rtl,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbarButton(
                    onPressed: isLoading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: 'تحديث',
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) => _pendingQuery = value,
                      onSubmitted: (_) => _searchQuestions(),
                      decoration: const InputDecoration(
                        labelText: 'بحث باسم الطالب أو الكورس أو السؤال',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(104, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _searchQuestions,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('بحث'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$pendingCount سؤال بانتظار الرد',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: pendingCount == 0
                      ? AppColors.textMuted
                      : AppColors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const _ErrorState(message: 'تعذر تحميل أسئلة الطلاب.')
            else if (questions.isEmpty)
              _Panel(
                child: Text(
                  'لا توجد أسئلة حتى الآن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...questions.map(
                (question) => _AdminQuestionCard(
                  question: question,
                  isSaving: _answeringIds.contains(question.id),
                  onAnswer: () => _answerQuestion(question),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminQuestionCard extends StatelessWidget {
  final CourseQuestion question;
  final bool isSaving;
  final VoidCallback onAnswer;

  const _AdminQuestionCard({
    required this.question,
    required this.isSaving,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                _StatusPill(
                  text: question.isAnswered ? 'تم الرد' : 'بانتظار الرد',
                  color: question.isAnswered ? Colors.green : AppColors.orange,
                ),
                Text(
                  question.studentName.isEmpty ? 'طالب' : question.studentName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${question.courseTitle} • ${question.levelTitle} • ${question.lectureTitle} • ${question.partTitle}',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.45),
            ),
            if (question.answer.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.answer,
                  textAlign: TextAlign.right,
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onAnswer,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.reply_rounded),
                label: Text(question.isAnswered ? 'تعديل الرد' : 'رد'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class AdminNotificationsPage extends StatefulWidget {
  final AdminSession session;

  const AdminNotificationsPage({super.key, required this.session});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _service = AdminApiService();
  late Future<List<AdminAppNotification>> _notificationsFuture;
  late Future<List<AdminUser>> _usersFuture;
  bool _isSending = false;
  String _query = '';
  String _typeFilter = 'all';
  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _service.getNotifications(widget.session.token);
    _usersFuture = _service.getUsers(widget.session.token);
  }

  void _refresh() {
    setState(() {
      _notificationsFuture = _service.getNotifications(widget.session.token);
      _usersFuture = _service.getUsers(widget.session.token);
      _page = 0;
    });
  }

  Future<void> _createNotification() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _NotificationFormDialog(usersFuture: _usersFuture),
    );
    if (result == null) return;

    setState(() => _isSending = true);
    try {
      final sendResult = await _service.createNotification(
        widget.session.token,
        result,
      );
      if (!mounted) return;

      _showMessage(
        sendResult.pushFailureReason == null
            ? 'تم إرسال الإشعار.'
            : 'تم حفظ الإشعار، لكن الـ Push فشل: ${sendResult.pushFailureReason}',
      );

      if (sendResult.unmatchedPhones.isNotEmpty) {
        _showMessage(
          'أرقام غير موجودة: ${sendResult.unmatchedPhones.join(', ')}',
        );
      }

      _refresh();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر إرسال الإشعار.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteNotification(AdminAppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الإشعار'),
          content: Text('هل تريد حذف "${notification.title}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_rounded),
              label: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteNotification(widget.session.token, notification.id);
      if (!mounted) return;
      _showMessage('تم حذف الإشعار.');
      _refresh();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر حذف الإشعار.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  List<AdminAppNotification> _filterNotifications(
    List<AdminAppNotification> notifications,
  ) {
    final query = _query.trim().toLowerCase();
    return notifications.where((notification) {
      if (_typeFilter != 'all' && notification.type != _typeFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final text =
          '${notification.title} ${notification.body} ${notification.type} ${notification.createdBy}'
              .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  DateTime? _notificationDate(AdminAppNotification notification) {
    return DateTime.tryParse(notification.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminAppNotification>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final allNotifications =
            snapshot.data ?? const <AdminAppNotification>[];
        final notifications = _filterNotifications(allNotifications);
        final now = DateTime.now();
        final total = allNotifications.length;
        final thisMonth = allNotifications.where((notification) {
          final date = _notificationDate(notification);
          return date != null &&
              date.year == now.year &&
              date.month == now.month;
        }).length;
        final int totalPages = notifications.isEmpty
            ? 1
            : (notifications.length / _pageSize).ceil();
        final int page = _page.clamp(0, totalPages - 1).toInt();
        final pagedNotifications = notifications
            .skip(page * _pageSize)
            .take(_pageSize)
            .toList(growable: false);

        if (page != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _page = page);
          });
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: AppColors.background,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(34, 22, 34, 30),
              children: [
                DefaultTextStyle.merge(
                  textAlign: TextAlign.right,
                  child: _NotificationHero(
                    isSending: _isSending,
                    isLoading: isLoading,
                    onCreate: _createNotification,
                    onRefresh: _refresh,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 1100
                        ? (constraints.maxWidth - 42) / 4
                        : constraints.maxWidth >= 760
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _NotificationStatCard(
                          width: cardWidth,
                          title: 'إجمالي الإشعارات',
                          subtitle: 'كل الإشعارات',
                          value: total.toString(),
                          icon: Icons.notifications_rounded,
                          color: const Color(0xFF2DD4BF),
                        ),
                        _NotificationStatCard(
                          width: cardWidth,
                          title: 'غير مقروءة',
                          subtitle: 'تحتاج متابعة',
                          value: notifications.length.toString(),
                          icon: Icons.mail_outline_rounded,
                          color: AppColors.orange,
                          highlighted: true,
                        ),
                        _NotificationStatCard(
                          width: cardWidth,
                          title: 'تم قراءتها',
                          subtitle: 'من واقع بيانات القراء',
                          value: 'Live',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF3ED47E),
                        ),
                        _NotificationStatCard(
                          width: cardWidth,
                          title: 'هذا الشهر',
                          subtitle: 'تم إرسالها',
                          value: thisMonth.toString(),
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _NotificationControls(
                  query: _query,
                  typeFilter: _typeFilter,
                  onQueryChanged: (value) => setState(() {
                    _query = value;
                    _page = 0;
                  }),
                  onFilterChanged: (value) => setState(() {
                    _typeFilter = value;
                    _page = 0;
                  }),
                ),
                const SizedBox(height: 22),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(44),
                      child: CircularProgressIndicator(color: AppColors.orange),
                    ),
                  )
                else if (snapshot.hasError)
                  const _ErrorState(message: 'تعذر تحميل الإشعارات.')
                else if (notifications.isEmpty)
                  const _PremiumGlass(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'لا توجد إشعارات مطابقة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFAAB4C4)),
                    ),
                  )
                else ...[
                  ...pagedNotifications.map(
                    (notification) => _AdminNotificationCard(
                      notification: notification,
                      onDelete: () => _deleteNotification(notification),
                      token: widget.session.token,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NotificationPagination(
                    page: page,
                    totalPages: totalPages,
                    totalItems: notifications.length,
                    pageSize: _pageSize,
                    onPageChanged: (value) => setState(() => _page = value),
                    onPageSizeChanged: (value) => setState(() {
                      _pageSize = value;
                      _page = 0;
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NotificationMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 17, color: AppColors.orange),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NotificationFormDialog extends StatefulWidget {
  final Future<List<AdminUser>> usersFuture;

  const _NotificationFormDialog({required this.usersFuture});

  @override
  State<_NotificationFormDialog> createState() =>
      _NotificationFormDialogState();
}

class _NotificationFormDialogState extends State<_NotificationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _studentSearch = TextEditingController();
  String _type = 'general';
  String _targetMode = 'all';
  String _studentQuery = '';
  final Set<String> _selectedUserIds = <String>{};
  final Set<String> _csvPhones = <String>{};

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _studentSearch.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_targetMode == 'specific' &&
        _selectedUserIds.isEmpty &&
        _csvPhones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ø§Ø®ØªØ± Ø·Ø§Ù„Ø¨ ÙˆØ§Ø­Ø¯ Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„ Ø£Ùˆ Ø§Ø±ÙØ¹ CSV.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'type': _type,
      'targetMode': _targetMode,
      'targetUserIds': _targetMode == 'specific'
          ? _selectedUserIds.toList(growable: false)
          : const <String>[],
      'targetPhones': _targetMode == 'specific'
          ? _csvPhones.toList(growable: false)
          : const <String>[],
    });
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    final file = result?.files.first;
    final bytes = file?.bytes;
    if (bytes == null) {
      return;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    final phones = _phonesFromCsv(content);
    setState(() {
      _targetMode = 'specific';
      _csvPhones
        ..clear()
        ..addAll(phones);
    });
  }

  List<String> _phonesFromCsv(String content) {
    final lines = const LineSplitter()
        .convert(content)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const [];
    }
    final headers = _splitCsvLine(
      lines.first,
    ).map((item) => item.trim().toLowerCase()).toList();
    final phoneIndex = headers.indexWhere(
      (item) => item == 'phone' || item == 'mobile',
    );
    if (phoneIndex < 0) {
      return const [];
    }
    return lines
        .skip(1)
        .map((line) {
          final cells = _splitCsvLine(line);
          if (phoneIndex >= cells.length) {
            return '';
          }
          return cells[phoneIndex].replaceAll(RegExp(r'\s+'), '');
        })
        .where((phone) => phone.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _splitCsvLine(String line) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        quoted = !quoted;
      } else if (char == ',' && !quoted) {
        cells.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString());
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إرسال إشعار'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'نوع الإشعار'),
                    items: const [
                      DropdownMenuItem(value: 'general', child: Text('عام')),
                      DropdownMenuItem(value: 'course', child: Text('كورس')),
                      DropdownMenuItem(value: 'lesson', child: Text('درس')),
                      DropdownMenuItem(value: 'exam', child: Text('اختبار')),
                      DropdownMenuItem(value: 'payment', child: Text('دفع')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _title,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإشعار',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _body,
                    minLines: 4,
                    maxLines: 7,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'محتوى الإشعار',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        icon: Icon(Icons.groups_rounded),
                        label: Text('All students'),
                      ),
                      ButtonSegment(
                        value: 'specific',
                        icon: Icon(Icons.person_search_rounded),
                        label: Text('Selected students'),
                      ),
                    ],
                    selected: {_targetMode},
                    onSelectionChanged: (value) {
                      setState(() => _targetMode = value.first);
                    },
                  ),
                  if (_targetMode == 'specific') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _studentSearch,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'Search by name or phone',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) =>
                          setState(() => _studentQuery = value),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _pickCsv,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _csvPhones.isEmpty
                            ? 'Upload CSV with phone or mobile column'
                            : 'CSV: ${_csvPhones.length} phones',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<AdminUser>>(
                      future: widget.usersFuture,
                      builder: (context, snapshot) {
                        final users = (snapshot.data ?? const <AdminUser>[])
                            .where((user) => !user.isAdminRole)
                            .where((user) {
                              final query = _studentQuery.trim().toLowerCase();
                              if (query.isEmpty) {
                                return true;
                              }
                              return '${user.fullName} ${user.phone}'
                                  .toLowerCase()
                                  .contains(query);
                            })
                            .take(80)
                            .toList();

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          );
                        }

                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return CheckboxListTile(
                                value: _selectedUserIds.contains(user.id),
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedUserIds.add(user.id);
                                    } else {
                                      _selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                                title: Text(
                                  user.fullName,
                                  textAlign: TextAlign.right,
                                ),
                                subtitle: Text(
                                  user.phone,
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _submit, child: const Text('إرسال')),
        ],
      ),
    );
  }
}

class AdminCoursesPage extends StatefulWidget {
  final AdminSession session;

  const AdminCoursesPage({super.key, required this.session});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _service = AdminApiService();
  late Future<List<AdminCoursePart>> _partsFuture;
  String? _selectedLanguage;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _partsFuture = _service.getCourseParts(widget.session.token);
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(
      () => _partsFuture = _service.getCourseParts(widget.session.token),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  Future<void> _createCourse() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CourseNodeDialog(
        title: 'إضافة كورس',
        fieldLabel: 'اسم الكورس',
        type: 'course',
      ),
    );
    if (result == null) {
      return;
    }

    try {
      await _service.createCoursePart(widget.session.token, result);
      _refresh();
      _showMessage('تم إنشاء الكورس بنجاح.');
    } on AuthApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر إنشاء الكورس.');
    }
  }

  Future<void> _editCourse(AdminCoursePart course) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CourseNodeDialog(
        title: 'تعديل كورس',
        fieldLabel: 'اسم الكورس',
        type: 'course',
        item: course,
      ),
    );
    if (result == null) {
      return;
    }

    try {
      await _service.updateCoursePart(widget.session.token, course.id, result);
      _refresh();
      _showMessage('تم تعديل الكورس بنجاح.');
    } on AuthApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر تعديل الكورس.');
    }
  }

  Future<void> _createLevel() async {
    final language = _selectedLanguage;
    final course = _selectedCourse;
    if (language == null || course == null) {
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CourseNodeDialog(
        title: 'إضافة ليفيل',
        fieldLabel: 'اسم الليفيل',
        type: 'level',
        language: language,
        course: course,
      ),
    );
    if (result == null) {
      return;
    }
    await _createNode(result, 'تم إضافة الليفيل.');
  }

  Future<void> _createLecture(String level) async {
    final language = _selectedLanguage;
    final course = _selectedCourse;
    if (language == null || course == null) {
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CourseNodeDialog(
        title: 'إضافة درس',
        fieldLabel: 'اسم الدرس',
        type: 'lecture',
        language: language,
        course: course,
        level: level,
      ),
    );
    if (result == null) {
      return;
    }
    await _createNode(result, 'تم إضافة الدرس.');
  }

  Future<void> _createPart(String level, String lecture) async {
    final language = _selectedLanguage;
    final course = _selectedCourse;
    if (language == null || course == null) {
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CourseVideoPartDialog(
        language: language,
        course: course,
        level: level,
        lecture: lecture,
      ),
    );
    if (result == null) {
      return;
    }
    await _createNode(result, 'تم إضافة جزء الفيديو.');
  }

  Future<void> _createNode(Map<String, dynamic> result, String message) async {
    try {
      await _service.createCoursePart(widget.session.token, result);
      _refresh();
      _showMessage(message);
    } on AuthApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر تنفيذ العملية.');
    }
  }

  Future<void> _deleteNode(AdminCoursePart part) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنصر'),
        content: Text('هل تريد الحذف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteCoursePart(widget.session.token, part.id);
      _refresh();
      _showMessage('تم الحذف.');
    } on AuthApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر الحذف.');
    }
  }

  List<AdminCoursePart> _coursesFrom(List<AdminCoursePart> parts) {
    final byKey = <String, AdminCoursePart>{};
    for (final item in parts) {
      if (item.language.isEmpty || item.course.isEmpty) {
        continue;
      }
      byKey.putIfAbsent('${item.language}|${item.course}', () {
        final explicit = parts.where(
          (part) =>
              part.isCourse &&
              part.language == item.language &&
              part.course == item.course,
        );
        return explicit.isEmpty ? item : explicit.first;
      });
    }
    return byKey.values.toList()..sort((a, b) => a.course.compareTo(b.course));
  }

  List<String> _levelsFor(List<AdminCoursePart> parts) {
    final levels = parts
        .where((part) => part.level.isNotEmpty)
        .map((part) => part.level)
        .toSet()
        .toList();
    levels.sort();
    return levels;
  }

  List<String> _lecturesFor(List<AdminCoursePart> parts, String level) {
    final lectures = parts
        .where((part) => part.level == level && part.lecture.isNotEmpty)
        .map((part) => part.lecture)
        .toSet()
        .toList();
    lectures.sort();
    return lectures;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminCoursePart>>(
      future: _partsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final parts = snapshot.data ?? const <AdminCoursePart>[];
        final selectedParts = parts
            .where(
              (part) =>
                  part.language == _selectedLanguage &&
                  part.course == _selectedCourse,
            )
            .toList();
        final courses = _coursesFrom(parts);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            _PageTitle(
              title: _selectedCourse ?? 'الكورسات',
              subtitle: _selectedCourse == null
                  ? 'أضف الكورس باللغة فقط، وبعدها افتح الكارت لإضافة الليفيلات والدروس والأجزاء.'
                  : 'إدارة مستويات ودروس وأجزاء الفيديو داخل الكورس.',
              action: _ToolbarButton(
                onPressed: _selectedCourse == null
                    ? _createCourse
                    : _createLevel,
                icon: Icon(
                  _selectedCourse == null
                      ? Icons.add_rounded
                      : Icons.stacked_line_chart_rounded,
                ),
                label: _selectedCourse == null ? 'إضافة كورس' : 'إضافة ليفيل',
                filled: true,
              ),
            ),
            if (_selectedCourse != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedLanguage = null;
                    _selectedCourse = null;
                  }),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('رجوع للكورسات'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              _ErrorState(message: 'تعذر تحميل الكورسات.')
            else if (_selectedCourse == null && courses.isEmpty)
              _Panel(
                child: Text(
                  'لا توجد كورسات بعد. ابدأ بإضافة أول كورس.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else if (_selectedCourse == null)
              _CoursesGrid(
                courses: courses,
                parts: parts,
                onOpen: (course) => setState(() {
                  _selectedLanguage = course.language;
                  _selectedCourse = course.course;
                }),
                onEdit: _editCourse,
                onDelete: _deleteNode,
              )
            else
              _CourseDetailsView(
                parts: selectedParts,
                levels: _levelsFor(selectedParts),
                lecturesFor: (level) => _lecturesFor(selectedParts, level),
                onAddLecture: _createLecture,
                onAddPart: _createPart,
                onDelete: _deleteNode,
              ),
          ],
        );
      },
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  final List<AdminCoursePart> courses;
  final List<AdminCoursePart> parts;
  final ValueChanged<AdminCoursePart> onOpen;
  final ValueChanged<AdminCoursePart> onEdit;
  final ValueChanged<AdminCoursePart> onDelete;

  const _CoursesGrid({
    required this.courses,
    required this.parts,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 5 / 4,
          ),
          itemBuilder: (context, index) {
            final course = courses[index];
            final courseParts = parts
                .where(
                  (part) =>
                      part.language == course.language &&
                      part.course == course.course,
                )
                .toList();
            return _CourseCard(
              course: course,
              parts: courseParts,
              onOpen: () => onOpen(course),
              onEdit: course.isCourse ? () => onEdit(course) : null,
              onDelete: course.isCourse ? () => onDelete(course) : null,
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final AdminCoursePart course;
  final List<AdminCoursePart> parts;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CourseCard({
    required this.course,
    required this.parts,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isEnglish = course.language.contains('إنج');
    final color = isEnglish ? const Color(0xFF1D4ED8) : AppColors.orange;
    final levelsCount = parts
        .where((part) => part.level.isNotEmpty)
        .map((part) => part.level)
        .toSet()
        .length;
    final lessonsCount = parts
        .where((part) => part.lecture.isNotEmpty)
        .map((part) => part.lecture)
        .toSet()
        .length;
    final imageProvider = _courseImageProvider(course.imageDataUrl);
    final hasImage = imageProvider != null;
    return Material(
      color: hasImage ? AppColors.surface : color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: hasImage
                ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.36),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'تعديل الكورس',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'حذف الكورس',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                course.course,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                course.language,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${course.courseLevel.isEmpty ? 'مستوى غير محدد' : course.courseLevel} • $levelsCount مستويات • $lessonsCount درس',
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.priceLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDetailsView extends StatelessWidget {
  final List<AdminCoursePart> parts;
  final List<String> levels;
  final List<String> Function(String level) lecturesFor;
  final ValueChanged<String> onAddLecture;
  final void Function(String level, String lecture) onAddPart;
  final ValueChanged<AdminCoursePart> onDelete;

  const _CourseDetailsView({
    required this.parts,
    required this.levels,
    required this.lecturesFor,
    required this.onAddLecture,
    required this.onAddPart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return _Panel(
        child: Text(
          'لسه مفيش ليفيلات في الكورس. اضغط إضافة ليفيل وابدأ التنظيم.',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: levels
          .map(
            (level) => _LevelSection(
              level: level,
              lectures: lecturesFor(level),
              parts: parts,
              onAddLecture: () => onAddLecture(level),
              onAddPart: (lecture) => onAddPart(level, lecture),
              onDelete: onDelete,
            ),
          )
          .toList(),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final String level;
  final List<String> lectures;
  final List<AdminCoursePart> parts;
  final VoidCallback onAddLecture;
  final ValueChanged<String> onAddPart;
  final ValueChanged<AdminCoursePart> onDelete;

  const _LevelSection({
    required this.level,
    required this.lectures,
    required this.parts,
    required this.onAddLecture,
    required this.onAddPart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _TreeCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(
                  Icons.stacked_line_chart_rounded,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAddLecture,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة درس'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lectures.isEmpty)
              Text(
                'لا توجد دروس بعد.',
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ...lectures.map(
                (lecture) => _LectureSection(
                  lecture: lecture,
                  parts: parts
                      .where(
                        (part) =>
                            part.level == level &&
                            part.lecture == lecture &&
                            part.isPart,
                      )
                      .toList(),
                  onAddPart: () => onAddPart(lecture),
                  onDelete: onDelete,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LectureSection extends StatelessWidget {
  final String lecture;
  final List<AdminCoursePart> parts;
  final VoidCallback onAddPart;
  final ValueChanged<AdminCoursePart> onDelete;

  const _LectureSection({
    required this.lecture,
    required this.parts,
    required this.onAddPart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.play_lesson_rounded, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lecture,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: onAddPart,
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('إضافة جزء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (parts.isEmpty)
            Text(
              'لا توجد أجزاء فيديو بعد.',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...parts.map(
              (part) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            part.part,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            part.vimeoUrl,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            part.duration.isEmpty ? '00:00:00' : part.duration,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف الجزء',
                      onPressed: () => onDelete(part),
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  final Widget child;

  const _TreeCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

class _TreeTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TreeTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget action;

  const _PageTitle({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth < 460
                    ? constraints.maxWidth
                    : 460,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            action,
          ],
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool filled;

  const _ToolbarButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          );

    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: style,
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: style,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.orange, size: 21),
            ),
            Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              title,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser user;
  final VoidCallback? onEdit;
  final VoidCallback? onPassword;
  final VoidCallback? onSuspend;
  final VoidCallback? onDelete;

  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onPassword,
    required this.onSuspend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          user.fullName,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _StatusChip(isSuspended: user.isSuspended),
                        _RoleChip(label: user.roleLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _InfoText(icon: Icons.phone_rounded, text: user.phone),
                        _InfoText(
                          icon: Icons.translate_rounded,
                          text: user.language,
                        ),
                        _InfoText(icon: Icons.work_rounded, text: user.job),
                        _InfoText(
                          icon: Icons.location_on_rounded,
                          text: user.address,
                        ),
                        _InfoText(
                          icon: Icons.calendar_today_rounded,
                          text: user.createdAtLabel,
                        ),
                        _InfoText(
                          icon: Icons.person_pin_rounded,
                          text: user.createdBy,
                        ),
                      ],
                    ),
                  ),
                  if (user.enrollments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        textDirection: TextDirection.rtl,
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: user.enrollments
                            .map((enrollment) => _EnrollmentChip(enrollment))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _UserActionsMenu(
              enabled: !user.isSystemAdmin,
              isSuspended: user.isSuspended,
              onEdit: onEdit,
              onPassword: onPassword,
              onSuspend: onSuspend,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentChip extends StatelessWidget {
  final AdminUserEnrollment enrollment;

  const _EnrollmentChip(this.enrollment);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'طريقة الدفع: ${enrollment.paymentMethod}\nتاريخ الدفع: ${enrollment.paymentDate}\nالرقم: ${enrollment.paymentPhone}\nالمبلغ: ${enrollment.paidAmount}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.orangeSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.orange),
        ),
        child: Text(
          '${enrollment.courseTitle} - ${enrollment.courseLanguage}',
          style: const TextStyle(
            color: AppColors.orange,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _UserActionsMenu extends StatelessWidget {
  final bool enabled;
  final bool isSuspended;
  final VoidCallback? onEdit;
  final VoidCallback? onPassword;
  final VoidCallback? onSuspend;
  final VoidCallback? onDelete;

  const _UserActionsMenu({
    required this.enabled,
    required this.isSuspended,
    required this.onEdit,
    required this.onPassword,
    required this.onSuspend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_UserAction>(
      enabled: enabled,
      tooltip: 'إجراءات',
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case _UserAction.edit:
            onEdit?.call();
            break;
          case _UserAction.password:
            onPassword?.call();
            break;
          case _UserAction.suspend:
            onSuspend?.call();
            break;
          case _UserAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _UserAction.edit,
          child: _ActionMenuItem(icon: Icons.edit_rounded, label: 'تعديل'),
        ),
        const PopupMenuItem(
          value: _UserAction.password,
          child: _ActionMenuItem(
            icon: Icons.password_rounded,
            label: 'كلمة المرور',
          ),
        ),
        PopupMenuItem(
          value: _UserAction.suspend,
          child: _ActionMenuItem(
            icon: isSuspended ? Icons.lock_open_rounded : Icons.block_rounded,
            label: isSuspended ? 'إلغاء التعليق' : 'تعليق الدخول',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _UserAction.delete,
          child: _ActionMenuItem(icon: Icons.delete_rounded, label: 'حذف'),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: enabled ? AppColors.orange : AppColors.textMuted,
        ),
      ),
    );
  }
}

enum _UserAction { edit, password, suspend, delete }

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.orange),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isSuspended;

  const _StatusChip({required this.isSuspended});

  @override
  Widget build(BuildContext context) {
    final color = isSuspended ? Colors.redAccent : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        isSuspended ? 'معلق' : 'نشط',
        textAlign: TextAlign.right,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;

  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          text.isEmpty ? '-' : text,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _CourseNodeDialog extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String type;
  final String? language;
  final String? course;
  final String? level;
  final AdminCoursePart? item;

  const _CourseNodeDialog({
    required this.title,
    required this.fieldLabel,
    required this.type,
    this.language,
    this.course,
    this.level,
    this.item,
  });

  @override
  State<_CourseNodeDialog> createState() => _CourseNodeDialogState();
}

class _CourseNodeDialogState extends State<_CourseNodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _price = TextEditingController();

  static const _languages = ['الإنجليزية', 'الألمانية'];
  static const _courseLevels = ['مبتدئ', 'متوسط', 'متوسط مرتفع', 'محترف'];
  String? _language;
  String _courseType = 'free';
  String? _courseLevel = 'مبتدئ';
  String _imageDataUrl = '';
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _language = _languages.contains(item.language) ? item.language : null;
      _courseType = item.courseType;
      _courseLevel = _courseLevels.contains(item.courseLevel)
          ? item.courseLevel
          : 'مبتدئ';
      _imageDataUrl = item.imageDataUrl;
      _price.text = item.price;
      switch (widget.type) {
        case 'course':
          _value.text = item.course;
          break;
        case 'level':
          _value.text = item.level;
          break;
        case 'lecture':
          _value.text = item.lecture;
          break;
      }
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _price.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (_courseType == 'free') {
      return null;
    }
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    final number = num.tryParse(value!.trim());
    if (number == null || number < 0) {
      return 'اكتب سعر صحيح';
    }
    return null;
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) {
      return;
    }

    setState(() => _isPickingImage = true);
    try {
      final image = await pickCourseImageDataUrl();
      if (!mounted) {
        return;
      }
      if (image == null || image.isEmpty) {
        setState(() => _isPickingImage = false);
        return;
      }
      setState(() {
        _imageDataUrl = image;
        _isPickingImage = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = _value.text.trim();
    final data = <String, dynamic>{
      'type': widget.type,
      'language': widget.language ?? _language ?? '',
      'course': widget.course ?? '',
      'level': widget.level ?? '',
      'lecture': '',
      'part': '',
      'vimeoUrl': '',
      'courseType': widget.item?.courseType ?? 'free',
      'price': widget.item?.price ?? '',
      'courseLevel': widget.item?.courseLevel ?? 'مبتدئ',
      'imageDataUrl': widget.item?.imageDataUrl ?? '',
    };

    switch (widget.type) {
      case 'course':
        data['course'] = value;
        data['courseType'] = _courseType;
        data['price'] = _courseType == 'paid' ? _price.text.trim() : '';
        data['courseLevel'] = _courseLevel ?? 'مبتدئ';
        data['imageDataUrl'] = _imageDataUrl;
        break;
      case 'level':
        data['level'] = value;
        break;
      case 'lecture':
        data['lecture'] = value;
        break;
    }

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double dialogWidth = screenSize.width > 700
        ? 650.0
        : (screenSize.width > 500 ? screenSize.width - 40 : 450.0);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: dialogWidth,
        height: screenSize.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.type == 'course')
                            _DialogDropdown(
                              value: _language,
                              label: 'اللغة',
                              icon: Icons.translate_rounded,
                              items: _languages,
                              onChanged: (value) =>
                                  setState(() => _language = value),
                              validator: _required,
                            ),
                          _DialogField(
                            controller: _value,
                            label: widget.fieldLabel,
                            validator: _required,
                          ),
                          if (widget.type == 'course') ...[
                            _CourseImagePickerField(
                              imageDataUrl: _imageDataUrl,
                              isLoading: _isPickingImage,
                              onPick: _pickImage,
                              onClear: () => setState(() => _imageDataUrl = ''),
                            ),
                            _DialogDropdown(
                              value: _courseLevel,
                              label: 'مستوى الكورس',
                              icon: Icons.signal_cellular_alt_rounded,
                              items: _courseLevels,
                              onChanged: (value) => setState(() {
                                _courseLevel = value;
                              }),
                              validator: _required,
                            ),
                            _DialogDropdown(
                              value: _courseType,
                              label: 'نوع الكورس',
                              icon: Icons.workspace_premium_rounded,
                              items: const ['free', 'paid'],
                              itemLabels: const {
                                'free': 'Free',
                                'paid': 'Paid',
                              },
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _courseType = value);
                              },
                              validator: _required,
                            ),
                            if (_courseType == 'paid')
                              _DialogField(
                                controller: _price,
                                label: 'السعر',
                                validator: _validatePrice,
                                keyboardType: TextInputType.number,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FilledButton(onPressed: _submit, child: const Text('حفظ')),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseVideoPartDialog extends StatefulWidget {
  final String language;
  final String course;
  final String level;
  final String lecture;

  const _CourseVideoPartDialog({
    required this.language,
    required this.course,
    required this.level,
    required this.lecture,
  });

  @override
  State<_CourseVideoPartDialog> createState() => _CourseVideoPartDialogState();
}

class _CourseImagePickerField extends StatelessWidget {
  final String imageDataUrl;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _CourseImagePickerField({
    required this.imageDataUrl,
    this.isLoading = false,
    required this.onPick,
    required this.onClear,
  });

  Widget _buildPreview() {
    if (imageDataUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: 5 / 4,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.image_rounded,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
      );
    }

    if (imageDataUrl.startsWith('data:')) {
      try {
        final uriData = Uri.parse(imageDataUrl).data;
        if (uriData == null) {
          throw StateError('Invalid data URI');
        }
        final bytes = uriData.contentAsBytes();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 5 / 4,
            child: Image.memory(
              bytes,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {
        return _buildInvalidPreview();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 5 / 4,
        child: Image.network(
          imageDataUrl,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInvalidPreview(),
        ),
      ),
    );
  }

  Widget _buildInvalidPreview() {
    return AspectRatio(
      aspectRatio: 5 / 4,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'تعذر عرض الصورة',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              textDirection: TextDirection.rtl,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onPick,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: Text(
                    isLoading
                        ? 'جاري اختيار الصورة...'
                        : imageDataUrl.isNotEmpty
                        ? 'تغيير الصورة'
                        : 'رفع صورة الكورس',
                  ),
                ),
                if (imageDataUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('حذف الصورة'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseVideoPartDialogState extends State<_CourseVideoPartDialog> {
  final _formKey = GlobalKey<FormState>();
  final _part = TextEditingController();
  final _vimeoUrl = TextEditingController();
  final _duration = TextEditingController(text: '00:00:00');

  @override
  void dispose() {
    _part.dispose();
    _vimeoUrl.dispose();
    _duration.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب';
    }
    return null;
  }

  String? _validateVimeo(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    final url = value!.trim();
    if (!RegExp(
      r'^https?:\/\/(www\.)?(vimeo\.com|player\.vimeo\.com)\/',
    ).hasMatch(url)) {
      return 'اكتب لينك Vimeo صحيح';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (!RegExp(r'^\d{2}:[0-5]\d:[0-5]\d$').hasMatch(value!.trim())) {
      return 'اكتب الوقت بصيغة hh:mm:ss';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'type': 'part',
      'language': widget.language,
      'course': widget.course,
      'level': widget.level,
      'lecture': widget.lecture,
      'part': _part.text.trim(),
      'vimeoUrl': _vimeoUrl.text.trim(),
      'duration': _duration.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة جزء فيديو', textAlign: TextAlign.right),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  controller: _part,
                  label: 'اسم الجزء',
                  validator: _required,
                ),
                _DialogField(
                  controller: _vimeoUrl,
                  label: 'لينك Vimeo',
                  validator: _validateVimeo,
                ),
                _DialogField(
                  controller: _duration,
                  label: 'وقت الجزء hh:mm:ss',
                  validator: _validateDuration,
                  keyboardType: TextInputType.datetime,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final AdminUser? user;

  const _UserFormDialog({this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _referralReason;
  late String? _address;
  late String? _job;
  late String? _language;
  late String? _learningReason;
  late String _role;

  static const _egyptGovernorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'الشرقية',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
  ];

  static const _languages = ['الإنجليزية', 'الألمانية'];

  static const _jobs = [
    'طالب',
    'معلم',
    'طبيب',
    'صيدلي',
    'مهندس',
    'محاسب',
    'محامي',
    'مصمم جرافيك',
    'مبرمج',
    'مصمم واجهات',
    'مسوق رقمي',
    'مندوب مبيعات',
    'خدمة عملاء',
    'موظف إداري',
    'مدير مشروع',
    'مدير موارد بشرية',
    'صاحب عمل',
    'رائد أعمال',
    'مترجم',
    'كاتب محتوى',
    'صحفي',
    'باحث',
    'عامل حر',
    'فني',
    'سائق',
    'ممرض',
    'مدرب',
    'مصمم أزياء',
    'ربة منزل',
    'أخرى',
  ];

  static const _learningReasons = [
    'السفر',
    'الدراسة',
    'الشغل',
    'تعليم الأولاد',
    'سبب أخر',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _password = TextEditingController();
    _referralReason = TextEditingController(text: user?.referralReason ?? '');
    _address = _normalizeChoice(user?.address, _egyptGovernorates);
    _job = _normalizeChoice(user?.job, _jobs);
    _language = _normalizeChoice(user?.language, _languages);
    _learningReason = _normalizeChoice(user?.learningReason, _learningReasons);
    _role = user?.role ?? 'student';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _referralReason.dispose();
    super.dispose();
  }

  String? _normalizeChoice(String? value, List<String> choices) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return choices.contains(value) ? value : null;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final Map<String, dynamic> data = {
      'fullName': _name.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address ?? '',
      'job': _job ?? '',
      'language': _language ?? '',
      'learningReason': _learningReason ?? '',
      'referralReason': _referralReason.text.trim(),
      'role': _role,
    };
    if (_password.text.isNotEmpty) {
      data['password'] = _password.text;
    }
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    return AlertDialog(
      title: Text(isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'نوع الصلاحية',
                    prefixIcon: Icon(Icons.admin_panel_settings_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('طالب')),
                    DropdownMenuItem(value: 'admin', child: Text('أدمن')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _role = value);
                  },
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _name,
                  label: 'الاسم',
                  validator: _required,
                ),
                _DialogField(
                  controller: _phone,
                  label: 'رقم الهاتف',
                  validator: _required,
                ),
                _DialogField(
                  controller: _password,
                  label: isEditing ? 'كلمة مرور جديدة اختيارية' : 'كلمة المرور',
                  validator: isEditing ? null : _required,
                  obscureText: true,
                ),
                _DialogDropdown(
                  value: _address,
                  label: 'المحافظة',
                  icon: Icons.location_on_rounded,
                  items: _egyptGovernorates,
                  onChanged: (value) => setState(() => _address = value),
                  validator: _required,
                ),
                _DialogDropdown(
                  value: _job,
                  label: 'الوظيفة',
                  icon: Icons.work_rounded,
                  items: _jobs,
                  onChanged: (value) => setState(() => _job = value),
                  validator: _required,
                ),
                _DialogDropdown(
                  value: _language,
                  label: 'اللغة',
                  icon: Icons.translate_rounded,
                  items: _languages,
                  onChanged: (value) => setState(() => _language = value),
                  validator: _required,
                ),
                _DialogDropdown(
                  value: _learningReason,
                  label: 'سبب التعلم',
                  icon: Icons.flag_rounded,
                  items: _learningReasons,
                  onChanged: (value) {
                    setState(() => _learningReason = value);
                  },
                  validator: _required,
                ),
                _DialogField(
                  controller: _referralReason,
                  label: 'سبب اختيار المنصة',
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _DialogField({
    required this.controller,
    required this.label,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        textAlign: TextAlign.right,
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
      ),
    );
  }
}

class _DialogDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final Map<String, String> itemLabels;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _DialogDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.itemLabels = const {},
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        alignment: AlignmentDirectional.centerEnd,
        validator: validator,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    itemLabels[item] ?? item,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.length < 6) {
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة المرور'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'كلمة المرور الجديدة',
          helperText: '6 أحرف على الأقل',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('تغيير')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Text(
        'لا يوجد مستخدمين مطابقين للبحث.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}

class AdminBooksPage extends StatefulWidget {
  final AdminSession session;

  const AdminBooksPage({super.key, required this.session});

  @override
  State<AdminBooksPage> createState() => _AdminBooksPageState();
}

class _AdminBooksPageState extends State<AdminBooksPage> {
  final _service = AdminApiService();
  late Future<List<AdminBook>> _booksFuture;
  late Future<List<AdminCoursePart>> _coursePartsFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _service.getBooks(widget.session.token);
    _coursePartsFuture = _service.getCourseParts(widget.session.token);
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(() {
      _booksFuture = _service.getBooks(widget.session.token);
      _coursePartsFuture = _service.getCourseParts(widget.session.token);
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  Future<void> _createBook() async {
    final courseParts = await _coursePartsFuture;
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _BookDialog(title: 'إضافة كتاب', availableCourseParts: courseParts),
    );
    if (result == null) {
      return;
    }

    try {
      await _service.createBook(
        widget.session.token,
        AdminBook(
          id: '',
          title: result['title'],
          subtitle: result['subtitle'],
          course: result['course'],
          language: result['language'],
          isFree: result['isFree'],
          url: result['url'],
          createdBy: widget.session.name,
        ),
      );
      _refresh();
      _showMessage('تم إضافة الكتاب.');
    } catch (e) {
      _showMessage('تعذر إضافة الكتاب.');
    }
  }

  Future<void> _editBook(AdminBook book) async {
    final courseParts = await _coursePartsFuture;
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _BookDialog(
        title: 'تعديل كتاب',
        initialTitle: book.title,
        initialSubtitle: book.subtitle,
        initialCourse: book.course,
        initialLanguage: book.language,
        initialIsFree: book.isFree,
        initialUrl: book.url,
        availableCourseParts: courseParts,
      ),
    );
    if (result == null) {
      return;
    }

    try {
      await _service.updateBook(widget.session.token, book.id, result);
      _refresh();
      _showMessage('تم تعديل الكتاب.');
    } catch (e) {
      _showMessage('تعذر تعديل الكتاب.');
    }
  }

  Future<void> _deleteBook(AdminBook book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف كتاب'),
        content: Text('هل أنت متأكد من حذف "${book.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteBook(widget.session.token, book.id);
      _refresh();
      _showMessage('تم حذف الكتاب.');
    } catch (e) {
      _showMessage('تعذر حذف الكتاب.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _createBook,
          tooltip: 'إضافة كتاب',
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<List<AdminBook>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(message: 'تعذر تحميل الكتب.');
            }

            final books = snapshot.data ?? [];
            if (books.isEmpty) {
              return _Panel(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مفيش كتب بعد. اضغط + لإضافة كتاب جديد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(book.title),
                    subtitle: Text(
                      '${book.course.isNotEmpty ? 'الكورس: ${book.course} • ' : ''}${book.language.isNotEmpty ? 'اللغة: ${book.language} • ' : ''}${book.isFree ? 'مجاني' : 'مع شراء الكورس'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'معاينة',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookViewerScreen(
                                  book: Book(
                                    id: book.id,
                                    title: book.title,
                                    subtitle: book.subtitle,
                                    course: book.course,
                                    language: book.language,
                                    isFree: book.isFree,
                                    url: book.url,
                                    createdBy: book.createdBy,
                                    createdAt: DateTime.now().toIso8601String(),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                        ),
                        IconButton(
                          tooltip: 'تعديل',
                          onPressed: () => _editBook(book),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => _deleteBook(book),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
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

class _BookDialog extends StatefulWidget {
  final String title;
  final String? initialTitle;
  final String? initialSubtitle;
  final String? initialCourse;
  final String? initialLanguage;
  final bool? initialIsFree;
  final String? initialUrl;
  final List<AdminCoursePart> availableCourseParts;

  const _BookDialog({
    required this.title,
    this.initialTitle,
    this.initialSubtitle,
    this.initialCourse,
    this.initialLanguage,
    this.initialIsFree,
    this.initialUrl,
    required this.availableCourseParts,
  });

  @override
  State<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends State<_BookDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _urlController;
  late String _selectedCourse;
  late String _selectedLanguage;
  late String _accessMode;
  late final List<String> _courseOptions;
  late List<String> _languageOptions;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _subtitleController = TextEditingController(text: widget.initialSubtitle);
    _urlController = TextEditingController(text: widget.initialUrl);
    _accessMode = widget.initialIsFree == false ? 'purchase' : 'free';

    _courseOptions =
        widget.availableCourseParts
            .map((part) => part.course)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    _selectedCourse = widget.initialCourse?.isNotEmpty == true
        ? widget.initialCourse!
        : (_courseOptions.isNotEmpty ? _courseOptions.first : '');

    if (_selectedCourse.isNotEmpty &&
        !_courseOptions.contains(_selectedCourse)) {
      _courseOptions.insert(0, _selectedCourse);
    }

    _languageOptions =
        widget.availableCourseParts
            .where(
              (part) =>
                  _selectedCourse.isEmpty || part.course == _selectedCourse,
            )
            .map((part) => part.language)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    _selectedLanguage = widget.initialLanguage?.isNotEmpty == true
        ? widget.initialLanguage!
        : (_languageOptions.isNotEmpty ? _languageOptions.first : '');

    if (_selectedLanguage.isNotEmpty &&
        !_languageOptions.contains(_selectedLanguage)) {
      _languageOptions.insert(0, _selectedLanguage);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'اسم الكتاب'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCourse.isEmpty ? null : _selectedCourse,
              decoration: const InputDecoration(
                labelText: 'الكورس الخاص بالكتاب',
              ),
              items: _courseOptions
                  .map(
                    (course) =>
                        DropdownMenuItem(value: course, child: Text(course)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedCourse = value;
                  _languageOptions =
                      widget.availableCourseParts
                          .where((part) => part.course == value)
                          .map((part) => part.language)
                          .where((language) => language.trim().isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();
                  if (!_languageOptions.contains(_selectedLanguage)) {
                    _selectedLanguage = _languageOptions.isNotEmpty
                        ? _languageOptions.first
                        : '';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage.isEmpty
                  ? null
                  : _selectedLanguage,
              decoration: const InputDecoration(labelText: 'اللغة'),
              items: _languageOptions
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(language),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accessMode,
              decoration: const InputDecoration(labelText: 'وضعية الوصول'),
              items: const [
                DropdownMenuItem(value: 'free', child: Text('مفتوح مجاني')),
                DropdownMenuItem(
                  value: 'purchase',
                  child: Text('يتطلب شراء الكورس'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _accessMode = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'الرابط (Drive)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'title': _titleController.text.trim(),
            'subtitle': _subtitleController.text.trim(),
            'course': _selectedCourse,
            'language': _selectedLanguage,
            'isFree': _accessMode == 'free',
            'url': _urlController.text.trim(),
          }),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
