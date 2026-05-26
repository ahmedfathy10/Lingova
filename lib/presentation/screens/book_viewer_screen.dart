import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../domain/entities/book.dart';

class BookViewerScreen extends StatefulWidget {
  final Book book;

  const BookViewerScreen({super.key, required this.book});

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  late final String _bookUrl;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _bookUrl = _normalizeBookUrl(widget.book.url);
    _launchUrl();
  }

  String _normalizeBookUrl(String url) {
    final driveIdRegExp = RegExp(
      r'https?://drive\.google\.com/(?:file/d/|open\?id=|uc\?id=)([\w-]+)',
      caseSensitive: false,
    );
    final match = driveIdRegExp.firstMatch(url);
    if (match != null) {
      return 'https://drive.google.com/file/d/${match.group(1)}/preview';
    }
    return url;
  }

  Future<void> _launchUrl() async {
    if (_isLaunching) return;

    setState(() {
      _isLaunching = true;
    });

    final success = await launchUrlString(
      _bookUrl,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط في المتصفح.')),
      );
    }

    if (mounted) {
      setState(() {
        _isLaunching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: _isLaunching
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('سيتم فتح الكتاب في مشغل/متصفح خارجي.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _launchUrl,
                      child: const Text('إعادة فتح الرابط'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
