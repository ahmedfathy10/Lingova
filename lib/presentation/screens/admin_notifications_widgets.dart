part of 'admin_shell_screen.dart';

class _PremiumGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color accent;
  final bool highlighted;

  const _PremiumGlass({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.accent = Colors.white,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceTop = highlighted ? AppColors.surfaceHigh : AppColors.surface;
    final surfaceBottom = highlighted
        ? AppColors.surface
        : AppColors.surfaceHigh;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                surfaceTop.withValues(alpha: highlighted ? .98 : .94),
                surfaceBottom.withValues(alpha: highlighted ? .94 : .90),
              ],
            ),
            border: Border.all(
              color: highlighted
                  ? accent.withValues(alpha: .42)
                  : AppColors.border.withValues(alpha: .90),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              if (highlighted)
                BoxShadow(
                  color: accent.withValues(alpha: .10),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.right,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationHero extends StatelessWidget {
  final bool isSending;
  final bool isLoading;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  const _NotificationHero({
    required this.isSending,
    required this.isLoading,
    required this.onCreate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              textDirection: TextDirection.rtl,
              children: const [
                Text(
                  'الإشعارات',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'أرسل تنبيهات الطلاب عبر Firebase واحفظ نسخة منها داخل التطبيق.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Color(0xFFB7C0CE),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          textDirection: TextDirection.rtl,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: .32),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: isSending ? null : onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  isSending ? 'جاري الإرسال...' : 'إرسال إشعار',
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: isLoading ? null : onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFB15A),
                side: BorderSide(
                  color: AppColors.orange.withValues(alpha: .28),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white.withValues(alpha: .035),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تحديث', textAlign: TextAlign.right),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationStatCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlighted;

  const _NotificationStatCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _PremiumGlass(
        radius: 16,
        accent: color,
        highlighted: highlighted,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlighted
                          ? const Color(0xFFFFB15A)
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: highlighted ? AppColors.orange : Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF909CAF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: .25)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 23),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationControls extends StatelessWidget {
  final String query;
  final String typeFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;

  const _NotificationControls({
    required this.query,
    required this.typeFilter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final search = SizedBox(
          width: compact ? constraints.maxWidth : 340,
          child: _PremiumGlass(
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                onChanged: onQueryChanged,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'ابحث في الإشعارات...',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: TextStyle(color: Color(0xFF7F8A9C)),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFFA8B0BD),
                  ),
                ),
              ),
            ),
          ),
        );
        final filter = SizedBox(
          width: compact ? constraints.maxWidth : 150,
          child: _PremiumGlass(
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: typeFilter,
                dropdownColor: AppColors.surfaceHigh,
                iconEnabledColor: const Color(0xFFA8B0BD),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                onChanged: (value) {
                  if (value != null) onFilterChanged(value);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('تصفية', textAlign: TextAlign.right),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'general',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('عام', textAlign: TextAlign.right),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'course',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('كورس', textAlign: TextAlign.right),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'lesson',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('درس', textAlign: TextAlign.right),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'exam',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('اختبار', textAlign: TextAlign.right),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'payment',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('دفع', textAlign: TextAlign.right),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (compact) {
          return Wrap(
            alignment: WrapAlignment.end,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [filter, search],
          );
        }

        return Row(
          textDirection: TextDirection.rtl,
          children: [search, const Spacer(), filter],
        );
      },
    );
  }
}

class _AdminNotificationCard extends StatefulWidget {
  final AdminAppNotification notification;
  final VoidCallback onDelete;
  final String token;

  const _AdminNotificationCard({
    required this.notification,
    required this.onDelete,
    required this.token,
  });

  @override
  State<_AdminNotificationCard> createState() => _AdminNotificationCardState();
}

class _AdminNotificationCardState extends State<_AdminNotificationCard> {
  final AdminApiService _service = AdminApiService();
  bool _loadingReaders = false;
  List<Map<String, dynamic>> _readers = [];

  @override
  void initState() {
    super.initState();
    _fetchReaders();
  }

  Future<void> _fetchReaders() async {
    setState(() => _loadingReaders = true);
    try {
      final readers = await _service.getNotificationReaders(
        widget.token,
        widget.notification.id,
      );
      if (!mounted) return;
      setState(() {
        _readers = readers
            .map(
              (reader) => {
                'id': reader.id,
                'fullName': reader.fullName,
                'phone': reader.phone,
                'readAt': reader.readAt,
              },
            )
            .toList();
      });
    } catch (_) {
      // Keep the card usable when reader analytics are unavailable.
    } finally {
      if (mounted) setState(() => _loadingReaders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _typeColor(widget.notification.type);
    final date = DateTime.tryParse(widget.notification.createdAt)?.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _PremiumGlass(
        radius: 16,
        accent: accent,
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final content = compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _notificationInfo(accent),
                      const SizedBox(height: 18),
                      _metaGroup(date),
                      const SizedBox(height: 18),
                      _readerGroup(accent),
                      const SizedBox(height: 14),
                      _deleteButton(),
                    ],
                  )
                : Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: _notificationInfo(accent)),
                      const _VerticalDividerLite(),
                      SizedBox(width: 185, child: _metaGroup(date)),
                      const _VerticalDividerLite(),
                      SizedBox(width: 220, child: _readerGroup(accent)),
                      const _VerticalDividerLite(),
                      SizedBox(width: 52, child: _deleteButton()),
                    ],
                  );

            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 0 : 132),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 16,
                  compact ? 16 : 14,
                  compact ? 16 : 20,
                  compact ? 16 : 14,
                ),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _notificationInfo(Color accent) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: TextDirection.rtl,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _NotificationBadge(
              label: _typeLabel(widget.notification.type),
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.notification.title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.notification.body,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC5CCD8),
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.groups_rounded, size: 16, color: accent),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _targetLabel(widget.notification),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaGroup(DateTime? date) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _NotificationDateTimeBlock(
          icon: Icons.schedule_rounded,
          title: _formatTime(date),
          subtitle: 'وقت الإرسال',
        ),
        _NotificationDateTimeBlock(
          icon: Icons.calendar_today_rounded,
          title: _formatDate(date),
          subtitle: _formatWeekday(date),
        ),
      ],
    );
  }

  Widget _readerGroup(Color accent) {
    if (_loadingReaders) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.orange,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'القراء (${_readers.length})',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.person_rounded, size: 16, color: accent),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_readers.length > 5)
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2332),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: Text(
                  '+${_readers.length - 5}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (_readers.length > 5) const SizedBox(width: 6),
            _ReaderAvatarStack(readers: _readers.take(5).toList()),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 184,
            height: 33,
            child: OutlinedButton(
              onPressed: _readers.isEmpty ? null : _showReadersDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF7A8495),
                side: BorderSide(color: Colors.white.withValues(alpha: .15)),
                backgroundColor: Colors.white.withValues(alpha: .035),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'عرض جميع القراء',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteButton() {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'حذف الإشعار',
            onPressed: widget.onDelete,
            style: IconButton.styleFrom(
              fixedSize: const Size(42, 42),
              backgroundColor: Colors.redAccent.withValues(alpha: .10),
              foregroundColor: const Color(0xFFFF4D57),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: .30)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
          ),
          const SizedBox(height: 10),
          Icon(
            Icons.more_vert_rounded,
            color: Colors.white.withValues(alpha: .62),
          ),
        ],
      ),
    );
  }

  Future<void> _showReadersDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0C1420),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'قراء الإشعار',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 420,
            child: _readers.isEmpty
                ? const Text(
                    'لا توجد قراءات بعد.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Color(0xFFAAB4C4)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _readers.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: Colors.white.withValues(alpha: .08)),
                    itemBuilder: (context, index) {
                      final reader = _readers[index];
                      final name = _readerName(reader);
                      final subtitle =
                          reader['email']?.toString() ??
                          reader['phone']?.toString() ??
                          reader['mobile']?.toString() ??
                          reader['id']?.toString() ??
                          '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _ReaderAvatar(reader: reader, size: 38),
                        title: Text(
                          name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Text(
                                subtitle,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF8F9AAD),
                                ),
                              ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق', textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(AdminAppNotification notification) {
    return 'المستهدف: الطلاب';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'course':
        return 'كورس';
      case 'lesson':
        return 'درس';
      case 'exam':
        return 'اختبار';
      case 'payment':
        return 'دفع';
      default:
        return 'عام';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'course':
        return const Color(0xFF9B5CFF);
      case 'lesson':
        return const Color(0xFF38BDF8);
      case 'exam':
        return const Color(0xFF3ED47E);
      case 'payment':
        return const Color(0xFFF5B342);
      default:
        return AppColors.orange;
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return widget.notification.createdAt.isEmpty
          ? 'غير متاح'
          : widget.notification.createdAt;
    }
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatWeekday(DateTime? date) {
    if (date == null) return 'وقت الإرسال';
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[date.weekday - 1];
  }
}

class _NotificationBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _NotificationBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationDateTimeBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _NotificationDateTimeBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Icon(icon, color: const Color(0xFFAEB7C6), size: 20),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFF8C96A8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDividerLite extends StatelessWidget {
  const _VerticalDividerLite();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 88,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: Colors.white.withValues(alpha: .10),
    );
  }
}

class _ReaderAvatarStack extends StatelessWidget {
  final List<Map<String, dynamic>> readers;

  const _ReaderAvatarStack({required this.readers});

  @override
  Widget build(BuildContext context) {
    if (readers.isEmpty) {
      return Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: const Icon(
          Icons.person_off_rounded,
          size: 17,
          color: Color(0xFF8C96A8),
        ),
      );
    }

    return SizedBox(
      width: 38.0 + ((readers.length - 1) * 24),
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < readers.length; index++)
            Positioned(
              right: index * 24.0,
              top: 1,
              child: _ReaderAvatar(reader: readers[index], size: 38),
            ),
        ],
      ),
    );
  }
}

class _ReaderAvatar extends StatelessWidget {
  final Map<String, dynamic> reader;
  final double size;

  const _ReaderAvatar({required this.reader, required this.size});

  @override
  Widget build(BuildContext context) {
    final avatar =
        reader['avatarUrl']?.toString() ?? reader['photoUrl']?.toString() ?? '';
    final name = _readerName(reader);
    final colors = _avatarColors(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0A111D), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: avatar.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * .34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
            : Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                  ),
                  child: Center(
                    child: Text(
                      _initials(name),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * .34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _NotificationPagination({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : page * pageSize + 1;
    final end = (start + pageSize - 1).clamp(0, totalItems);
    final visiblePages = <int>{
      0,
      totalPages - 1,
      page - 1,
      page,
      page + 1,
    }.where((value) => value >= 0 && value < totalPages).toList()..sort();

    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 16,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'في الصفحة',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            _PremiumGlass(
              radius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  dropdownColor: AppColors.surfaceHigh,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  iconEnabledColor: const Color(0xFFA8B0BD),
                  alignment: AlignmentDirectional.centerEnd,
                  onChanged: (value) {
                    if (value != null) onPageSizeChanged(value);
                  },
                  items: const [10, 20, 50]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('$value', textAlign: TextAlign.right),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        Text(
          'عرض $start - $end من $totalItems إشعار',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .70),
            fontSize: 13,
          ),
        ),
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PageIconButton(
              icon: Icons.chevron_right_rounded,
              enabled: page > 0,
              onPressed: () => onPageChanged(page - 1),
            ),
            const SizedBox(width: 7),
            ...visiblePages.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _PageNumberButton(
                  label: '${item + 1}',
                  active: item == page,
                  onPressed: () => onPageChanged(item),
                ),
              ),
            ),
            const SizedBox(width: 7),
            _PageIconButton(
              icon: Icons.chevron_left_rounded,
              enabled: page < totalPages - 1,
              onPressed: () => onPageChanged(page + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PageIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        fixedSize: const Size(38, 38),
        foregroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFF5E6878),
        backgroundColor: Colors.white.withValues(alpha: .045),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.white.withValues(alpha: .10)),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _PageNumberButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.white : const Color(0xFFB3BDCA),
          backgroundColor: active
              ? AppColors.orange
              : Colors.white.withValues(alpha: .045),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(
            color: active
                ? AppColors.orange
                : Colors.white.withValues(alpha: .10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            label,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

String _readerName(Map<String, dynamic> reader) {
  return reader['fullName']?.toString() ??
      reader['name']?.toString() ??
      reader['displayName']?.toString() ??
      reader['email']?.toString() ??
      reader['phone']?.toString() ??
      reader['id']?.toString() ??
      'طالب';
}

String _initials(String name) {
  final cleaned = name.trim();
  if (cleaned.isEmpty) return '؟';
  final parts = cleaned
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length == 1) return _firstTextCharacter(parts.first).toUpperCase();
  return '${_firstTextCharacter(parts.first)}${_firstTextCharacter(parts.last)}'
      .toUpperCase();
}

String _firstTextCharacter(String value) {
  if (value.isEmpty) return '';
  final runes = value.runes;
  return String.fromCharCode(runes.first);
}

List<Color> _avatarColors(String seed) {
  final palettes = const [
    [Color(0xFF22C55E), Color(0xFF14B8A6)],
    [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    [Color(0xFFF97316), Color(0xFFEF4444)],
    [Color(0xFF06B6D4), Color(0xFF2563EB)],
    [Color(0xFFA855F7), Color(0xFFEC4899)],
  ];
  return palettes[seed.hashCode.abs() % palettes.length];
}
