import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/services/auth_storage_service.dart';
import '../../domain/entities/book.dart';
import '../../data/datasources/book_api_datasource.dart';
import 'ai_chat_page.dart';
import 'book_viewer_screen.dart';
import 'certificates_page.dart';
import 'community_page.dart';
import 'live_support_page.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AuthStorageService.clearUser();

    navigator.pushAndRemoveUntil(
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

    if (title == 'المساعد الذكي') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AiChatPage()));
      return;
    }

    if (title == 'الشهادات') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CertificatesPage()));
      return;
    }

    if (title == 'الشات المباشر') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LiveSupportPage()),
      );
      return;
    }

    if (title == 'المجتمع') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CommunityPage()),
      );
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
      (title: 'المساعد الذكي', icon: Icons.smart_toy_rounded),
      (title: 'الملفات الصوتية', icon: Icons.headphones_rounded),
      (title: 'الشهادات', icon: Icons.workspace_premium_rounded),
      (title: 'الشات المباشر', icon: Icons.support_agent_rounded),
      (title: 'المجتمع', icon: Icons.group_rounded),
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
  late final Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    if (widget.title == 'الكتب الإلكترونية') {
      _booksFuture = BookApiDataSource().getBooks();
    }
  }

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

  void _openBook(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookViewerScreen(book: book)),
    );
  }

  Widget _buildBooksList() {
    return FutureBuilder<List<Book>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'تعذر تحميل الكتب. حاول مرة أخرى لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'لا توجد كتب إلكترونية متاحة حالياً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return Column(
          children: books.map((book) => _buildBookItem(context, book)).toList(),
        );
      },
    );
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openBook(context, book),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: AppColors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        book.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.subtitle.isNotEmpty ? book.subtitle : book.course,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: AppColors.textMuted),
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

  void _onItemTap(BuildContext context, String itemTitle) {
    _showComingSoon(context, itemTitle);
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
              if (widget.title == 'الكتب الإلكترونية')
                _buildBooksList()
              else
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
