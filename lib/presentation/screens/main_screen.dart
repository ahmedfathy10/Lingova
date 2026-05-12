import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/push_notification_service.dart';
import 'courses_page.dart';
import 'exams_page.dart';
import 'home_screen.dart';
import 'library_page.dart';
import 'more_page.dart';

class MainScreen extends StatefulWidget {
  final AuthUser? user;
  final String? userName;

  const MainScreen({super.key, this.user, this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _authApiService = AuthApiService();
  int currentIndex = 0;
  CourseFilter courseFilter = CourseFilter.all;
  AuthUser? _currentUser;
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _sessionId =
        '${widget.user?.id ?? 'guest'}-${DateTime.now().microsecondsSinceEpoch}';
    PushNotificationService.instance.bindUser(_currentUser);
    _trackActivity('app_open', 'فتح التطبيق');
    _refreshUser();
  }

  Future<void> _trackActivity(
    String action,
    String label, {
    String details = '',
  }) async {
    final user = _currentUser;
    if (user == null || user.id.isEmpty) {
      return;
    }
    try {
      await _authApiService.recordActivity(
        userId: user.id,
        sessionId: _sessionId,
        action: action,
        label: label,
        details: details,
      );
    } catch (_) {}
  }

  Future<void> _refreshUser() async {
    final user = _currentUser;
    if (user == null || user.id.isEmpty) {
      return;
    }
    try {
      final freshUser = await _authApiService.getUser(user.id);
      if (!mounted) return;
      setState(() => _currentUser = freshUser);
      PushNotificationService.instance.bindUser(freshUser);
    } catch (_) {}
  }

  void _openCourses(CourseFilter filter) {
    setState(() {
      courseFilter = filter;
      currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        user: _currentUser,
        userName: _currentUser?.fullName ?? widget.userName,
        onViewCourses: _openCourses,
      ),
      CoursesPage(initialFilter: courseFilter, user: _currentUser),
      const LibraryPage(),
      ExamsPage(user: _currentUser),
      const MorePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 58,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(6, 3, 6, 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .20),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                isSelected: currentIndex == 0,
                onTap: () => _selectTab(0),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'الكورسات',
                isSelected: currentIndex == 1,
                onTap: () => _selectTab(1),
              ),
              _NavItem(
                icon: Icons.library_books_rounded,
                label: 'المكتبة',
                isSelected: currentIndex == 2,
                onTap: () => _selectTab(2),
              ),
              _NavItem(
                icon: Icons.quiz_rounded,
                label: 'الامتحانات',
                isSelected: currentIndex == 3,
                onTap: () => _selectTab(3),
              ),
              _NavItem(
                icon: Icons.more_horiz_rounded,
                label: 'المزيد',
                isSelected: currentIndex == 4,
                onTap: () => _selectTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (index == 0 || index == 1) {
      _refreshUser();
    }
    setState(() {
      if (index == 1) {
        courseFilter = CourseFilter.all;
      }
      currentIndex = index;
    });
    const labels = ['الرئيسية', 'الكورسات', 'المكتبة', 'الامتحانات', 'المزيد'];
    _trackActivity('navigate', 'تنقل داخل التطبيق', details: labels[index]);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.orange : Colors.white54;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.only(top: 1),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 27),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 40 : 28,
                  height: isSelected ? 40 : 28,
                  transform: Matrix4.translationValues(
                    0,
                    isSelected ? -18 : 0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(color: AppColors.surface, width: 4)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: .35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: isSelected ? 22 : 20,
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
