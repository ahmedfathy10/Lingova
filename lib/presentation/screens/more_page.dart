import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../domain/entities/book.dart';
import 'book_viewer_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openFeature(BuildContext context, String title, IconData icon) {
    if (title == 'الإعدادات') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MoreFeatureScreen(title: title, icon: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <({String title, IconData icon})>[
      (title: 'الكتب الإلكترونية', icon: Icons.picture_as_pdf_rounded),
      (title: 'الملفات الصوتية', icon: Icons.headphones_rounded),
      (title: 'الشهادات', icon: Icons.workspace_premium_rounded),
      (title: 'تواصل معنا', icon: Icons.support_agent_rounded),
      (title: 'الإعدادات', icon: Icons.settings_rounded),
      (title: 'تسجيل خروج', icon: Icons.logout_rounded),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'المزيد',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'إدارة محتواك وحسابك وخدمات Lingova.',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted),
            ),
            SizedBox(height: 20),
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLogout = entry.key == items.length - 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isLogout
                        ? () => _logout(context)
                        : () => _openFeature(context, item.title, item.icon),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, color: AppColors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MoreFeatureScreen extends StatefulWidget {
  final String title;
  final IconData icon;

  const _MoreFeatureScreen({required this.title, required this.icon});

  @override
  State<_MoreFeatureScreen> createState() => _MoreFeatureScreenState();
}

class _MoreFeatureScreenState extends State<_MoreFeatureScreen> {
  List<({String title, String subtitle, IconData icon})> get _items {
    return switch (widget.title) {
      'الكتب الإلكترونية' => const [
        (
          title: 'كتاب English A1',
          subtitle: 'ملخص الدروس والكلمات الأساسية',
          icon: Icons.picture_as_pdf_rounded,
        ),
        (
          title: 'كتاب German A1',
          subtitle: 'تأسيس قواعد ومفردات المستوى الأول',
          icon: Icons.picture_as_pdf_rounded,
        ),
      ],
      'الملفات الصوتية' => const [
        (
          title: 'نطق الحروف الإنجليزية',
          subtitle: 'تدريب صوتي قصير للمبتدئين',
          icon: Icons.headphones_rounded,
        ),
        (
          title: 'German Listening A1',
          subtitle: 'محادثات يومية بسرعة مناسبة',
          icon: Icons.headphones_rounded,
        ),
      ],
      'الشهادات' => const [
        (
          title: 'شهادة إتمام English A1',
          subtitle: 'تظهر بعد إنهاء الكورس واجتياز الاختبار',
          icon: Icons.workspace_premium_rounded,
        ),
        (
          title: 'شهادة إتمام German A1',
          subtitle: 'تظهر بعد إنهاء الكورس واجتياز الاختبار',
          icon: Icons.workspace_premium_rounded,
        ),
      ],
      'تواصل معنا' => const [
        (
          title: 'دعم واتساب',
          subtitle: 'تواصل سريع مع فريق خدمة العملاء',
          icon: Icons.support_agent_rounded,
        ),
        (
          title: 'البريد الإلكتروني',
          subtitle: 'support@lingova.app',
          icon: Icons.email_rounded,
        ),
      ],
      _ => const [
        (
          title: 'الإشعارات',
          subtitle: 'إدارة تنبيهات الدروس والاختبارات',
          icon: Icons.notifications_rounded,
        ),
        (
          title: 'لغة التطبيق',
          subtitle: 'العربية',
          icon: Icons.translate_rounded,
        ),
      ],
    };
  }

  void _onItemTap(BuildContext context, String itemTitle) {
    if (widget.title == 'الكتب الإلكترونية') {
      // Create sample books
      final books = [
        Book(
          id: '1',
          title: 'كتاب English A1',
          subtitle: 'ملخص الدروس والكلمات الأساسية',
          course: 'English A1',
          language: 'English',
          isFree: true,
          url: 'https://example.com/english_a1.pdf', // Replace with actual URL
          createdAt: '2024-01-01',
          createdBy: 'Admin',
        ),
        Book(
          id: '2',
          title: 'كتاب German A1',
          subtitle: 'تأسيس قواعد ومفردات المستوى الأول',
          course: 'German A1',
          language: 'German',
          isFree: false,
          url: 'https://example.com/german_a1.pdf', // Replace with actual URL
          createdAt: '2024-01-01',
          createdBy: 'Admin',
        ),
      ];

      final book = books.firstWhere(
        (b) => b.title == itemTitle,
        orElse: () => books[0],
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookViewerScreen(book: book)),
      );
    } else {
      _showComingSoon(context, itemTitle);
    }
  }

  void _showComingSoon(BuildContext context, String itemTitle) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('سيتم تفعيل $itemTitle قريباً')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: .35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: AppColors.orange, size: 34),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onItemTap(context, item.title),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: AppColors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item.title,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    item.subtitle,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
