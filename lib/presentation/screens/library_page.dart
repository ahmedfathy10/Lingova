import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = [
      (
        title: 'English A1 Vocabulary',
        subtitle: 'ملف PDF لأهم كلمات المستوى الأول',
        icon: Icons.picture_as_pdf_rounded,
        tag: 'PDF',
      ),
      (
        title: 'German A1 Listening',
        subtitle: 'ملفات صوتية للتدريب على النطق والاستماع',
        icon: Icons.headphones_rounded,
        tag: 'Audio',
      ),
      (
        title: 'Grammar Cheat Sheet',
        subtitle: 'ملخص سريع للقواعد الأكثر استخداماً',
        icon: Icons.edit_note_rounded,
        tag: 'Notes',
      ),
      (
        title: 'Conversation Practice',
        subtitle: 'مواقف يومية للتدريب على المحادثة',
        icon: Icons.record_voice_over_rounded,
        tag: 'Practice',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'المكتبة',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'مواد مساعدة للمذاكرة والمراجعة بين الدروس.',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            SizedBox(height: 20),
            ...resources.map(
              (resource) => _LibraryTile(
                title: resource.title,
                subtitle: resource.subtitle,
                icon: resource.icon,
                tag: resource.tag,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;

  const _LibraryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
  });

  void _open(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('سيتم فتح $title قريباً')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppColors.orange),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  tag,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
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
