import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class HeaderSection extends StatelessWidget {
  final String? userName;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationsTap;

  const HeaderSection({
    super.key,
    this.userName,
    this.unreadNotificationsCount = 0,
    this.onNotificationsTap,
  });

  String get _displayName {
    final trimmedName = userName?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return 'بك';
    }

    return trimmedName;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onNotificationsTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.orange,
                    ),
                    if (unreadNotificationsCount > 0)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unreadNotificationsCount > 9
                                ? '9+'
                                : unreadNotificationsCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أهلاً $_displayName',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'كمّل رحلتك في تعلم اللغات مع Lingova',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
