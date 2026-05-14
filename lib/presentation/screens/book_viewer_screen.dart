import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/book.dart';

class BookViewerScreen extends StatefulWidget {
  final Book book;

  const BookViewerScreen({super.key, required this.book});

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  late final WebViewController _controller;
  late final String _bookUrl;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _bookUrl = _normalizeBookUrl(widget.book.url);

    if (kIsWeb) {
      _launchUrl();
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {},
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_bookUrl));
    }
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
        body: kIsWeb
            ? Center(
                child: _isLaunching
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('تم فتح الكتاب في نافذة جديدة.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _launchUrl,
                            child: const Text('إعادة فتح الرابط'),
                          ),
                        ],
                      ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
