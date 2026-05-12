import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('الإعدادات')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                'المظهر',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text(
                'اختار شكل التطبيق المناسب لك.',
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textMuted),
              ),
              SizedBox(height: 20),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppSettings.themeMode,
                builder: (context, themeMode, _) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeOption(
                            title: 'دارك',
                            subtitle: 'خلفية هادئة ومريحة',
                            icon: Icons.dark_mode_rounded,
                            selected: themeMode == ThemeMode.dark,
                            onTap: () =>
                                AppSettings.setThemeMode(ThemeMode.dark),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _ModeOption(
                            title: 'لايت',
                            subtitle: 'تصميم فاتح وواضح',
                            icon: Icons.light_mode_rounded,
                            selected: themeMode == ThemeMode.light,
                            onTap: () =>
                                AppSettings.setThemeMode(ThemeMode.light),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orangeSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.orange),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.orange,
                      size: 20,
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
