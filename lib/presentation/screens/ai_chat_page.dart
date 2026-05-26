import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/datasources/book_api_datasource.dart';
import '../../data/datasources/course_api_datasource.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/course.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  final _books = <Book>[];
  final _courses = <Course>[];
  bool _isSending = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            'مرحباً! اسألني عن أي كتاب أو فيديو مرفوع، وسأساعدك في إيجاد المحتوى المناسب.',
        isUser: false,
      ),
    );
    _loadContent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final results = await Future.wait([
        BookApiDataSource().getBooks(),
        CourseApiDataSource().getCourses(),
      ]);
      setState(() {
        _books.addAll(results[0] as List<Book>);
        _courses.addAll(results[1] as List<Course>);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _loadError = 'تعذر تحميل محتوى المساعدة. حاول مرة أخرى لاحقاً.';
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 250));

    final reply = _generateReply(text);
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  String _generateReply(String prompt) {
    final lower = prompt.toLowerCase();

    if (_containsAny(lower, [
      'كتاب',
      'pdf',
      'كتاب إلكترون',
      'كتاب الكترون',
      'book',
    ])) {
      return _replyForBooks(lower);
    }

    if (_containsAny(lower, [
      'فيديو',
      'درس',
      'كورسات',
      'course',
      'lecture',
      'تدريب',
    ])) {
      return _replyForCourses(lower);
    }

    if (_containsAny(lower, [
      'كيف',
      'ماذا',
      'اين',
      'لماذا',
      'هل',
      'ما',
      'اذاً',
      'اذا',
    ])) {
      return 'يمكنني مساعدتك في العثور على كتب ودروس ضمن المحتوى المرفوع. اسأل عن عنوان الكتاب أو اسم الكورس أو أي سؤال عن الفيديوهات.';
    }

    return 'اسألني عن الكتب أو الفيديوهات المتوفرة في التطبيق. سأساعدك في اختيار الكتاب أو الكورس المناسب أو إرشادك إلى المحتوى.';
  }

  String _replyForBooks(String lower) {
    if (_books.isEmpty) {
      return 'لا توجد بيانات مكتبة متاحة حالياً داخل المساعد، ولكن يمكنك زيارة صفحة المكتبة لعرض الكتب المتوفرة.';
    }

    final matchedBooks = _books.where((book) {
      final title = book.title.toLowerCase();
      final subtitle = book.subtitle.toLowerCase();
      final course = book.course.toLowerCase();
      return lower.contains(title) ||
          lower.contains(subtitle) ||
          lower.contains(course);
    }).toList();

    if (matchedBooks.isNotEmpty) {
      final firstBooks = matchedBooks.take(3).toList();
      final summary = firstBooks
          .map((book) {
            final label = book.subtitle.isNotEmpty
                ? book.subtitle
                : book.course;
            return '- ${book.title}: $label';
          })
          .join('\n');
      return '''وجدت هذه الكتب المتطابقة:
$summary
يمكنك زيارة صفحة المكتبة لفتح أي كتاب أو عرضه مباشرة.''';
    }

    final category =
        _books
            .where((book) => book.language.toLowerCase().contains('الإنجليزية'))
            .isNotEmpty
        ? 'هناك كتب باللغة الإنجليزية والعربية في المكتبة.'
        : 'هناك عدة كتب جيدة متاحة في المكتبة.';

    return '''$category
استخدم صفحة المكتبة للبحث عن عنوان الكتاب أو اسم الدورة، وسأساعدك في توصية الكتب المناسبة.''';
  }

  String _replyForCourses(String lower) {
    if (_courses.isEmpty) {
      return 'لا توجد بيانات كورسات متاحة حالياً داخل المساعد، ولكن يمكنك زيارة صفحة الكورسات لمعرفة المحتوى المتوفر.';
    }

    final matchedCourses = _courses.where((course) {
      final title = course.title.toLowerCase();
      final description = course.description.toLowerCase();
      final language = course.language.toLowerCase();
      return lower.contains(title) ||
          lower.contains(description) ||
          lower.contains(language);
    }).toList();

    if (matchedCourses.isNotEmpty) {
      final firstCourses = matchedCourses.take(3).toList();
      final summary = firstCourses
          .map((course) {
            return '- ${course.title} (${course.language}) • ${course.lessonsCount}';
          })
          .join('\n');
      return '''هذه بعض الكورسات المناسبة:
$summary
يمكنك فتح صفحة الكورسات للاطلاع على التفاصيل ومشاهدة الفيديوهات.''';
    }

    return 'هناك ${_courses.length} كورسات متاحة. يمكنك البحث في صفحة الكورسات عن اسم الدورة أو اللغة، وسأساعدك في اختيار الأنسب لك.';
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المساعد الذكي')),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: .35),
                  ),
                ),
                child: const Text(
                  'اكتب سؤالك عن الكتب أو الفيديوهات المرفوعة. المساعد هنا يساعدك في العثور على المحتوى المناسب.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  child: Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'اكتب سؤالك هنا...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Material(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Icon(
                            _isSending
                                ? Icons.hourglass_top_rounded
                                : Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isUser ? AppColors.orange : AppColors.surface;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              margin: message.isUser
                  ? const EdgeInsets.only(left: 50)
                  : const EdgeInsets.only(right: 50),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                textAlign: TextAlign.right,
                style: TextStyle(color: textColor, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
