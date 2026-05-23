import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AudioEmbedWidget extends StatefulWidget {
  final String html;

  const AudioEmbedWidget({super.key, required this.html});

  @override
  State<AudioEmbedWidget> createState() => _AudioEmbedWidgetState();
}

class _AudioEmbedWidgetState extends State<AudioEmbedWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(widget.html);
  }

  @override
  void didUpdateWidget(covariant AudioEmbedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      setState(() => _isLoading = true);
      _controller.loadHtmlString(widget.html);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
